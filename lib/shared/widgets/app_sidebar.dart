import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../features/usuario/controllers/usuario_controller.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/controllers/user_info_controller.dart';
import '../../features/lojas/providers/loja_ativa_provider.dart';
import '../../features/lojas/controllers/loja_controller.dart';

class SidebarItemWithRoute {
  final IconData icon;
  final String label;
  final String route;
  final String? category;
  const SidebarItemWithRoute({
    required this.icon,
    required this.label,
    required this.route,
    this.category,
  });
}

const sidebarItemsWithRoutes = [
  // Dashboard
  SidebarItemWithRoute(
    icon: Icons.dashboard,
    label: 'Dashboard',
    route: '/dashboard',
    category: 'principal',
  ),
  
  // Gestão de Produtos
  SidebarItemWithRoute(
    icon: Icons.category,
    label: 'Categorias',
    route: '/categorias',
    category: 'produtos',
  ),
  SidebarItemWithRoute(
    icon: Icons.inventory,
    label: 'Produtos',
    route: '/produtos',
    category: 'produtos',
  ),
  SidebarItemWithRoute(
    icon: Icons.warehouse,
    label: 'Estoque',
    route: '/estoque',
    category: 'produtos',
  ),
  
  // Movimentações de Estoque
  SidebarItemWithRoute(
    icon: Icons.history,
    label: 'Histórico',
    route: '/movimentacoes',
    category: 'movimentacoes',
  ),
  SidebarItemWithRoute(
    icon: Icons.add_circle,
    label: 'Entradas',
    route: '/entradas-estoque',
    category: 'movimentacoes',
  ),
  SidebarItemWithRoute(
    icon: Icons.remove_circle,
    label: 'Saídas',
    route: '/saidas-estoque',
    category: 'movimentacoes',
  ),
  SidebarItemWithRoute(
    icon: Icons.swap_horiz,
    label: 'Trocas',
    route: '/trocas-estoque',
    category: 'movimentacoes',
  ),
  SidebarItemWithRoute(
    icon: Icons.swap_vert,
    label: 'Transferências',
    route: '/transferencias-estoque',
    category: 'movimentacoes',
  ),
  
  // Vendas e Financeiro
  SidebarItemWithRoute(
    icon: Icons.shopping_cart,
    label: 'Vendas',
    route: '/vendas',
    category: 'vendas',
  ),
  SidebarItemWithRoute(
    icon: Icons.account_balance_wallet,
    label: 'Caixa',
    route: '/caixa',
    category: 'vendas',
  ),
  SidebarItemWithRoute(
    icon: Icons.payment,
    label: 'Formas de Pagamento',
    route: '/formas-pagamento',
    category: 'vendas',
  ),
  
  // Cadastros
  SidebarItemWithRoute(
    icon: Icons.store,
    label: 'Lojas',
    route: '/lojas',
    category: 'cadastros',
  ),
  SidebarItemWithRoute(
    icon: Icons.people,
    label: 'Fornecedores',
    route: '/fornecedores',
    category: 'cadastros',
  ),
  SidebarItemWithRoute(
    icon: Icons.person_outline,
    label: 'Clientes',
    route: '/clientes',
    category: 'cadastros',
  ),
  
  // Administração
  SidebarItemWithRoute(
    icon: Icons.badge,
    label: 'Cargos',
    route: '/cargos',
    category: 'admin',
  ),
  SidebarItemWithRoute(
    icon: Icons.person,
    label: 'Usuários',
    route: '/usuarios',
    category: 'admin',
  ),
  SidebarItemWithRoute(
    icon: Icons.settings,
    label: 'Configurações',
    route: '/configuracoes',
    category: 'admin',
  ),
];

class AppSidebar extends ConsumerWidget {
  final String currentRoute;
  final void Function(String)? onItemSelected;
  final bool isCollapsed;

