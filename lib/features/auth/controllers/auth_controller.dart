import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import 'user_info_controller.dart';
import '../../lojas/providers/loja_ativa_provider.dart';

final authProvider = StateNotifierProvider<AuthController, bool>((ref) {
  final controller = AuthController(ref);
  return controller;
});

class AuthController extends StateNotifier<bool> {
  final Ref _ref;
  final AuthService _authService = AuthService();

  AuthController(this._ref) : super(AuthService().currentSession != null) {
    // Escuta mudanças de autenticação do Supabase
    _authService.authStateChanges.listen((authState) {
      final isLoggedIn = authState.session != null;
      print('[AuthController] Auth state changed - isLoggedIn: $isLoggedIn');
      
      if (state != isLoggedIn) {
        state = isLoggedIn;
        
        if (isLoggedIn) {
          print('[AuthController] Usuário logado, carregando informações');
          _ref.read(userInfoProvider.notifier).loadUserInfo();
        } else {
          print('[AuthController] Usuário deslogado, limpando informações');
          _ref.read(userInfoProvider.notifier).clear();
          _ref.read(lojaAtivaProvider.notifier).clear();
        }
      }
    });
  }

  static bool isLoggedIn() => AuthService().currentSession != null;

  static Future<String?> getCargoIdUsuarioLogado() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    final client = SupabaseService().client;
    final data = await client
        .from('usuarios')
        .select('cargo_id')
        .eq('user_id', user.id)
        .maybeSingle();
    return data != null ? data['cargo_id'] as String? : null;
  }

  static Future<String?> getUsuarioIdLogado() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    final client = SupabaseService().client;
    final data = await client
        .from('usuarios')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    return data != null ? data['id'] as String? : null;
  }

  Future<void> login(String email, String password) async {
    print('[AuthController] Iniciando login');
    final response = await _authService.signIn(email, password);
    // O estado será atualizado automaticamente pelo listener
    print('[AuthController] Login processado, estado será atualizado pelo listener');
  }

  Future<void> logout() async {
    print('[AuthController] Iniciando logout');
    await _authService.signOut();
    // O estado será atualizado automaticamente pelo listener
    print('[AuthController] Logout processado, estado será atualizado pelo listener');
  }
}
