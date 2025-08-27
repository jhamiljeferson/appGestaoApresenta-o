import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_breadcrumbs.dart';

class AppHeader extends ConsumerWidget {
  final String title;
  final List<BreadcrumbItem> breadcrumbs;
  final List<Widget>? actions;
  final String currentRoute;

  const AppHeader({
    Key? key,
    required this.title,
    required this.breadcrumbs,
    this.actions,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isSmall = MediaQuery.of(context).size.width < 400;
    final width = MediaQuery.of(context).size.width;
    double buttonHeight = isSmall ? 32 : 40;
    double buttonMinWidth = isSmall ? width * 0.32 : 120;
    double iconSize = isSmall ? 16 : 24;
    double fontSize = isSmall ? 12 : 16;

    // Seletor de loja movido para o AppSidebar (menu lateral/drawer) para ficar
    // mais adequado ao uso em mobile. Aqui mantemos apenas o título e ações.

    List<Widget> responsiveActions = (actions ?? []).map((w) {
      if (w is ElevatedButton) {
        Widget child = w.child ?? const SizedBox.shrink();
        if (child is Row && child.children.length == 2) {
          // Caso ElevatedButton.icon
          Widget iconWidget = child.children[0];
          Widget labelWidget = child.children[1];
          return SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: w.onPressed,
              style:
                  w.style?.copyWith(
                    minimumSize: MaterialStateProperty.all(
                      Size(buttonMinWidth, buttonHeight),
                    ),
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: isSmall ? 8 : 20),
                    ),
                  ) ??
                  ElevatedButton.styleFrom(
                    minimumSize: Size(buttonMinWidth, buttonHeight),
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 20),
                  ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: IconThemeData(size: iconSize),
                    child: iconWidget,
                  ),
                  const SizedBox(width: 6),
                  DefaultTextStyle.merge(
                    style: TextStyle(fontSize: fontSize),
                    child: labelWidget,
                  ),
                ],
              ),
            ),
          );
        } else {
          // Botão simples: só texto
          return SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: w.onPressed,
              style:
                  w.style?.copyWith(
                    minimumSize: MaterialStateProperty.all(
                      Size(buttonMinWidth, buttonHeight),
                    ),
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: isSmall ? 8 : 20),
                    ),
                  ) ??
                  ElevatedButton.styleFrom(
                    minimumSize: Size(buttonMinWidth, buttonHeight),
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 20),
                  ),
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: fontSize),
                child: child,
              ),
            ),
          );
        }
      }
      return w;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isDesktop)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Menu',
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (responsiveActions.isNotEmpty) ...responsiveActions,
            ],
          ),
          const SizedBox(height: 4),
          AppBreadcrumbs(items: breadcrumbs),
        ],
      ),
    );
  }
}
