import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'features/auth/controllers/auth_controller.dart';

class AppEntrypoint extends ConsumerWidget {
  const AppEntrypoint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta mudanças no estado de autenticação e no router
    ref.watch(authProvider);
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ERP Multi-Lojas',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
