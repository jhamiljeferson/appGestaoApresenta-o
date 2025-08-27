import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/forma_pagamento_controller.dart';
import '../models/forma_pagamento_model.dart';
import 'forma_pagamento_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class FormaPagamentoListView extends ConsumerStatefulWidget {
  const FormaPagamentoListView({Key? key}) : super(key: key);

  @override
  ConsumerState<FormaPagamentoListView> createState() =>
      _FormaPagamentoListViewState();
}

class _FormaPagamentoListViewState
    extends ConsumerState<FormaPagamentoListView> {
  final TextEditingController filtroNomeController = TextEditingController();

  @override
  void dispose() {
    filtroNomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formasPagamentoAsync = ref.watch(formaPagamentoProvider);

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Formas de Pagamento',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Formas de Pagamento'),
            ],
            currentRoute: '/formas-pagamento',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'formas_pagamento' && p['acao'] == 'criar',
            );

            return MainLayout(
              title: 'Formas de Pagamento',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Formas de Pagamento'),
              ],
              currentRoute: '/formas-pagamento',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Pagamento'),
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
                        builder: (_) => const FormaPagamentoFormView(),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: formasPagamentoAsync.when(
                        loading: () => const AppLoading(),
                        error: (e, _) => Center(
                          child: Text('Erro ao carregar formas de pagamento'),
                        ),
                        data: (formasPagamento) {
                          final filtroNome = filtroNomeController.text
                              .toLowerCase();
                          final filtrados = formasPagamento.where((fp) {
                            return filtroNome.isEmpty ||
                                fp.nome.toLowerCase().contains(filtroNome);
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
                                        DataColumn(label: Text('Tipo de Taxa')),
                                        DataColumn(label: Text('Percentual')),
                                        DataColumn(label: Text('Ações')),
                                      ],
                                      rows: filtrados
                                          .map(
                                            (formaPagamento) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(formaPagamento.nome),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        formaPagamento
                                                                    .tipoTaxa ==
                                                                TipoTaxa
                                                                    .acrescimo
                                                            ? Icons.add_circle
                                                            : Icons
                                                                  .remove_circle,
                                                        color:
                                                            formaPagamento
                                                                    .tipoTaxa ==
                                                                TipoTaxa
                                                                    .acrescimo
                                                            ? Colors.green
                                                            : Colors.red,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        formaPagamento
                                                                    .tipoTaxa ==
                                                                TipoTaxa
                                                                    .acrescimo
                                                            ? 'Adiciona'
                                                            : 'Desconta',
                                                        style: TextStyle(
                                                          color:
                                                              formaPagamento
                                                                      .tipoTaxa ==
                                                                  TipoTaxa
                                                                      .acrescimo
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '${formaPagamento.percentualTaxa.toStringAsFixed(2)}%',
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
                                                                FormaPagamentoFormView(
                                                                  formaPagamento:
                                                                      formaPagamento,
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
                                                                formaPagamentoProvider
                                                                    .notifier,
                                                              )
                                                              .deleteFormaPagamento(
                                                                formaPagamento
                                                                    .id,
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
                                        (formaPagamento) => AppCard(
                                          child: ListTile(
                                            title: Text(formaPagamento.nome),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      formaPagamento.tipoTaxa ==
                                                              TipoTaxa.acrescimo
                                                          ? Icons.add_circle
                                                          : Icons.remove_circle,
                                                      color:
                                                          formaPagamento
                                                                  .tipoTaxa ==
                                                              TipoTaxa.acrescimo
                                                          ? Colors.green
                                                          : Colors.red,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formaPagamento.tipoTaxa ==
                                                              TipoTaxa.acrescimo
                                                          ? 'Adiciona'
                                                          : 'Desconta',
                                                      style: TextStyle(
                                                        color:
                                                            formaPagamento
                                                                    .tipoTaxa ==
                                                                TipoTaxa
                                                                    .acrescimo
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Taxa: ${formaPagamento.percentualTaxa.toStringAsFixed(2)}%',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
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
                                                          FormaPagamentoFormView(
                                                            formaPagamento:
                                                                formaPagamento,
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
                                                          formaPagamentoProvider
                                                              .notifier,
                                                        )
                                                        .deleteFormaPagamento(
                                                          formaPagamento.id,
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
