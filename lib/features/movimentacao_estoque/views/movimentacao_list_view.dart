import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';

import '../../../shared/widgets/app_breadcrumbs.dart';

import '../controllers/movimentacao_estoque_controller.dart';
import '../models/movimentacao_estoque_model.dart';
import '../../produto/controllers/produto_controller.dart';
import '../../produto/models/produto_model.dart';
import '../../lojas/controllers/loja_controller.dart';
import '../../lojas/models/loja_model.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../usuario/services/usuario_service.dart';

class MovimentacaoListView extends ConsumerStatefulWidget {
  const MovimentacaoListView({super.key});

  @override
  ConsumerState<MovimentacaoListView> createState() =>
      _MovimentacaoListViewState();
}

class _MovimentacaoListViewState extends ConsumerState<MovimentacaoListView> {
  @override
  void initState() {
    super.initState();
    // Carregar movimentações quando a tela for montada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movimentacaoEstoqueProvider.notifier).loadMovimentacoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final movimentacoesAsync = ref.watch(movimentacaoEstoqueProvider);
    final produtosAsync = ref.watch(produtoProvider);
    final lojasAsync = ref.watch(lojaProvider);
    final lojaAtiva = ref.watch(lojaAtivaProvider);

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Movimentações de Estoque',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Movimentações'),
            ],
            currentRoute: '/movimentacoes',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            return MainLayout(
              title: '📊 Histórico de Movimentações',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Movimentações'),
              ],
              currentRoute: '/movimentacoes',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar histórico',
                  onPressed: () {
                    ref
                        .read(movimentacaoEstoqueProvider.notifier)
                        .loadMovimentacoes();
                  },
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    // Header com informações da loja ativa
                    if (lojaAtiva != null && lojaAtiva.isNotEmpty)
                      lojasAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => const Text('Erro ao carregar loja'),
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
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: Colors.blue[700],
                                      size: isWide ? 16 : 14,
                                    ),
                                    SizedBox(width: isWide ? 6 : 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Loja Ativa',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          Text(
                                            loja.nome,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 8),

                    // Lista de movimentações
                    Expanded(
                      child: movimentacoesAsync.when(
                        loading: () => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Carregando movimentações...'),
                            ],
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text('Erro ao carregar movimentações: $e'),
                        ),
                        data: (movimentacoes) {
                          if (movimentacoes.isEmpty) {
                            return AppCard(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nenhuma movimentação encontrada',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'As movimentações de estoque aparecerão aqui',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 700;

                              if (isWide) {
                                return AppCard(
                                  padding: const EdgeInsets.all(0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Data')),
                                        DataColumn(label: Text('Tipo')),
                                        DataColumn(label: Text('Produto')),
                                        DataColumn(label: Text('Quantidade')),
                                        DataColumn(label: Text('Observação')),
                                        DataColumn(label: Text('Usuário')),
                                      ],
                                      rows: movimentacoes.map<DataRow>((
                                        movimentacao,
                                      ) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                '${movimentacao.criadoEm.day.toString().padLeft(2, '0')}/${movimentacao.criadoEm.month.toString().padLeft(2, '0')}/${movimentacao.criadoEm.year}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    (movimentacao.tipo ==
                                                                TipoMovimentacao
                                                                    .entrada ||
                                                            movimentacao.tipo ==
                                                                TipoMovimentacao
                                                                    .trocaEntrada ||
                                                            movimentacao.tipo ==
                                                                TipoMovimentacao
                                                                    .transferenciaEntrada)
                                                        ? Icons.add_circle
                                                        : Icons.remove_circle,
                                                    color:
                                                        (movimentacao.tipo ==
                                                                TipoMovimentacao
                                                                    .entrada ||
                                                            movimentacao.tipo ==
                                                                TipoMovimentacao
                                                                    .trocaEntrada ||
                                                            movimentacao.tipo ==
                                                                TipoMovimentacao
                                                                    .transferenciaEntrada)
                                                        ? Colors.green
                                                        : Colors.red,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _getTipoDisplay(
                                                      movimentacao.tipo,
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          (movimentacao.tipo ==
                                                                  TipoMovimentacao
                                                                      .entrada ||
                                                              movimentacao
                                                                      .tipo ==
                                                                  TipoMovimentacao
                                                                      .trocaEntrada ||
                                                              movimentacao
                                                                      .tipo ==
                                                                  TipoMovimentacao
                                                                      .transferenciaEntrada)
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              produtosAsync.maybeWhen(
                                                data: (produtos) {
                                                  final produto = produtos.firstWhere(
                                                    (p) =>
                                                        p.id ==
                                                        movimentacao.produtoId,
                                                    orElse: () => ProdutoModel(
                                                      id: '',
                                                      nome:
                                                          'Produto não encontrado',
                                                      sku: '',
                                                      codigo: '',
                                                      precoCusto: 0,
                                                      precoAtacado: 0,
                                                      precoVarejo: 0,
                                                    ),
                                                  );
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        produto.nome,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        'SKU: ${produto.sku}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                                orElse: () =>
                                                    const Text('Carregando...'),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${movimentacao.quantidade} unidades',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                movimentacao.observacao ?? '-',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                            DataCell(
                                              FutureBuilder<String>(
                                                future: _getNomeUsuario(
                                                  movimentacao.criadoPor,
                                                ),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.data ??
                                                        'Usuário não encontrado',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  );
                                                },
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
                                  itemCount: movimentacoes.length,
                                  itemBuilder: (context, index) {
                                    final movimentacao = movimentacoes[index];
                                    return AppCard(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  movimentacao.tipo ==
                                                              TipoMovimentacao
                                                                  .entrada ||
                                                          movimentacao.tipo ==
                                                              TipoMovimentacao
                                                                  .trocaEntrada ||
                                                          movimentacao.tipo ==
                                                              TipoMovimentacao
                                                                  .transferenciaEntrada
                                                      ? Icons.add_circle
                                                      : Icons.remove_circle,
                                                  color:
                                                      movimentacao.tipo ==
                                                              TipoMovimentacao
                                                                  .entrada ||
                                                          movimentacao.tipo ==
                                                              TipoMovimentacao
                                                                  .trocaEntrada ||
                                                          movimentacao.tipo ==
                                                              TipoMovimentacao
                                                                  .transferenciaEntrada
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _getTipoDisplay(
                                                          movimentacao.tipo,
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              movimentacao.tipo ==
                                                                      TipoMovimentacao
                                                                          .entrada ||
                                                                  movimentacao
                                                                          .tipo ==
                                                                      TipoMovimentacao
                                                                          .trocaEntrada ||
                                                                  movimentacao
                                                                          .tipo ==
                                                                      TipoMovimentacao
                                                                          .transferenciaEntrada
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${movimentacao.quantidade} unidades',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '${movimentacao.criadoEm.day.toString().padLeft(2, '0')}/${movimentacao.criadoEm.month.toString().padLeft(2, '0')}/${movimentacao.criadoEm.year}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            produtosAsync.maybeWhen(
                                              data: (produtos) {
                                                final produto = produtos.firstWhere(
                                                  (p) =>
                                                      p.id ==
                                                      movimentacao.produtoId,
                                                  orElse: () => ProdutoModel(
                                                    id: '',
                                                    nome:
                                                        'Produto não encontrado',
                                                    sku: '',
                                                    codigo: '',
                                                    precoCusto: 0,
                                                    precoAtacado: 0,
                                                    precoVarejo: 0,
                                                  ),
                                                );
                                                return Text(
                                                  produto.nome,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              },
                                              orElse: () =>
                                                  const Text('Carregando...'),
                                            ),
                                            if (movimentacao.observacao !=
                                                null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                movimentacao.observacao!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            FutureBuilder<String>(
                                              future: _getNomeUsuario(
                                                movimentacao.criadoPor,
                                              ),
                                              builder: (context, snapshot) {
                                                return Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_outline,
                                                      size: 16,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      snapshot.data ??
                                                          'Usuário não encontrado',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors
                                                                .grey[500],
                                                          ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
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
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getNomeUsuario(String? usuarioId) async {
    if (usuarioId == null) return 'Usuário não informado';

    try {
      final usuarioService = UsuarioService();
      final usuarios = await usuarioService.getUsuarios();
      final usuario = usuarios.firstWhere(
        (u) => u.id == usuarioId,
        orElse: () => throw Exception('Usuário não encontrado'),
      );
      return usuario.nome;
    } catch (e) {
      return 'Usuário não encontrado';
    }
  }

  String _getTipoDisplay(TipoMovimentacao tipo) {
    switch (tipo) {
      case TipoMovimentacao.entrada:
        return 'Entrada';
      case TipoMovimentacao.saida:
        return 'Saída';
      case TipoMovimentacao.trocaEntrada:
        return 'Troca (Entrada)';
      case TipoMovimentacao.trocaSaida:
        return 'Troca (Saída)';
      case TipoMovimentacao.transferenciaEntrada:
        return 'Transferência (Entrada)';
      case TipoMovimentacao.transferenciaSaida:
        return 'Transferência (Saída)';
    }
  }
}