  const AppSidebar({
    Key? key,
    required this.currentRoute,
    this.onItemSelected,
    this.isCollapsed = false,
  }) : super(key: key);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair do sistema?'),
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
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'principal':
        return 'PRINCIPAL';
      case 'produtos':
        return 'PRODUTOS';
      case 'movimentacoes':
        return 'MOVIMENTAÇÕES';
      case 'vendas':
        return 'VENDAS & FINANCEIRO';
      case 'cadastros':
        return 'CADASTROS';
      case 'admin':
        return 'ADMINISTRAÇÃO';
      default:
        return category.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        return Builder(
          builder: (context) {
            return Consumer(
              builder: (context, ref, _) {
                final permissoesAsync = ref.watch(
                  permissoesUsuarioProvider(cargoId),
                );
                return permissoesAsync.when(
                  loading: () => Container(),
                  error: (e, _) => Container(),
                  data: (permissoes) {
                    // Mapeamento de rota para recurso
                    final rotaRecurso = {
                      '/dashboard': null, // dashboard sempre visível
                      '/lojas': 'lojas',
                      '/categorias': 'categorias',
                      '/produtos': 'produtos',
                      '/estoque': 'estoque',
                      '/movimentacoes': 'estoque',
                      '/entradas-estoque': 'estoque',
                      '/saidas-estoque': 'estoque',
                      '/trocas-estoque': 'estoque',
                      '/transferencias-estoque': 'estoque',
                      '/fornecedores': 'fornecedores',
                      '/clientes': 'clientes',
                      '/vendas': 'vendas',
                      '/caixa': 'caixa',
                      '/formas-pagamento': 'formas_pagamento',
                      '/cargos': 'cargos',
                      '/usuarios': 'usuarios',
                      '/configuracoes': null, // configurações sempre visível
                    };
                    
                    // Filtra itens por permissão
                    final visibleItems = <SidebarItemWithRoute>[];
                    for (final item in sidebarItemsWithRoutes) {
                      final recurso = rotaRecurso[item.route];
                      if (recurso == null ||
                          permissoes.any(
                            (p) =>
                                p['recurso'] == recurso &&
                                p['acao'] == 'listar',
                          )) {
                        visibleItems.add(item);
                      }
                    }
                    
                    // Agrupa itens por categoria
                    final groupedItems = <String, List<SidebarItemWithRoute>>{};
                    for (final item in visibleItems) {
                      final category = item.category ?? 'outros';
                      groupedItems.putIfAbsent(category, () => []).add(item);
                    }
                    
                    return Container(
                      width: isCollapsed ? 60 : 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                DrawerHeader(
                                  decoration: const BoxDecoration(
                                    color: AppColors.blue,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ERP Multi-Lojas',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Seletor de loja aqui
                                      Consumer(
                                        builder: (context, ref, _) {
                                          final userInfoAsync = ref.watch(
                                            userInfoProvider,
                                          );
                                          final lojasCatalogoAsync = ref.watch(
                                            lojaProvider,
                                          );
                                          final activeStoreId = ref.watch(
                                            lojaAtivaProvider,
                                          );
                                          return userInfoAsync.when(
                                            loading: () =>
                                                const SizedBox.shrink(),
                                            error: (_, __) =>
                                                const SizedBox.shrink(),
                                            data: (userInfo) {
                                              final lojasUser = userInfo
                                                  .lojas; // [{loja_id: ...}]
                                              if (lojasUser.isEmpty) {
                                                return const Text(
                                                  'Sem lojas associadas',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                );
                                              }
                                              return lojasCatalogoAsync.when(
                                                loading: () =>
                                                    const SizedBox.shrink(),
                                                error: (_, __) =>
                                                    const SizedBox.shrink(),
                                                data: (lojasCatalogo) {
                                                  final idsPermitidos =
                                                      lojasUser
                                                          .map(
                                                            (e) =>
                                                                e['loja_id']
                                                                    as String,
                                                          )
                                                          .toSet();
                                                  final lojasPermitidas =
                                                      lojasCatalogo
                                                          .where(
                                                            (l) => idsPermitidos
                                                                .contains(l.id),
                                                          )
                                                          .toList();
                                                  if ((activeStoreId == null ||
                                                          activeStoreId
                                                              .isEmpty) &&
                                                      lojasPermitidas.length ==
                                                          1) {
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback((
                                                          _,
                                                        ) {
                                                          ref
                                                              .read(
                                                                lojaAtivaProvider
                                                                    .notifier,
                                                              )
                                                              .setActiveStore(
                                                                lojasPermitidas
                                                                    .first
                                                                    .id,
                                                              );
                                                        });
                                                  }
                                                  return DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      dropdownColor:
                                                          AppColors.blue,
                                                      iconEnabledColor:
                                                          Colors.white,
                                                      value:
                                                          activeStoreId !=
                                                                  null &&
                                                              idsPermitidos
                                                                  .contains(
                                                                    activeStoreId,
                                                                  )
                                                          ? activeStoreId
                                                          : null,
                                                      hint: const Text(
                                                        'Selecione a loja',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      items: lojasPermitidas
                                                          .map(
                                                            (l) =>
                                                                DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: l.id,
                                                                  child: Text(
                                                                    l.nome,
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                          )
                                                          .toList(),
                                                      onChanged: (value) {
                                                        ref
                                                            .read(
                                                              lojaAtivaProvider
                                                                  .notifier,
                                                            )
                                                            .setActiveStore(
                                                              value,
                                                            );
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Menu',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Itens agrupados por categoria
                                ...groupedItems.entries.map((entry) {
                                  final category = entry.key;
                                  final items = entry.value;
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Cabeçalho da categoria
                                      if (!isCollapsed)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                          child: Text(
                                            _getCategoryLabel(category),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      
                                      // Itens da categoria
                                      ...items.map((item) {
                                        final isSelected = currentRoute == item.route;
                                        return ListTile(
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          leading: Icon(
                                            item.icon,
                                            size: 20,
                                            color: isSelected
                                                ? AppColors.blue
                                                : AppColors.blueAccent,
                                          ),
                                          title: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected 
                                                  ? FontWeight.w600 
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedTileColor: AppColors.blueLight,
                                          onTap: () {
                                            context.go(item.route);
                                            if (onItemSelected != null) {
                                              onItemSelected!(item.route);
                                            }
                                          },
                                        );
                                      }).toList(),
                                      
                                      // Separador entre categorias
                                      if (category != groupedItems.keys.last)
                                        Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Colors.grey[200],
                                          indent: 16,
                                          endIndent: 16,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          // Botão de Logout no final da sidebar
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 20,
                              ),
                              title: const Text(
                                'Sair',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _logout(context, ref),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
