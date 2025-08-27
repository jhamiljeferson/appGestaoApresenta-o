import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/categoria_controller.dart';
import 'categoria_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class CategoriaListView extends ConsumerStatefulWidget {
  const CategoriaListView({super.key});

  @override
  ConsumerState<CategoriaListView> createState() => _CategoriaListViewState();
}

class _CategoriaListViewState extends ConsumerState<CategoriaListView> {
  final TextEditingController filtroController = TextEditingController();
  String filtro = '';

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
          if (podeCriar && message == 'Nenhuma categoria cadastrada') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar Primeira Categoria'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CategoriaFormView(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriaProvider);
    final categoriaCountAsync = ref.watch(categoriaCountProvider);

    // Refresh automático quando o count muda
    ref.listen(categoriaCountProvider, (previous, next) {
      next.whenData((count) {
        if (previous?.value != count) {
          // Se o número de categorias mudou, recarregar a lista
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(categoriaProvider.notifier).loadCategorias();
          });
        }
      });
    });

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Categorias',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Categorias'),
            ],
            currentRoute: '/categorias',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'categorias' && p['acao'] == 'criar',
            );
            final podeEditar = permissoes.any(
              (p) => p['recurso'] == 'categorias' && p['acao'] == 'atualizar',
            );
            final podeExcluir = permissoes.any(
              (p) => p['recurso'] == 'categorias' && p['acao'] == 'deletar',
            );

            String title = 'Categorias';
            categoriaCountAsync.whenData((count) {
              if (count > 0) {
                title = 'Categorias ($count)';
              }
            });

            return MainLayout(
              title: title,
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Categorias'),
              ],
              currentRoute: '/categorias',
              onSidebarItemSelected: (route) =>
                  context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar lista',
                  onPressed: () {
                    ref.read(categoriaProvider.notifier).loadCategorias();
                    ref.invalidate(categoriaCountProvider);
                  },
                ),
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Categoria'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CategoriaFormView(),
                      );
                    },
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    // Widget de estatísticas
                    Consumer(
                      builder: (context, ref, child) {
                        final countAsync = ref.watch(categoriaCountProvider);
                        return countAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (count) {
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total de Categorias',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                        Text(
                                          '$count categoria${count > 1 ? 's' : ''} cadastrada${count > 1 ? 's' : ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: filtroController,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por nome',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => filtro = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: categoriasAsync.when(
                        loading: () => const AppLoading(),
                        error: (e, _) =>
                            Center(child: Text('Erro ao carregar categorias')),
                        data: (categorias) {
                          final filtradas = filtro.isEmpty
                              ? categorias
                              : categorias
                                    .where(
                                      (c) => c.nome.toLowerCase().contains(
                                        filtro.toLowerCase(),
                                      ),
                                    )
                                    .toList();

                          // Se não há categorias, mostrar mensagem para cadastrar
                          if (categorias.isEmpty) {
                            return _buildEmptyState(
                              podeCriar: podeCriar,
                              message: 'Nenhuma categoria cadastrada',
                              subtitle:
                                  'Cadastre sua primeira categoria para começar',
                              icon: Icons.category_outlined,
                            );
                          }

                          // Se há categorias mas o filtro não retornou resultados
                          if (filtradas.isEmpty && filtro.isNotEmpty) {
                            return _buildEmptyState(
                              podeCriar: podeCriar,
                              message: 'Nenhuma categoria encontrada',
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
                                        DataColumn(label: Text('Nome')),
                                        DataColumn(label: Text('Ações')),
                                      ],
                                      rows: filtradas
                                          .map(
                                            (categoria) => DataRow(
                                              cells: [
                                                DataCell(Text(categoria.nome)),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      if (podeEditar)
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit,
                                                          ),
                                                          tooltip: 'Editar',
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) =>
                                                                  CategoriaFormView(
                                                                    categoria:
                                                                        categoria,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                      if (podeExcluir)
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                          ),
                                                          tooltip: 'Excluir',
                                                          onPressed: () async {
                                                            await ref
                                                                .read(
                                                                  categoriaProvider
                                                                      .notifier,
                                                                )
                                                                .deleteCategoria(
                                                                  categoria.id,
                                                                );
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                              } else {
                                return ListView(
                                  children: filtradas
                                      .map(
                                        (categoria) => AppCard(
                                          child: ListTile(
                                            title: Text(categoria.nome),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (podeEditar)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) =>
                                                            CategoriaFormView(
                                                              categoria:
                                                                  categoria,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                if (podeExcluir)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    onPressed: () async {
                                                      await ref
                                                          .read(
                                                            categoriaProvider
                                                                .notifier,
                                                          )
                                                          .deleteCategoria(
                                                            categoria.id,
                                                          );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
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
}
