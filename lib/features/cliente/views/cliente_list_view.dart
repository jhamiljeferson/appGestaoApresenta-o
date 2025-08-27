import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cliente_model.dart';
import '../controllers/cliente_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../features/lojas/providers/loja_ativa_provider.dart';
import '../../../features/lojas/controllers/loja_controller.dart';
import '../../../features/lojas/models/loja_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/usuario/controllers/usuario_controller.dart';

class ClienteListView extends ConsumerStatefulWidget {
  const ClienteListView({super.key});

  @override
  ConsumerState<ClienteListView> createState() => _ClienteListViewState();
}

class _ClienteListViewState extends ConsumerState<ClienteListView> {
  String filtroNome = '';
  String filtroTipoDocumento = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lojaAtiva = ref.read(lojaAtivaProvider);
      if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
        ref.read(clienteProvider.notifier).loadClientesPorLoja(lojaAtiva);
      } else {
        ref.read(clienteProvider.notifier).loadClientes();
      }
    });
  }

  List<ClienteModel> getClientesFiltrados(List<ClienteModel> clientes) {
    return clientes.where((cliente) {
      final matchNome =
          filtroNome.isEmpty ||
          cliente.nome.toLowerCase().contains(filtroNome.toLowerCase());
      final matchTipo =
          filtroTipoDocumento.isEmpty ||
          cliente.tipoDocumento == filtroTipoDocumento;
      return matchNome && matchTipo;
    }).toList();
  }

  void _deletarCliente(ClienteModel cliente) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o cliente "${cliente.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(clienteProvider.notifier)
                      .deleteCliente(cliente.id);
                  if (mounted) {
                    AppFeedback.showSuccess(
                      context,
                      'Cliente excluído com sucesso!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppFeedback.showError(
                      context,
                      'Erro ao excluir cliente: $e',
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

  @override
  Widget build(BuildContext context) {
    final clienteAsync = ref.watch(clienteProvider);
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
            title: 'Clientes',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Clientes'),
            ],
            currentRoute: '/clientes',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            return MainLayout(
              title: '👥 Clientes',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Clientes'),
              ],
              currentRoute: '/clientes',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar lista',
                  onPressed: () {
                    final lojaAtiva = ref.read(lojaAtivaProvider);
                    if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
                      ref
                          .read(clienteProvider.notifier)
                          .loadClientesPorLoja(lojaAtiva);
                    } else {
                      ref.read(clienteProvider.notifier).loadClientes();
                    }
                  },
                ),
                if (permissoes.any(
                  (p) => p['recurso'] == 'clientes' && p['acao'] == 'criar',
                ))
                  ElevatedButton.icon(
                    onPressed: () => context.go('/clientes/novo'),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Cliente'),
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
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Clientes da Loja: ${loja.nome}',
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
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Buscar por nome',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          filtroNome = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Tipo de Documento',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: filtroTipoDocumento.isEmpty
                                          ? null
                                          : filtroTipoDocumento,
                                      items: const [
                                        DropdownMenuItem(
                                          value: '',
                                          child: Text('Todos'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'CPF',
                                          child: Text('CPF'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'CNPJ',
                                          child: Text('CNPJ'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          filtroTipoDocumento = value ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Buscar por nome',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        filtroNome = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Tipo de Documento',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: filtroTipoDocumento.isEmpty
                                        ? null
                                        : filtroTipoDocumento,
                                    items: const [
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text('Todos'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CPF',
                                        child: Text('CPF'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CNPJ',
                                        child: Text('CNPJ'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        filtroTipoDocumento = value ?? '';
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

                  // Lista de clientes
                  Expanded(
                    child: clienteAsync.when(
                      loading: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Carregando clientes...'),
                          ],
                        ),
                      ),
                      error: (e, _) =>
                          Center(child: Text('Erro ao carregar clientes: $e')),
                      data: (clientes) {
                        final filtrados = getClientesFiltrados(clientes);

                        if (filtrados.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum cliente encontrado',
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
                            final isWide = constraints.maxWidth > 700;

                            if (isWide) {
                              return AppCard(
                                padding: const EdgeInsets.all(0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Nome')),
                                      DataColumn(label: Text('Tipo Doc.')),
                                      DataColumn(label: Text('Documento')),
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Telefone')),
                                      DataColumn(label: Text('Ações')),
                                    ],
                                    rows: filtrados.map((cliente) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            InkWell(
                                              onTap: () => context.go(
                                                '/clientes/${cliente.id}',
                                              ),
                                              child: Text(
                                                cliente.nome,
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
                                            Text(cliente.tipoDocumento ?? '-'),
                                          ),
                                          DataCell(
                                            Text(cliente.documento ?? '-'),
                                          ),
                                          DataCell(Text(cliente.email ?? '-')),
                                          DataCell(
                                            Text(cliente.telefone ?? '-'),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (permissoes.any(
                                                  (p) =>
                                                      p['recurso'] ==
                                                          'clientes' &&
                                                      p['acao'] == 'editar',
                                                ))
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    tooltip: 'Editar',
                                                    onPressed: () => context.go(
                                                      '/clientes/${cliente.id}/editar',
                                                    ),
                                                  ),
                                                if (permissoes.any(
                                                  (p) =>
                                                      p['recurso'] ==
                                                          'clientes' &&
                                                      p['acao'] == 'excluir',
                                                ))
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    tooltip: 'Excluir',
                                                    onPressed: () =>
                                                        _deletarCliente(
                                                          cliente,
                                                        ),
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
                                itemCount: filtrados.length,
                                itemBuilder: (context, index) {
                                  final cliente = filtrados[index];
                                  return AppCard(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () =>
                                          context.go('/clientes/${cliente.id}'),
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
                                                        cliente.nome,
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
                                                      if (cliente
                                                              .tipoDocumento !=
                                                          null)
                                                        Text(
                                                          '${cliente.tipoDocumento}: ${cliente.documento ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Colors.grey[400],
                                                ),
                                                if (permissoes.any(
                                                      (p) =>
                                                          p['recurso'] ==
                                                              'clientes' &&
                                                          p['acao'] == 'editar',
                                                    ) ||
                                                    permissoes.any(
                                                      (p) =>
                                                          p['recurso'] ==
                                                              'clientes' &&
                                                          p['acao'] ==
                                                              'excluir',
                                                    ))
                                                  PopupMenuButton<String>(
                                                    onSelected: (value) {
                                                      switch (value) {
                                                        case 'edit':
                                                          context.go(
                                                            '/clientes/${cliente.id}/editar',
                                                          );
                                                          break;
                                                        case 'delete':
                                                          _deletarCliente(
                                                            cliente,
                                                          );
                                                          break;
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      if (permissoes.any(
                                                        (p) =>
                                                            p['recurso'] ==
                                                                'clientes' &&
                                                            p['acao'] ==
                                                                'editar',
                                                      ))
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text('Editar'),
                                                            ],
                                                          ),
                                                        ),
                                                      if (permissoes.any(
                                                        (p) =>
                                                            p['recurso'] ==
                                                                'clientes' &&
                                                            p['acao'] ==
                                                                'excluir',
                                                      ))
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.delete,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text('Excluir'),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            if (cliente.email != null ||
                                                cliente.telefone != null)
                                              const SizedBox(height: 8),
                                            if (cliente.email != null)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.email,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      cliente.email!,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (cliente.telefone != null)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      cliente.telefone!,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
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
