import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';
import '../../../core/services/supabase_service.dart';

class UsuarioService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'usuarios';

  Future<List<UsuarioModel>> getUsuarios() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .then((value) => value as List);
      return data.map((e) => UsuarioModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<void> addUsuario(UsuarioModel usuario) async {
    try {
      await _client.from(_table).insert(usuario.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar usuário: $e');
    }
  }

  Future<void> updateUsuario(UsuarioModel usuario) async {
    try {
      await _client.from(_table).update(usuario.toMap()).eq('id', usuario.id);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  Future<void> deleteUsuario(String id) async {
    try {
      // Primeiro, remove todas as relações usuário-lojas
      await _client.from('usuario_lojas').delete().eq('usuario_id', id);

      // Depois, remove o usuário da tabela de autenticação (se necessário)
      // Nota: A exclusão do usuário do Supabase Auth deve ser feita separadamente

      // Por fim, remove o usuário da tabela local
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar usuário: $e');
    }
  }

  // Métodos para gerenciar relações usuário-lojas
  Future<List<Map<String, dynamic>>> getLojasDoUsuario(String usuarioId) async {
    try {
      final data = await _client
          .from('usuario_lojas')
          .select('loja_id')
          .eq('usuario_id', usuarioId)
          .then((value) => value as List);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      // Se o usuário não existir, retorna lista vazia em vez de erro
      if (e.toString().contains('not found') ||
          e.toString().contains('does not exist')) {
        return [];
      }
      throw Exception('Erro ao buscar lojas do usuário: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLojasDisponiveis() async {
    try {
      final data = await _client
          .from('lojas')
          .select('id, nome, shopping, andar, numero')
          .then((value) => value as List);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erro ao buscar lojas disponíveis: $e');
    }
  }

  Future<void> salvarLojasDoUsuario(
    String usuarioId,
    List<String> lojasIds,
  ) async {
    try {
      // Remove todas as relações existentes
      await _client.from('usuario_lojas').delete().eq('usuario_id', usuarioId);

      // Adiciona as novas relações em lote
      if (lojasIds.isNotEmpty) {
        final batch = lojasIds
            .map((lojaId) => {'usuario_id': usuarioId, 'loja_id': lojaId})
            .toList();
        await _client.from('usuario_lojas').insert(batch);
      }
    } catch (e) {
      throw Exception('Erro ao salvar lojas do usuário: $e');
    }
  }
}
