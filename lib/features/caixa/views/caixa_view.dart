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
import '../../../features/usuario/controllers/usuario_controller.dart';
import '../../../core/utils/formatters.dart';


class CaixaView extends ConsumerStatefulWidget {
  const CaixaView({super.key});

  @override
  ConsumerState<CaixaView> createState() => _CaixaViewState();
}

class _CaixaViewState extends ConsumerState<CaixaView> {
  CaixaModel? caixaAtivo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCaixaAtivo();
    });
  }

  Future<void> _carregarCaixaAtivo() async {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
      try {
        final caixa = await ref
            .read(caixaProvider.notifier)
            .getCaixaAbertoPorLoja(lojaAtiva);
        setState(() {
          caixaAtivo = caixa;
        });
      } catch (e) {
        // Ignorar erro, pode não haver caixa aberto
      }
    }
  }

  Future<void> _abrirCaixa() async {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva == null || lojaAtiva.isEmpty) {
      AppFeedback.showError(context, 'Selecione uma loja primeiro');
      return;
    }

    // IMPORTANTE: Usar ID do usuário, não do cargo
    final usuarioId = await AuthController.getUsuarioIdLogado();
    if (usuarioId == null) {
      AppFeedback.showError(context, 'Usuário não autenticado');
      return;
    }

    final saldoInicial = await _solicitarSaldoInicial();
    if (saldoInicial == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      print('🔧 [CaixaView] Abrindo caixa com usuário ID: $usuarioId');

      await ref
          .read(caixaProvider.notifier)
          .abrirCaixa(lojaAtiva, usuarioId, saldoInicial);

      await _carregarCaixaAtivo();

      if (mounted) {
        AppFeedback.showSuccess(context, 'Caixa aberto com sucesso!');
      }
    } catch (e) {
      print('❌ [CaixaView] Erro ao abrir caixa: $e');
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao abrir caixa: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fecharCaixa() async {
    if (caixaAtivo == null) return;

    final usuarioId = await AuthController.getUsuarioIdLogado();
    if (usuarioId == null) {
      AppFeedback.showError(context, 'Usuário não autenticado');
      return;
    }

    final resultado = await _solicitarConfirmacaoFechamento();
    if (resultado == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      print('🔧 [CaixaView] Fechando caixa: ${caixaAtivo!.id}');

      await ref.read(caixaProvider.notifier).fecharCaixa(
        caixaAtivo!.id,
        usuarioId,
        saldoFinalManual: resultado['saldoFinal'],
        observacoes: resultado['observacoes'],
      );

      await _carregarCaixaAtivo();

      if (mounted) {
        AppFeedback.showSuccess(context, 'Caixa fechado com sucesso!');
      }
    } catch (e) {
      print('❌ [CaixaView] Erro ao fechar caixa: $e');
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao fechar caixa: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<double?> _solicitarSaldoInicial() async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caixa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o saldo inicial do caixa:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Inicial',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controller.text);
              if (valor != null && valor >= 0) {
                Navigator.of(context).pop(valor);
              } else {
                AppFeedback.showError(context, 'Valor inválido');
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _solicitarConfirmacaoFechamento() async {
    final saldoController = TextEditingController();
    final observacoesController = TextEditingController();
    
    // Calcular saldo atual para exibir
    try {
      final saldoAtual = await ref.read(caixaServiceProvider).calcularSaldoAtual(caixaAtivo!.id);
      saldoController.text = saldoAtual.toStringAsFixed(2);
    } catch (e) {
      saldoController.text = '0.00';
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fechar Caixa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirme as informações para fechamento:'),
            const SizedBox(height: 16),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Final',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
                helperText: 'Confirme o valor em caixa',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Informações adicionais sobre o fechamento',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final saldoFinal = double.tryParse(saldoController.text);
              if (saldoFinal == null || saldoFinal < 0) {
                AppFeedback.showError(context, 'Saldo final inválido');
                return;
              }
              
              Navigator.of(context).pop({
                'saldoFinal': saldoFinal,
                'observacoes': observacoesController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar Caixa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lojaAtiva = ref.watch(lojaAtivaProvider);
    final lojasAsync = ref.watch(lojaProvider);

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Caixa',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Caixa'),
            ],
            currentRoute: '/caixa',
            child: Center(child: Text('Erro ao carregar permissões: $e')),
          ),
          data: (permissoes) {
            final scaffoldContext = context;
            return MainLayout(
              title: '💰 Caixa',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Caixa'),
              ],
              currentRoute: '/caixa',
              onSidebarItemSelected: (route) => scaffoldContext.go(route),
              child: SingleChildScrollView(
                // Adicionar ScrollView para evitar overflow
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
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  // Adicionar Expanded para evitar overflow
                                  child: Text(
                                    'Caixa da Loja: ${loja.nome}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Tratar overflow de texto
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Status do caixa
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                caixaAtivo?.isAberto == true
                                    ? Icons.account_balance_wallet
                                    : Icons.account_balance_wallet_outlined,
                                color: caixaAtivo?.isAberto == true
                                    ? Colors.green
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                // Adicionar Expanded para evitar overflow
                                child: Text(
                                  'Status do Caixa',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (caixaAtivo?.isAberto == true) ...[
                            // Caixa aberto
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        // Adicionar Expanded para evitar overflow
                                        child: Text(
                                          'Caixa Aberto',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Usar LayoutBuilder para responsividade
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth > 600) {
                                        // Layout horizontal para telas maiores
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Saldo Inicial',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    formatCurrency(
                                                      caixaAtivo!.saldoInicial,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Data de Abertura',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    formatDate(
                                                      caixaAtivo!.dataAbertura,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // Layout vertical para telas menores
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Saldo Inicial',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  formatCurrency(
                                                    caixaAtivo!.saldoInicial,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Data de Abertura',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  formatDate(
                                                    caixaAtivo!.dataAbertura,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Informações de vendas do caixa aberto
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final resumoAsync = ref.watch(
                                        resumoFechamentoProvider(caixaAtivo!.id),
                                      );
                                      
                                      return resumoAsync.when(
                                        loading: () => const SizedBox.shrink(),
                                        error: (e, _) => const SizedBox.shrink(),
                                        data: (resumo) {
                                          if (resumo['total_vendas_realizadas'] == 0) {
                                            return const SizedBox.shrink();
                                          }
                                          
                                          return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.shopping_cart,
                                                      color: Colors.blue,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Resumo de Vendas',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.blue[700],
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Vendas',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.blue[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            '${resumo['total_vendas_realizadas']}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blue[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Peças',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.blue[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            '${resumo['total_itens_vendidos']}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blue[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Total',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.blue[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            formatCurrency(resumo['total_vendas']),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blue[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  
                                  // Botões responsivos
                                  Wrap(
                                    // Usar Wrap para botões responsivos
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (permissoes.any(
                                        (p) =>
                                            p['recurso'] == 'caixa' &&
                                            p['acao'] == 'listar',
                                      ))
                                        SizedBox(
                                          width:
                                              200, // Largura fixa para botões
                                          child: OutlinedButton.icon(
                                            onPressed: () => context.go(
                                              '/caixa/movimentacoes',
                                            ),
                                            icon: const Icon(Icons.history),
                                            label: const Text(
                                              'Ver Movimentações',
                                            ),
                                          ),
                                        ),
                                      
                                      // Botão de fechamento
                                      if (permissoes.any(
                                        (p) =>
                                            p['recurso'] == 'caixa' &&
                                            p['acao'] == 'criar',
                                      ))
                                        SizedBox(
                                          width: 200,
                                          child: ElevatedButton.icon(
                                            onPressed: () => context.go('/caixa/fechamento/${caixaAtivo!.id}'),
                                            icon: const Icon(Icons.close),
                                            label: const Text('Fechar Caixa'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Caixa fechado ou não existe
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        // Adicionar Expanded para evitar overflow
                                        child: Text(
                                          'Caixa Fechado',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Não há caixa aberto no momento. Abra um novo caixa para começar a operar.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (permissoes.any(
                                    (p) =>
                                        p['recurso'] == 'caixa' &&
                                        p['acao'] == 'criar',
                                  ))
                                    SizedBox(
                                      width: 200, // Largura fixa para botões
                                      child: ElevatedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : _abrirCaixa,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Abrir Caixa'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Histórico de caixas
                    if (permissoes.any(
                      (p) => p['recurso'] == 'caixa' && p['acao'] == 'listar',
                    ))
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  // Adicionar Expanded para evitar overflow
                                  child: const Text(
                                    'Histórico de Caixas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.go('/caixa/historico'),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Ver Todos'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Consumer(
                              builder: (context, ref, child) {
                                final caixasAsync = ref.watch(caixaProvider);

                                return caixasAsync.when(
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (e, _) => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'Erro ao carregar caixas: $e',
                                      ),
                                    ),
                                  ),
                                  data: (caixas) {
                                    final caixasLoja = caixas
                                        .where((c) => c.lojaId == lojaAtiva)
                                        .take(5)
                                        .toList();

                                    if (caixasLoja.isEmpty) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            'Nenhum caixa encontrado',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: caixasLoja.length,
                                      itemBuilder: (context, index) {
                                        final caixa = caixasLoja[index];
                                        return ListTile(
                                          leading: Icon(
                                            caixa.isAberto
                                                ? Icons.account_balance_wallet
                                                : Icons
                                                      .account_balance_wallet_outlined,
                                            color: caixa.isAberto
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          title: Text(
                                            'Caixa #${caixa.id.substring(0, 8)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${formatDate(caixa.dataAbertura)} - ${caixa.status.label}',
                                          ),
                                          trailing: Text(
                                            formatCurrency(caixa.saldoInicial),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onTap: () =>
                                              context.go('/caixa/${caixa.id}'),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
