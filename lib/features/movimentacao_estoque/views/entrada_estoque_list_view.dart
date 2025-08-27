import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';

import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_feedback.dart';
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

class EntradaEstoqueListView extends ConsumerStatefulWidget {
  const EntradaEstoqueListView({super.key});

  @override
  ConsumerState<EntradaEstoqueListView> createState() =>
      _EntradaEstoqueListViewState();
}

class _EntradaEstoqueListViewState
    extends ConsumerState<EntradaEstoqueListView> {
  final TextEditingController filtroController = TextEditingController();
  String filtro = '';

  @override
  void initState() {
    super.initState();
    // Carregar movimentações quando a tela for montada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movimentacaoEstoqueProvider.notifier).loadMovimentacoes();
    });
  }

  @override
  void dispose() {
    filtroController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState({
    required bool podeCriar,
    required String message,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (podeCriar && message == 'Nenhuma entrada encontrada') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar Primeira Entrada'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                context.go('/nova-entrada-estoque');
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movimentacoesAsync = ref.watch(movimentacaoEstoqueProvider);
    final produtosAsync = ref.watch(produtoProvider);
    final lojasAsync = ref.watch(lojaProvider);
    final lojaAtiva = ref.watch(lojaAtivaProvider);

    // Filtra apenas as entradas simples
    final entradasAsync = movimentacoesAsync.when(
      data: (movimentacoes) {
        final entradas = movimentacoes
            .where((m) => m.tipo == TipoMovimentacao.entrada)
            .toList();
        return AsyncValue.data(entradas);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Entradas de Estoque',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Entradas'),
            ],
            currentRoute: '/entradas-estoque',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'criar',
            );
            final podeEditar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'atualizar',
            );
            final podeExcluir = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'deletar',
            );

            return MainLayout(
              title: '📦 Entradas de Estoque',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Entradas'),
              ],
              currentRoute: '/entradas-estoque',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar lista',
                  onPressed: () {
                    ref
                        .read(movimentacaoEstoqueProvider.notifier)
                        .loadMovimentacoes();
                  },
                ),
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Nova Entrada'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      context.go('/nova-entrada-estoque');
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
                                      color: Colors.green[700],
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
                                                  color: Colors.green[700],
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
                                                  color: Colors.green[700],
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

                    // Campo de filtro
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: filtroController,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por produto',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => filtro = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Lista de entradas
                    Expanded(
                      child: entradasAsync.when(
                        loading: () => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Carregando entradas...'),
                            ],
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text('Erro ao carregar entradas: $e'),
                        ),
                        data: (entradas) {
                          // Aplicar filtro
                          final filtradas = filtro.isEmpty
                              ? entradas
                              : entradas.where((entrada) {
                                  return produtosAsync.maybeWhen(
                                    data: (produtos) {
                                      final produto = produtos.firstWhere(
                                        (p) => p.id == entrada.produtoId,
                                        orElse: () => ProdutoModel(
                                          id: '',
                                          nome: '',
                                          sku: '',
                                          codigo: '',
                                          precoCusto: 0,
                                          precoAtacado: 0,
                                          precoVarejo: 0,
                                        ),
                                      );
                                      return produto.nome
                                          .toLowerCase()
                                          .contains(filtro.toLowerCase());
                                    },
                                    orElse: () => false,
                                  );
                                }).toList();

                          // Se não há entradas, mostrar mensagem para cadastrar
                          if (entradas.isEmpty) {
                            return _buildEmptyState(
                              podeCriar: podeCriar,
                              message: 'Nenhuma entrada encontrada',
                              subtitle:
                                  'Cadastre sua primeira entrada para começar',
                              icon: Icons.add_circle_outline,
                            );
                          }

                          // Se há entradas mas o filtro não retornou resultados
                          if (filtradas.isEmpty && filtro.isNotEmpty) {
                            return _buildEmptyState(
                              podeCriar: podeCriar,
                              message: 'Nenhuma entrada encontrada',
                              subtitle: 'Tente ajustar o filtro de busca',
                              icon: Icons.search_off,
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
                                        DataColumn(label: Text('Produto')),
                                        DataColumn(label: Text('Quantidade')),
                                        DataColumn(label: Text('Observação')),
                                        DataColumn(label: Text('Usuário')),
                                        DataColumn(label: Text('Ações')),
                                      ],
                                      rows: filtradas.map<DataRow>((entrada) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                '${entrada.criadoEm.day.toString().padLeft(2, '0')}/${entrada.criadoEm.month.toString().padLeft(2, '0')}/${entrada.criadoEm.year}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                            DataCell(
                                              produtosAsync.maybeWhen(
                                                data: (produtos) {
                                                  final produto = produtos.firstWhere(
                                                    (p) =>
                                                        p.id ==
                                                        entrada.produtoId,
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
                                                '${entrada.quantidade} unidades',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                entrada.observacao ?? '-',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                            DataCell(
                                              FutureBuilder<String>(
                                                future: _getNomeUsuario(
                                                  entrada.criadoPor,
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
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (podeEditar)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _editarEntrada(
                                                          context,
                                                          entrada,
                                                        );
                                                      },
                                                      tooltip: 'Editar',
                                                    ),
                                                  if (podeExcluir)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        size: 20,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        _excluirEntrada(
                                                          context,
                                                          ref,
                                                          entrada,
                                                        );
                                                      },
                                                      tooltip: 'Excluir',
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
                                    final entrada = filtradas[index];
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
                                                  Icons.add_circle,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Entrada',
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${entrada.quantidade} unidades',
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
                                                  '${entrada.criadoEm.day.toString().padLeft(2, '0')}/${entrada.criadoEm.month.toString().padLeft(2, '0')}/${entrada.criadoEm.year}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                                if (podeEditar ||
                                                    podeExcluir) ...[
                                                  const SizedBox(width: 8),
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(
                                                      Icons.more_vert,
                                                    ),
                                                    onSelected: (value) {
                                                      if (value == 'edit' &&
                                                          podeEditar) {
                                                        _editarEntrada(
                                                          context,
                                                          entrada,
                                                        );
                                                      } else if (value ==
                                                              'delete' &&
                                                          podeExcluir) {
                                                        _excluirEntrada(
                                                          context,
                                                          ref,
                                                          entrada,
                                                        );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      if (podeEditar)
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.edit,
                                                                size: 16,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text('Editar'),
                                                            ],
                                                          ),
                                                        ),
                                                      if (podeExcluir)
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.delete,
                                                                size: 16,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Excluir',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            produtosAsync.maybeWhen(
                                              data: (produtos) {
                                                final produto = produtos.firstWhere(
                                                  (p) =>
                                                      p.id == entrada.produtoId,
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
                                            if (entrada.observacao != null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                entrada.observacao!,
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
                                                entrada.criadoPor,
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

  void _editarEntrada(BuildContext context, MovimentacaoEstoqueModel entrada) {
    // TODO: Implementar edição
    AppFeedback.showSuccess(
      context,
      'Funcionalidade de edição será implementada em breve',
    );
  }

  void _excluirEntrada(
    BuildContext context,
    WidgetRef ref,
    MovimentacaoEstoqueModel entrada,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir esta entrada?\n\nProduto: ${entrada.produtoId}\nQuantidade: ${entrada.quantidade}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(movimentacaoEstoqueProvider.notifier)
                    .deleteMovimentacao(entrada.id);
                if (!mounted) return;
                AppFeedback.showSuccess(
                  context,
                  'Entrada excluída com sucesso!',
                );
              } catch (e) {
                if (!mounted) return;
                AppFeedback.showError(context, 'Erro ao excluir entrada: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
