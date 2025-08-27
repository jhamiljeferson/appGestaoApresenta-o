import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/fornecedor_controller.dart';
import '../models/fornecedor_model.dart';
import 'fornecedor_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class FornecedorListView extends ConsumerStatefulWidget {
  const FornecedorListView({Key? key}) : super(key: key);

  @override
  ConsumerState<FornecedorListView> createState() => _FornecedorListViewState();
}

class _FornecedorListViewState extends ConsumerState<FornecedorListView> {
  final TextEditingController filtroNomeController = TextEditingController();
  String filtroTipoDocumento = '';

  @override
  void dispose() {
    filtroNomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fornecedoresAsync = ref.watch(fornecedorProvider);
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Fornecedores',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Fornecedores'),
            ],
            currentRoute: '/fornecedores',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'fornecedores' && p['acao'] == 'criar',
            );
            final podeEditar = permissoes.any(
              (p) => p['recurso'] == 'fornecedores' && p['acao'] == 'atualizar',
            );
            final podeExcluir = permissoes.any(
              (p) => p['recurso'] == 'fornecedores' && p['acao'] == 'deletar',
            );
            return MainLayout(
              title: 'Fornecedores',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Fornecedores'),
              ],
              currentRoute: '/fornecedores',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Fornecedor'),
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
                        builder: (_) => const FornecedorFormView(),
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
                        DropdownButton<String>(
                          value: filtroTipoDocumento.isEmpty
                              ? null
                              : filtroTipoDocumento,
                          hint: const Text('Tipo Documento'),
                          items: const [
                            DropdownMenuItem<String>(
                              value: '',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'CPF',
                              child: Text('CPF'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'CNPJ',
                              child: Text('CNPJ'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => filtroTipoDocumento = v ?? ''),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: fornecedoresAsync.when(
                        loading: () => const AppLoading(),
                        error: (e, _) => Center(
                          child: Text('Erro ao carregar fornecedores'),
                        ),
                        data: (fornecedores) {
                          final filtroNome = filtroNomeController.text
                              .toLowerCase();
                          final filtrados = fornecedores.where((f) {
                            final matchNome =
                                filtroNome.isEmpty ||
                                f.nome.toLowerCase().contains(filtroNome);
                            final matchTipo =
                                filtroTipoDocumento.isEmpty ||
                                f.tipoDocumento == filtroTipoDocumento;
                            return matchNome && matchTipo;
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
                                        DataColumn(label: Text('Tipo')),
                                        DataColumn(label: Text('CPF/CNPJ')),
                                        DataColumn(label: Text('Telefone')),
                                        DataColumn(label: Text('Ações')),
                                      ],
                                      rows: filtrados
                                          .map(
                                            (fornecedor) => DataRow(
                                              cells: [
                                                DataCell(Text(fornecedor.nome)),
                                                DataCell(
                                                  Text(
                                                    fornecedor.tipoDocumento
                                                        .toUpperCase(),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    fornecedor
                                                        .documentoFormatado,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    fornecedor.telefone ?? '-',
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
                                                                FornecedorFormView(
                                                                  fornecedor:
                                                                      fornecedor,
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
                                                                fornecedorProvider
                                                                    .notifier,
                                                              )
                                                              .deleteFornecedor(
                                                                fornecedor.id,
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
                                        (fornecedor) => AppCard(
                                          child: ListTile(
                                            title: Text(fornecedor.nome),
                                            subtitle: Text(
                                              '${fornecedor.tipoDocumento}: ${fornecedor.documentoFormatado}',
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
                                                          FornecedorFormView(
                                                            fornecedor:
                                                                fornecedor,
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
                                                          fornecedorProvider
                                                              .notifier,
                                                        )
                                                        .deleteFornecedor(
                                                          fornecedor.id,
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
