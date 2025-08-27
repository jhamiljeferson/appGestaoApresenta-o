import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/usuario_controller.dart';
import '../models/usuario_model.dart';
import '../../cargo/controllers/cargo_controller.dart';
import '../../cargo/models/cargo_model.dart';
import 'usuario_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../auth/controllers/auth_controller.dart';

class UsuarioListView extends ConsumerStatefulWidget {
  const UsuarioListView({Key? key}) : super(key: key);

  @override
  ConsumerState<UsuarioListView> createState() => _UsuarioListViewState();
}

class _UsuarioListViewState extends ConsumerState<UsuarioListView> {
  final TextEditingController filtroNomeController = TextEditingController();
  final TextEditingController filtroEmailController = TextEditingController();
  String filtroCargoId = '';
  bool filtroAtivo = false;

  @override
  void dispose() {
    filtroNomeController.dispose();
    filtroEmailController.dispose();
    super.dispose();
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    String usuarioId,
    String nomeUsuario,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o usuário "$nomeUsuario"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Invalida os providers relacionados ao usuário antes da exclusão
        ref.invalidate(lojasDoUsuarioProvider(usuarioId));

        await ref.read(usuarioProvider.notifier).deleteUsuario(usuarioId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir usuário: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(usuarioProvider);
    final cargosAsync = ref.watch(cargoProvider);
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Usuários',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Usuários'),
            ],
            currentRoute: '/usuarios',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'usuarios' && p['acao'] == 'criar',
            );
            final podeEditar = permissoes.any(
              (p) => p['recurso'] == 'usuarios' && p['acao'] == 'atualizar',
            );
            final podeExcluir = permissoes.any(
              (p) => p['recurso'] == 'usuarios' && p['acao'] == 'deletar',
            );
            return MainLayout(
              title: 'Usuários',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Usuários'),
              ],
              currentRoute: '/usuarios',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Usuário'),
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
                        builder: (_) => const UsuarioFormView(),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: filtroEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        cargosAsync.when(
                          loading: () => const SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(),
                          ),
                          error: (e, _) => const SizedBox(
                            width: 120,
                            child: Text('Erro cargos'),
                          ),
                          data: (cargos) => DropdownButton<String>(
                            value: filtroCargoId.isEmpty ? null : filtroCargoId,
                            hint: const Text('Cargo'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Todos'),
                              ),
                              ...cargos.map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.nome),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => filtroCargoId = v ?? ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: filtroAtivo,
                          onChanged: (v) =>
                              setState(() => filtroAtivo = v ?? false),
                        ),
                        const Text('Ativo'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: usuariosAsync.when(
                        loading: () => const AppLoading(),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar usuários',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                e.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.invalidate(usuarioProvider);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar Novamente'),
                              ),
                            ],
                          ),
                        ),
                        data: (usuarios) {
                          final filtroNome = filtroNomeController.text
                              .toLowerCase();
                          final filtroEmail = filtroEmailController.text
                              .toLowerCase();
                          final filtrados = usuarios.where((u) {
                            final matchNome =
                                filtroNome.isEmpty ||
                                u.nome.toLowerCase().contains(filtroNome);
                            final matchEmail =
                                filtroEmail.isEmpty ||
                                u.email.toLowerCase().contains(filtroEmail);
                            final matchCargo =
                                filtroCargoId.isEmpty ||
                                u.cargoId == filtroCargoId;
                            final matchAtivo = !filtroAtivo || u.ativo;
                            return matchNome &&
                                matchEmail &&
                                matchCargo &&
                                matchAtivo;
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
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Cargo')),
                                        DataColumn(label: Text('Lojas')),
                                        DataColumn(label: Text('Ativo')),
                                        DataColumn(label: Text('Ações')),
                                      ],
                                      rows: filtrados
                                          .map(
                                            (usuario) => DataRow(
                                              cells: [
                                                DataCell(Text(usuario.nome)),
                                                DataCell(Text(usuario.email)),
                                                DataCell(
                                                  cargosAsync.maybeWhen(
                                                    data: (cargos) => Text(
                                                      cargos
                                                          .firstWhere(
                                                            (c) =>
                                                                c.id ==
                                                                usuario.cargoId,
                                                            orElse: () =>
                                                                CargoModel(
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
                                                  FutureBuilder<
                                                    List<Map<String, dynamic>>
                                                  >(
                                                    future: ref.read(
                                                      lojasDoUsuarioProvider(
                                                        usuario.id,
                                                      ).future,
                                                    ),
                                                    builder: (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        );
                                                      }
                                                      if (snapshot.hasError) {
                                                        return const Text(
                                                          'Erro',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.red,
                                                          ),
                                                        );
                                                      }
                                                      if (!snapshot.hasData) {
                                                        return const Text('-');
                                                      }
                                                      final lojas =
                                                          snapshot.data!;
                                                      if (lojas.isEmpty) {
                                                        return const Text(
                                                          'Nenhuma loja',
                                                        );
                                                      }
                                                      return Text(
                                                        '${lojas.length} loja${lojas.length > 1 ? 's' : ''}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                DataCell(
                                                  Icon(
                                                    usuario.ativo
                                                        ? Icons.check
                                                        : Icons.close,
                                                    color: usuario.ativo
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
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
                                                                  UsuarioFormView(
                                                                    usuario:
                                                                        usuario,
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
                                                            await _confirmarExclusao(
                                                              context,
                                                              ref,
                                                              usuario.id,
                                                              usuario.nome,
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
                                        (usuario) => AppCard(
                                          child: ListTile(
                                            title: Text(usuario.nome),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(usuario.email),
                                                const SizedBox(height: 4),
                                                FutureBuilder<
                                                  List<Map<String, dynamic>>
                                                >(
                                                  future: ref.read(
                                                    lojasDoUsuarioProvider(
                                                      usuario.id,
                                                    ).future,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      );
                                                    }
                                                    if (snapshot.hasError) {
                                                      return const Text(
                                                        'Lojas: Erro',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                    if (!snapshot.hasData) {
                                                      return const Text(
                                                        'Lojas: -',
                                                      );
                                                    }
                                                    final lojas =
                                                        snapshot.data!;
                                                    if (lojas.isEmpty) {
                                                      return const Text(
                                                        'Lojas: Nenhuma',
                                                      );
                                                    }
                                                    return Text(
                                                      'Lojas: ${lojas.length} loja${lojas.length > 1 ? 's' : ''}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
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
                                                            UsuarioFormView(
                                                              usuario: usuario,
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
                                                      await _confirmarExclusao(
                                                        context,
                                                        ref,
                                                        usuario.id,
                                                        usuario.nome,
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
