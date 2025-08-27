import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loja_model.dart';
import '../../../core/services/supabase_service.dart';

class LojaService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'lojas';

  Future<List<LojaModel>> getLojas() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .then((value) => value as List);
      return data.map((e) => LojaModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar lojas: $e');
    }
  }

  Future<void> addLoja(LojaModel loja) async {
    try {
      await _client.from(_table).insert(loja.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar loja: $e');
    }
  }

  Future<void> updateLoja(LojaModel loja) async {
    try {
      await _client.from(_table).update(loja.toMap()).eq('id', loja.id);
    } catch (e) {
      throw Exception('Erro ao atualizar loja: $e');
    }
  }

  Future<void> deleteLoja(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar loja: $e');
    }
  }
}
