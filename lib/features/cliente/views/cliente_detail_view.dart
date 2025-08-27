import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cliente_model.dart';
import '../controllers/cliente_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../features/lojas/controllers/loja_controller.dart';
import '../../../features/lojas/models/loja_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/usuario/controllers/usuario_controller.dart';
import '../../../features/venda/models/venda_model.dart';
import '../../../features/venda/services/venda_service.dart';

class ClienteDetailView extends ConsumerStatefulWidget {
  final String clienteId;

  const ClienteDetailView({super.key, required this.clienteId});

  @override
  ConsumerState<ClienteDetailView> createState() => _ClienteDetailViewState();
}

class _ClienteDetailViewState extends ConsumerState<ClienteDetailView> {
  ClienteModel? cliente;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarCliente();
  }

  Future<void> _carregarCliente() async {
    setState(() => _loading = true);
    try {
      final clienteData = await ref
          .read(clienteProvider.notifier)
          .getCliente(widget.clienteId);
      if (clienteData != null) {
        setState(() {
          cliente = clienteData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao carregar cliente: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lojasAsync = ref.watch(lojaProvider);

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Detalhes do Cliente',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Clientes'),
              BreadcrumbItem('Detalhes'),
            ],
            currentRoute: '/clientes',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            return MainLayout(
              title: '👤 Detalhes do Cliente',
              breadcrumbs: [
                const BreadcrumbItem('Dashboard'),
                const BreadcrumbItem('Clientes'),
                BreadcrumbItem(cliente?.nome ?? 'Detalhes'),
              ],
              currentRoute: '/clientes',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                TextButton.icon(
                  onPressed: () => context.go('/clientes'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                ),
                if (permissoes.any(
                  (p) => p['recurso'] == 'clientes' && p['acao'] == 'editar',
                ))
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/clientes/${widget.clienteId}/editar'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
              ],
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : cliente == null
                  ? const Center(child: Text('Cliente não encontrado'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header com informações principais
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cliente!.nome,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (cliente!.tipoDocumento != null)
                                            Text(
                                              '${cliente!.tipoDocumento}: ${cliente!.documento ?? ''}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ativo',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Informações de contato
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.contact_phone,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Informações de Contato',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 600;

                                    if (isWide) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoCard(
                                              'Email',
                                              cliente!.email ?? 'Não informado',
                                              Icons.email,
                                              Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildInfoCard(
                                              'Telefone',
                                              cliente!.telefone ??
                                                  'Não informado',
                                              Icons.phone,
                                              Colors.green,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          _buildInfoCard(
                                            'Email',
                                            cliente!.email ?? 'Não informado',
                                            Icons.email,
                                            Colors.blue,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildInfoCard(
                                            'Telefone',
                                            cliente!.telefone ??
                                                'Não informado',
                                            Icons.phone,
                                            Colors.green,
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                                if (cliente!.endereco != null) ...[
                                  const SizedBox(height: 16),
                                  _buildInfoCard(
                                    'Endereço',
                                    cliente!.endereco!,
                                    Icons.location_on,
                                    Colors.orange,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Informações da loja
                          if (cliente!.lojaId != null)
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.store,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Loja Associada',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  lojasAsync.when(
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (e, _) =>
                                        Text('Erro ao carregar loja: $e'),
                                    data: (lojas) {
                                      final loja = lojas.firstWhere(
                                        (l) => l.id == cliente!.lojaId,
                                        orElse: () => LojaModel(
                                          id: '',
                                          nome: 'Loja não encontrada',
                                          shopping: '',
                                          andar: '',
                                          numero: '',
                                          quantidadeMinimaAtacado: 4,
                                        ),
                                      );
                                      return _buildInfoCard(
                                        'Loja',
                                        '${loja.nome} - ${loja.shopping}',
                                        Icons.store,
                                        Colors.purple,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Histórico de compras
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Histórico de Compras',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildComprasHistoric(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Informações de auditoria
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Informações do Sistema',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 600;

                                    if (isWide) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoCard(
                                              'Criado em',
                                              cliente!.criadoEm != null
                                                  ? _formatDate(
                                                      cliente!.criadoEm!,
                                                    )
                                                  : 'Não informado',
                                              Icons.add_circle,
                                              Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildInfoCard(
                                              'Última atualização',
                                              cliente!.atualizadoEm != null
                                                  ? _formatDate(
                                                      cliente!.atualizadoEm!,
                                                    )
                                                  : 'Não atualizado',
                                              Icons.update,
                                              Colors.orange,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          _buildInfoCard(
                                            'Criado em',
                                            cliente!.criadoEm != null
                                                ? _formatDate(
                                                    cliente!.criadoEm!,
                                                  )
                                                : 'Não informado',
                                            Icons.add_circle,
                                            Colors.green,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildInfoCard(
                                            'Última atualização',
                                            cliente!.atualizadoEm != null
                                                ? _formatDate(
                                                    cliente!.atualizadoEm!,
                                                  )
                                                : 'Não atualizado',
                                            Icons.update,
                                            Colors.orange,
                                          ),
                                        ],
                                      );
                                    }
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

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildComprasHistoric() {
    return FutureBuilder<List<VendaModel>>(
      future: _carregarVendasDoCliente(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando histórico de compras...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Erro no histórico de compras: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar histórico',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não foi possível carregar o histórico de compras.',
                  style: TextStyle(fontSize: 14, color: Colors.red[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final vendas = snapshot.data ?? [];

        // Filtrar vendas do cliente atual
        final vendasCliente = vendas
            .where((venda) => venda.clienteId == cliente!.id)
            .toList();

        if (vendasCliente.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma compra encontrada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este cliente ainda não realizou nenhuma compra.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Ordenar por data (mais recente primeiro)
        vendasCliente.sort(
          (a, b) => (b.criadoEm ?? DateTime.now()).compareTo(
            a.criadoEm ?? DateTime.now(),
          ),
        );

        return Column(
          children: [
            // Resumo do histórico
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo do Cliente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vendasCliente.length} compra(s) • Total: ${_formatCurrency(_calcularTotalCompras(vendasCliente))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de vendas
            ...vendasCliente
                .map((venda) => _buildVendaCard(venda, ref))
                .toList(),
          ],
        );
      },
    );
  }

  Future<List<VendaModel>> _carregarVendasDoCliente() async {
    try {
      final vendaService = VendaService();
      return await vendaService.getVendasPorCliente(cliente!.id);
    } catch (e) {
      print('Erro ao carregar vendas do cliente: $e');
      return [];
    }
  }

  Widget _buildVendaCard(VendaModel venda, WidgetRef ref) {
    final lojasAsync = ref.watch(lojaProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da venda
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(venda.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(
                        venda.status,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(venda.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(venda.status),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(venda.criadoEm ?? DateTime.now()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informações da venda
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venda #${venda.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      lojasAsync.when(
                        loading: () => const Text(
                          'Carregando...',
                          style: TextStyle(fontSize: 12),
                        ),
                        error: (_, __) => const Text(
                          'Erro ao carregar loja',
                          style: TextStyle(fontSize: 12),
                        ),
                        data: (lojas) {
                          final loja = lojas.firstWhere(
                            (l) => l.id == venda.lojaId,
                            orElse: () => LojaModel(
                              id: '',
                              nome: 'Loja não encontrada',
                              shopping: '',
                              andar: '',
                              numero: '',
                              quantidadeMinimaAtacado: 4,
                            ),
                          );
                          return Text(
                            'Loja: ${loja.nome}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(venda.valorTotal - venda.descontoTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (venda.descontoTotal > 0)
                      Text(
                        'Desconto: ${_formatCurrency(venda.descontoTotal)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calcularTotalCompras(List<VendaModel> vendas) {
    return vendas.fold(
      0.0,
      (total, venda) => total + (venda.valorTotal - venda.descontoTotal),
    );
  }

  Color _getStatusColor(StatusVenda status) {
    switch (status) {
      case StatusVenda.fechada:
        return Colors.green;
      case StatusVenda.aberta:
        return Colors.orange;
      case StatusVenda.cancelada:
        return Colors.red;
    }
  }

  String _getStatusText(StatusVenda status) {
    switch (status) {
      case StatusVenda.fechada:
        return 'Finalizada';
      case StatusVenda.aberta:
        return 'Em Aberto';
      case StatusVenda.cancelada:
        return 'Cancelada';
    }
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
