import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/loja_controller.dart';
import 'loja_form_view.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class LojaListView extends ConsumerWidget {
  const LojaListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lojasAsync = ref.watch(lojaProvider);
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Lojas',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Lojas'),
            ],
            currentRoute: '/lojas',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'lojas' && p['acao'] == 'criar',
            );
            final podeEditar = permissoes.any(
              (p) => p['recurso'] == 'lojas' && p['acao'] == 'atualizar',
            );
            final podeExcluir = permissoes.any(
              (p) => p['recurso'] == 'lojas' && p['acao'] == 'deletar',
            );
            return MainLayout(
              title: 'Lojas',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Lojas'),
              ],
              currentRoute: '/lojas',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Loja'),
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
                        builder: (_) => const LojaFormView(),
                      );
                    },
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 8,
                ),
                child: lojasAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, _) =>
                      Center(child: Text('Erro ao carregar lojas')),
                  data: (lojas) => LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        // Tabela para desktop
                        return AppCard(
                          padding: const EdgeInsets.all(0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nome')),
                                DataColumn(label: Text('Shopping')),
                                DataColumn(label: Text('Andar')),
                                DataColumn(label: Text('Número')),
                                DataColumn(label: Text('Qtd. Mín. Atacado')),
                                DataColumn(label: Text('Ações')),
                              ],
                              rows: lojas
                                  .map(
                                    (loja) => DataRow(
                                      cells: [
                                        DataCell(Text(loja.nome)),
                                        DataCell(Text(loja.shopping)),
                                        DataCell(Text(loja.andar)),
                                        DataCell(Text(loja.numero)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${loja.quantidadeMinimaAtacado}',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                tooltip: 'Editar',
                                                onPressed: podeEditar
                                                    ? () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) =>
                                                              LojaFormView(
                                                                loja: loja,
                                                              ),
                                                        );
                                                      }
                                                    : null,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                tooltip: 'Excluir',
                                                onPressed: podeExcluir
                                                    ? () async {
                                                        await ref
                                                            .read(
                                                              lojaProvider
                                                                  .notifier,
                                                            )
                                                            .deleteLoja(
                                                              loja.id,
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
                        // Cards para mobile
                        return ListView.separated(
                          itemCount: lojas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final loja = lojas[index];
                            return AppCard(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.store,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          loja.nome,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Editar',
                                        onPressed: podeEditar
                                            ? () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      LojaFormView(loja: loja),
                                                );
                                              }
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Excluir',
                                        onPressed: podeExcluir
                                            ? () async {
                                                await ref
                                                    .read(lojaProvider.notifier)
                                                    .deleteLoja(loja.id);
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_city,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        loja.shopping,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.stairs,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Andar: ${loja.andar}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.confirmation_number,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Nº ${loja.numero}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_offer,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qtd. Mín. Atacado: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${loja.quantidadeMinimaAtacado}',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
