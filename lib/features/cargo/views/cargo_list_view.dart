import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/cargo_controller.dart';
import '../models/cargo_model.dart';
import 'cargo_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class CargoListView extends ConsumerStatefulWidget {
  const CargoListView({Key? key}) : super(key: key);

  @override
  ConsumerState<CargoListView> createState() => _CargoListViewState();
}

class _CargoListViewState extends ConsumerState<CargoListView> {
  final TextEditingController filtroController = TextEditingController();
  String filtro = '';

  @override
  void dispose() {
    filtroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cargosAsync = ref.watch(cargoProvider);
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Cargos',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Cargos'),
            ],
            currentRoute: '/cargos',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'cargos' && p['acao'] == 'criar',
            );
            final podeEditar = permissoes.any(
              (p) => p['recurso'] == 'cargos' && p['acao'] == 'atualizar',
            );
            final podeExcluir = permissoes.any(
              (p) => p['recurso'] == 'cargos' && p['acao'] == 'deletar',
            );
            return MainLayout(
              title: 'Cargos',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Cargos'),
              ],
              currentRoute: '/cargos',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Cargo'),
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
                        builder: (_) => const CargoFormView(),
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
                      child: cargosAsync.when(
                        loading: () => const AppLoading(),
                        error: (e, _) =>
                            Center(child: Text('Erro ao carregar cargos')),
                        data: (cargos) {
                          final filtrados = filtro.isEmpty
                              ? cargos
                              : cargos
                                    .where(
                                      (c) => c.nome.toLowerCase().contains(
                                        filtro.toLowerCase(),
                                      ),
                                    )
                                    .toList();
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
                                      rows: filtrados
                                          .map(
                                            (cargo) => DataRow(
                                              cells: [
                                                DataCell(Text(cargo.nome)),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                        tooltip: 'Editar',
                                                        onPressed: podeEditar
                                                            ? () {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder: (_) =>
                                                                      CargoFormView(
                                                                        cargo:
                                                                            cargo,
                                                                      ),
                                                                );
                                                              }
                                                            : null,
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                        ),
                                                        tooltip: 'Excluir',
                                                        onPressed: podeExcluir
                                                            ? () async {
                                                                await ref
                                                                    .read(
                                                                      cargoProvider
                                                                          .notifier,
                                                                    )
                                                                    .deleteCargo(
                                                                      cargo.id,
                                                                    );
                                                              }
                                                            : null,
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
                                        (cargo) => AppCard(
                                          child: ListTile(
                                            title: Text(cargo.nome),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: podeEditar
                                                      ? () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                CargoFormView(
                                                                  cargo: cargo,
                                                                ),
                                                          );
                                                        }
                                                      : null,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                  ),
                                                  onPressed: podeExcluir
                                                      ? () async {
                                                          await ref
                                                              .read(
                                                                cargoProvider
                                                                    .notifier,
                                                              )
                                                              .deleteCargo(
                                                                cargo.id,
                                                              );
                                                        }
                                                      : null,
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
