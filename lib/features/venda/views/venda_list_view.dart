import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/venda_model.dart';
import '../controllers/venda_controller.dart';
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

class VendaListView extends ConsumerStatefulWidget {
  const VendaListView({super.key});

  @override
  ConsumerState<VendaListView> createState() => _VendaListViewState();
}

class _VendaListViewState extends ConsumerState<VendaListView> {
  String filtroStatus = '';
  String filtroCliente = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lojaAtiva = ref.read(lojaAtivaProvider);
      if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
        ref.read(vendaProvider.notifier).loadVendasPorLoja(lojaAtiva);
      } else {
        ref.read(vendaProvider.notifier).loadVendas();
      }
    });
  }

  List<VendaModel> getVendasFiltradas(List<VendaModel> vendas) {
    return vendas.where((venda) {
      final matchStatus =
          filtroStatus.isEmpty || venda.status.name == filtroStatus;
      // TODO: Implementar filtro por cliente quando tivermos acesso aos dados do cliente
      return matchStatus;
    }).toList();
  }

  void _deletarVenda(VendaModel venda) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
            'Tem certeza que deseja excluir a venda #${venda.id.substring(0, 8)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final scaffoldContext = context;
                Navigator.of(scaffoldContext).pop();
                try {
                  await ref.read(vendaProvider.notifier).deleteVenda(venda.id);
                  if (mounted) {
                    AppFeedback.showSuccess(
                      scaffoldContext,
                      'Venda excluída com sucesso!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppFeedback.showError(
                      scaffoldContext,
                      'Erro ao excluir venda: $e',
                    );
                  }
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(StatusVenda status) {
    switch (status) {
      case StatusVenda.aberta:
        return Colors.orange;
      case StatusVenda.fechada:
        return Colors.green;
      case StatusVenda.cancelada:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendaAsync = ref.watch(vendaProvider);
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
            title: 'Vendas',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Vendas'),
            ],
            currentRoute: '/vendas',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final scaffoldContext = context;
            return MainLayout(
              title: '🛒 Vendas',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Vendas'),
              ],
              currentRoute: '/vendas',
              onSidebarItemSelected: (route) => scaffoldContext.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar lista',
                  onPressed: () {
                    final lojaAtiva = ref.read(lojaAtivaProvider);
                    if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
                      ref
                          .read(vendaProvider.notifier)
                          .loadVendasPorLoja(lojaAtiva);
                    } else {
                      ref.read(vendaProvider.notifier).loadVendas();
                    }
                  },
                ),
                if (permissoes.any(
                  (p) => p['recurso'] == 'vendas' && p['acao'] == 'criar',
                ))
                  ElevatedButton.icon(
                    onPressed: () => context.go('/vendas/nova'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Venda'),
                  ),
              ],
              child: Column(
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
                              Icon(Icons.store, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Vendas da Loja: ${loja.nome}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Filtros
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 600;

                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: filtroStatus.isEmpty
                                          ? null
                                          : filtroStatus,
                                      items: const [
                                        DropdownMenuItem(
                                          value: '',
                                          child: Text('Todos'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'aberta',
                                          child: Text('Aberta'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'fechada',
                                          child: Text('Fechada'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cancelada',
                                          child: Text('Cancelada'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          filtroStatus = value ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: filtroStatus.isEmpty
                                        ? null
                                        : filtroStatus,
                                    items: const [
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text('Todos'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'aberta',
                                        child: Text('Aberta'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'fechada',
                                        child: Text('Fechada'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cancelada',
                                        child: Text('Cancelada'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        filtroStatus = value ?? '';
                                      });
                                    },
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de vendas
                  Expanded(
                    child: vendaAsync.when(
                      loading: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Carregando vendas...'),
                          ],
                        ),
                      ),
                      error: (e, _) =>
                          Center(child: Text('Erro ao carregar vendas: $e')),
                      data: (vendas) {
                        final filtradas = getVendasFiltradas(vendas);

                        if (filtradas.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhuma venda encontrada',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;

                            if (isWide) {
                              return AppCard(
                                padding: const EdgeInsets.all(0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('ID')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Valor Total')),
                                      DataColumn(label: Text('Desconto')),
                                      DataColumn(label: Text('Valor Final')),
                                      DataColumn(label: Text('Data')),
                                      DataColumn(label: Text('Ações')),
                                    ],
                                    rows: filtradas.map((venda) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            InkWell(
                                              onTap: () => context.go(
                                                '/vendas/${venda.id}',
                                              ),
                                              child: Text(
                                                '#${venda.id.substring(0, 8)}',
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  venda.status,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getStatusColor(
                                                    venda.status,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                venda.status.label,
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    venda.status,
                                                  ),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              formatCurrency(venda.valorTotal),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              formatCurrency(
                                                venda.descontoTotal,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              formatCurrency(venda.valorFinal),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              venda.criadoEm != null
                                                  ? formatDate(venda.criadoEm!)
                                                  : '-',
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (permissoes.any(
                                                  (p) =>
                                                      p['recurso'] ==
                                                          'vendas' &&
                                                      p['acao'] == 'editar',
                                                ))
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    tooltip: 'Editar',
                                                    onPressed: () => context.go(
                                                      '/vendas/${venda.id}/editar',
                                                    ),
                                                  ),
                                                if (permissoes.any(
                                                  (p) =>
                                                      p['recurso'] ==
                                                          'vendas' &&
                                                      p['acao'] == 'excluir',
                                                ))
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    tooltip: 'Excluir',
                                                    onPressed: () =>
                                                        _deletarVenda(venda),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            } else {
                              return ListView.builder(
                                itemCount: filtradas.length,
                                itemBuilder: (context, index) {
                                  final venda = filtradas[index];
                                  return AppCard(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () =>
                                          context.go('/vendas/${venda.id}'),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '#${venda.id.substring(0, 8)}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        formatDate(
                                                          venda.criadoEm ??
                                                              DateTime.now(),
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      venda.status,
                                                    ).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                        venda.status,
                                                      ).withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    venda.status.label,
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                        venda.status,
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Valor Total',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        formatCurrency(
                                                          venda.valorTotal,
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Valor Final',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        formatCurrency(
                                                          venda.valorFinal,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (permissoes.any(
                                                  (p) =>
                                                      p['recurso'] ==
                                                          'vendas' &&
                                                      p['acao'] == 'editar',
                                                ) ||
                                                permissoes.any(
                                                  (p) =>
                                                      p['recurso'] ==
                                                          'vendas' &&
                                                      p['acao'] == 'excluir',
                                                ))
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  if (permissoes.any(
                                                    (p) =>
                                                        p['recurso'] ==
                                                            'vendas' &&
                                                        p['acao'] == 'editar',
                                                  ))
                                                    TextButton(
                                                      onPressed: () => context.go(
                                                        '/vendas/${venda.id}/editar',
                                                      ),
                                                      child: const Text(
                                                        'Editar',
                                                      ),
                                                    ),
                                                  if (permissoes.any(
                                                    (p) =>
                                                        p['recurso'] ==
                                                            'vendas' &&
                                                        p['acao'] == 'excluir',
                                                  ))
                                                    TextButton(
                                                      onPressed: () =>
                                                          _deletarVenda(venda),
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        'Excluir',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
