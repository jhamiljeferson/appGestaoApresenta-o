import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/caixa_model.dart';
import '../controllers/caixa_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../features/lojas/providers/loja_ativa_provider.dart';
import '../../../features/lojas/controllers/loja_controller.dart';
import '../../../features/lojas/models/loja_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/utils/formatters.dart';

class CaixaHistoricoView extends ConsumerStatefulWidget {
  const CaixaHistoricoView({super.key});

  @override
  ConsumerState<CaixaHistoricoView> createState() => _CaixaHistoricoViewState();
}

class _CaixaHistoricoViewState extends ConsumerState<CaixaHistoricoView> {
  bool isLoading = false;
  String? _filtroStatus;
  String? _filtroPeriodo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCaixas();
    });
  }

  Future<void> _carregarCaixas() async {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
      try {
        setState(() {
          isLoading = true;
        });

        await ref.read(caixaProvider.notifier).loadCaixasPorLoja(lojaAtiva);

        setState(() {
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          AppFeedback.showError(context, 'Erro ao carregar caixas: $e');
        }
      }
    }
  }

  List<CaixaModel> _filtrarCaixas(List<CaixaModel> caixas) {
    List<CaixaModel> filtrados = caixas;

    // Filtro por status
    if (_filtroStatus != null && _filtroStatus!.isNotEmpty) {
      if (_filtroStatus == 'aberto') {
        filtrados = filtrados.where((c) => c.isAberto).toList();
      } else if (_filtroStatus == 'fechado') {
        filtrados = filtrados.where((c) => c.isFechado).toList();
      }
    }

    // Filtro por período
    if (_filtroPeriodo != null && _filtroPeriodo!.isNotEmpty) {
      final agora = DateTime.now();
      switch (_filtroPeriodo) {
        case 'hoje':
          filtrados = filtrados
              .where(
                (c) =>
                    c.dataAbertura.day == agora.day &&
                    c.dataAbertura.month == agora.month &&
                    c.dataAbertura.year == agora.year,
              )
              .toList();
          break;
        case 'semana':
          final umaSemanaAtras = agora.subtract(const Duration(days: 7));
          filtrados = filtrados
              .where((c) => c.dataAbertura.isAfter(umaSemanaAtras))
              .toList();
          break;
        case 'mes':
          final umMesAtras = DateTime(agora.year, agora.month - 1, agora.day);
          filtrados = filtrados
              .where((c) => c.dataAbertura.isAfter(umMesAtras))
              .toList();
          break;
      }
    }

    return filtrados;
  }

  Color _getStatusColor(StatusCaixa status) {
    switch (status) {
      case StatusCaixa.aberto:
        return Colors.green;
      case StatusCaixa.fechado:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(StatusCaixa status) {
    switch (status) {
      case StatusCaixa.aberto:
        return Icons.account_balance_wallet;
      case StatusCaixa.fechado:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lojaAtiva = ref.watch(lojaAtivaProvider);
    final lojasAsync = ref.watch(lojaProvider);
    final caixasAsync = ref.watch(caixaProvider);

    return MainLayout(
      title: '📊 Histórico de Caixas',
      breadcrumbs: const [
        BreadcrumbItem('Dashboard'),
        BreadcrumbItem('Caixa'),
        BreadcrumbItem('Histórico'),
      ],
      currentRoute: '/caixa/historico',
      onSidebarItemSelected: (route) => context.go(route),
      actions: [
        // Botão de atualizar
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
          onPressed: _carregarCaixas,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com loja ativa
            if (lojaAtiva != null && lojaAtiva.isNotEmpty)
              lojasAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (lojas) {
                  final loja = lojas.firstWhere(
                    (l) => l.id == lojaAtiva,
                    orElse: () => LojaModel(
                      id: '',
                      nome: 'Loja não encontrada',
                      shopping: '',
                      andar: '',
                      numero: '',
                    ),
                  );
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Histórico de Caixas',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Loja: ${loja.nome}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Botão de voltar ao caixa
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: () => context.go('/caixa'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar ao Caixa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Filtros
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Filtro por status
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          value: _filtroStatus,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(
                              value: 'aberto',
                              child: Text('Abertos'),
                            ),
                            DropdownMenuItem(
                              value: 'fechado',
                              child: Text('Fechados'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroStatus = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Filtro por período
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Período',
                            border: OutlineInputBorder(),
                          ),
                          value: _filtroPeriodo,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(
                              value: 'hoje',
                              child: Text('Hoje'),
                            ),
                            DropdownMenuItem(
                              value: 'semana',
                              child: Text('Última Semana'),
                            ),
                            DropdownMenuItem(
                              value: 'mes',
                              child: Text('Último Mês'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroPeriodo = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de caixas
            caixasAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar caixas: $e',
                        style: TextStyle(color: Colors.red[700], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _carregarCaixas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (caixas) {
                final caixasLoja = caixas
                    .where((c) => c.lojaId == lojaAtiva)
                    .toList();

                final caixasFiltrados = _filtrarCaixas(caixasLoja);

                if (caixasFiltrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            caixasLoja.isEmpty
                                ? 'Nenhum caixa encontrado'
                                : 'Nenhum caixa encontrado com os filtros aplicados',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (caixasLoja.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros ou limpar as seleções',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Resumo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${caixasFiltrados.length} caixa(s) encontrado(s)',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total: ${caixasLoja.length} caixas',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de caixas
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: caixasFiltrados.length,
                      itemBuilder: (context, index) {
                        final caixa = caixasFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  caixa.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(caixa.status),
                                color: _getStatusColor(caixa.status),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Caixa #${caixa.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aberto em: ${formatDate(caixa.dataAbertura)}',
                                ),

                                Text(
                                  'Status: ${caixa.status.label}',
                                  style: TextStyle(
                                    color: _getStatusColor(caixa.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Saldo Inicial',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  formatCurrency(caixa.saldoInicial),
                                  style: TextStyle(
                                    color: _getStatusColor(caixa.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (caixa.saldoFinal != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saldo Final',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    formatCurrency(caixa.saldoFinal!),
                                    style: TextStyle(
                                      color: _getStatusColor(caixa.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () => context.go('/caixa/${caixa.id}'),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
