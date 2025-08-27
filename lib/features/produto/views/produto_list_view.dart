import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/produto_controller.dart';
import '../models/produto_model.dart';
import '../../categoria/controllers/categoria_controller.dart';
import '../../categoria/models/categoria_model.dart';
import 'produto_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class ProdutoListView extends ConsumerStatefulWidget {
  const ProdutoListView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProdutoListView> createState() => _ProdutoListViewState();
}

class _ProdutoListViewState extends ConsumerState<ProdutoListView> {
  final TextEditingController filtroNomeController = TextEditingController();
  String filtroCategoriaId = '';

  @override
  void dispose() {
    filtroNomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produtosAsync = ref.watch(produtoProvider);
    final categoriasAsync = ref.watch(categoriaProvider);
    // Provider para cargoId do usuário logado
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Produtos',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Produtos'),
            ],
            currentRoute: '/produtos',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'produtos' && p['acao'] == 'criar',
            );
            return MainLayout(
              title: 'Produtos',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Produtos'),
              ],
              currentRoute: '/produtos',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Produto'),
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
                        builder: (_) => const ProdutoFormView(),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: filtroNomeController,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por nome',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        categoriasAsync.when(
                          loading: () => const SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(),
                          ),
                          error: (e, _) => const SizedBox(
                            width: 120,
                            child: Text('Erro categorias'),
                          ),
                          data: (categorias) => DropdownButton<String>(
                            value: filtroCategoriaId.isEmpty
                                ? null
                                : filtroCategoriaId,
                            hint: const Text('Categoria'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Todas'),
                              ),
                              ...categorias.map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.nome),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => filtroCategoriaId = v ?? ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: produtosAsync.when(
                        loading: () => const AppLoading(),
                        error: (e, _) =>
                            Center(child: Text('Erro ao carregar produtos')),
                        data: (produtos) {
                          final filtroNome = filtroNomeController.text
                              .toLowerCase();
                          final filtrados = produtos.where((p) {
                            final matchNome =
                                filtroNome.isEmpty ||
                                p.nome.toLowerCase().contains(filtroNome);
                            final matchCategoria =
                                filtroCategoriaId.isEmpty ||
                                p.categoriaId == filtroCategoriaId;
                            return matchNome && matchCategoria;
                          }).toList();
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
                                        DataColumn(label: Text('SKU')),
                                        DataColumn(label: Text('Código')),
                                        DataColumn(label: Text('Categoria')),
                                        DataColumn(label: Text('Preço Varejo')),
                                        DataColumn(label: Text('Ações')),
                                      ],
                                      rows: filtrados
                                          .map(
                                            (produto) => DataRow(
                                              cells: [
                                                DataCell(Text(produto.nome)),
                                                DataCell(Text(produto.sku)),
                                                DataCell(Text(produto.codigo)),
                                                DataCell(
                                                  categoriasAsync.maybeWhen(
                                                    data: (cats) => Text(
                                                      cats
                                                          .firstWhere(
                                                            (c) =>
                                                                c.id ==
                                                                produto
                                                                    .categoriaId,
                                                            orElse: () =>
                                                                CategoriaModel(
                                                                  id: '',
                                                                  nome: '-',
                                                                ),
                                                          )
                                                          .nome,
                                                    ),
                                                    orElse: () =>
                                                        const Text('-'),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    produto.precoVarejo
                                                        .toStringAsFixed(2),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                        tooltip: 'Editar',
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                ProdutoFormView(
                                                                  produto:
                                                                      produto,
                                                                ),
                                                          );
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                        ),
                                                        tooltip: 'Excluir',
                                                        onPressed: () async {
                                                          await ref
                                                              .read(
                                                                produtoProvider
                                                                    .notifier,
                                                              )
                                                              .deleteProduto(
                                                                produto.id,
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
                                  children: filtrados
                                      .map(
                                        (produto) => AppCard(
                                          child: ListTile(
                                            title: Text(produto.nome),
                                            subtitle: Text(
                                              'SKU: ${produto.sku}',
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          ProdutoFormView(
                                                            produto: produto,
                                                          ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                  ),
                                                  onPressed: () async {
                                                    await ref
                                                        .read(
                                                          produtoProvider
                                                              .notifier,
                                                        )
                                                        .deleteProduto(
                                                          produto.id,
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
