import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';

import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../widgets/user_info_dialog.dart';
import '../../auth/controllers/user_info_controller.dart';
import '../../lojas/controllers/loja_controller.dart';
import '../../lojas/providers/loja_ativa_provider.dart';

final dashboardKpiProvider = FutureProvider<Map<String, String>>((ref) async {
  // Simulação: Substitua por chamada real ao backend/service
  await Future.delayed(const Duration(milliseconds: 500));
  return {
    'Empresas': '3',
    'Lojas': '12',
    'Vendas': 'R\$ 12.500',
    'Produtos': '320',
  };
});

// Evita abrir o diálogo de seleção de loja múltiplas vezes por montagem da tela
final _promptedActiveStoreOnceProvider = StateProvider<bool>((ref) => false);

class DashboardView extends ConsumerWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lógica de pós-login: se houver 1 loja, ativa automaticamente; se houver
    // mais de 1 e nenhuma ativa ainda, abre um diálogo para escolha.
    final userInfoAsync = ref.watch(userInfoProvider);
    final lojasCatalogoAsync = ref.watch(lojaProvider);
    final activeStoreId = ref.watch(lojaAtivaProvider);
    final alreadyPrompted = ref.watch(_promptedActiveStoreOnceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      if (alreadyPrompted) return;
      if (activeStoreId != null && activeStoreId.isNotEmpty) return;
      userInfoAsync.when(
        data: (userInfo) {
          final lojasUser = userInfo.lojas; // [{loja_id: ...}]
          if (lojasUser.isEmpty) return;
          lojasCatalogoAsync.when(
            data: (lojasCatalogo) async {
              final idsPermitidos = lojasUser
                  .map((e) => e['loja_id'] as String)
                  .toSet();
              final lojasPermitidas = lojasCatalogo
                  .where((l) => idsPermitidos.contains(l.id))
                  .toList();
              if (lojasPermitidas.isEmpty) return;
              // Marca como já exibido para evitar múltiplas chamadas
              ref.read(_promptedActiveStoreOnceProvider.notifier).state = true;
              if (lojasPermitidas.length == 1) {
                await ref
                    .read(lojaAtivaProvider.notifier)
                    .setActiveStore(lojasPermitidas.first.id);
                return;
              }
              // Solicita escolha
              final selectedId = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  String? tempSelected;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text('Selecione a loja ativa'),
                        content: SizedBox(
                          width: 300,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: lojasPermitidas.length,
                            itemBuilder: (context, index) {
                              final loja = lojasPermitidas[index];
                              return RadioListTile<String>(
                                title: Text(loja.nome),
                                value: loja.id,
                                groupValue: tempSelected,
                                onChanged: (v) => setState(() {
                                  tempSelected = v;
                                }),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              if (tempSelected == null) return;
                              Navigator.of(context).pop(tempSelected);
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
              if (selectedId != null && selectedId.isNotEmpty) {
                await ref
                    .read(lojaAtivaProvider.notifier)
                    .setActiveStore(selectedId);
              }
            },
            loading: () {},
            error: (_, __) {},
          );
        },
        loading: () {},
        error: (_, __) {},
      );
    });
    final kpis = ref.watch(dashboardKpiProvider);

    return MainLayout(
      title: 'Dashboard',
      breadcrumbs: const [
        BreadcrumbItem('Dashboard'),
      ],
      currentRoute: '/dashboard',
      onSidebarItemSelected: (route) => context.go(route),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notificações',
        ),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const UserInfoDialog(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.blueAccent,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            kpis.when(
              loading: () => const AppLoading(),
              error: (e, _) => Center(child: Text('Erro ao carregar KPIs')),
              data: (data) => LayoutBuilder(
                builder: (context, constraints) {
                  // Sempre 2 cards por linha, responsivo a partir de 320px
                  final double gridSpacing = 16;

                  final int crossAxisCount = 2;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: 0,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _DashboardCard(
                            title: 'Produtos',
                            value: data['Produtos'] ?? '-',
                            icon: Icons.inventory_2,
                            color: AppColors.blueDark,
                          ),
                          _DashboardCard(
                            title: 'Vendas',
                            value: data['Vendas'] ?? '-',
                            icon: Icons.attach_money,
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double iconSize = width < 320
        ? 16
        : width < 400
        ? 20
        : width < 700
        ? 28
        : 32;

    final double valueFontSize = width < 320
        ? 14
        : width < 400
        ? 18
        : width < 700
        ? 22
        : 26;

    final double titleFontSize = width < 320
        ? 10
        : width < 400
        ? 12
        : width < 700
        ? 14
        : 16;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontSize: valueFontSize,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: titleFontSize),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
