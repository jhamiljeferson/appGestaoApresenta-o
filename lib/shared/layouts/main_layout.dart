import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_breadcrumbs.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<BreadcrumbItem> breadcrumbs;
  final List<Widget>? actions;
  final String currentRoute;
  final void Function(String)? onSidebarItemSelected;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.breadcrumbs,
    this.actions,
    required this.currentRoute,
    this.onSidebarItemSelected,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                currentRoute: widget.currentRoute,
                onItemSelected: (route) {
                  Navigator.of(context).pop();
                  if (widget.onSidebarItemSelected != null)
                    widget.onSidebarItemSelected!(route);
                },
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentRoute: widget.currentRoute,
              onItemSelected: widget.onSidebarItemSelected,
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: widget.title,
                  breadcrumbs: widget.breadcrumbs,
                  actions: widget.actions,
                  currentRoute: widget.currentRoute,
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F8FA),
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
