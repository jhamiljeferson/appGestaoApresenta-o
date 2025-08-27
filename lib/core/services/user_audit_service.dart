import 'auth_service.dart';
import 'supabase_service.dart';

class UserAuditService {
  static final UserAuditService _instance = UserAuditService._internal();
  factory UserAuditService() => _instance;
  UserAuditService._internal();

  // Método para obter o ID do usuário da tabela usuarios
  Future<String?> getUsuarioId() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        print('❌ [AUDIT] Usuário não autenticado no Supabase Auth');
        return null;
      }

      print(
        '🔍 [AUDIT] Buscando usuário na tabela usuarios com user_id: ${user.id}',
      );

      final client = SupabaseService().client;
      final data = await client
          .from('usuarios')
          .select('id, nome, email')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        final usuarioId = data['id'] as String?;
        print('✅ [AUDIT] Usuário encontrado: ${data['nome']} (ID: $usuarioId)');
        return usuarioId;
      } else {
        print('❌ [AUDIT] Usuário não encontrado na tabela usuarios');
        return null;
      }
    } catch (e) {
      print('❌ [AUDIT] Erro ao obter ID do usuário: $e');
      return null;
    }
  }
}

