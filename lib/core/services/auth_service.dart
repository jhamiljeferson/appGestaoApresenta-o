import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeAuthListener();
  }

  final SupabaseClient _client = SupabaseService().client;
  bool _isInitialized = false;

  void _initializeAuthListener() {
    if (_isInitialized) return;
    _isInitialized = true;

    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      print('[AuthService] Auth state changed: $event');
    });
  }

  // Stream para mudanças de autenticação
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('[AuthService] Iniciando processo de autenticação');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('[AuthService] Autenticação realizada com sucesso');
      return response;
    } catch (e) {
      print('[AuthService] Erro ao fazer login: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      print('Usuário criado no Supabase Auth: ' + email);
      return response;
    } catch (e) {
      print('Erro ao criar usuário no Supabase Auth: ' + e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('Logout realizado');
    } catch (e) {
      print('Erro ao fazer logout: ' + e.toString());
      rethrow;
    }
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
}
