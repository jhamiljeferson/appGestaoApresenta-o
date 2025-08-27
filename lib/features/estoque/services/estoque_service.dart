import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estoque_model.dart';
import '../../../core/services/supabase_service.dart';

class EstoqueService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'estoque';

  Future<List<EstoqueModel>> getEstoques() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .then((value) => value as List);
      return data.map((e) => EstoqueModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar estoque: $e');
    }
  }

  Future<void> addEstoque(EstoqueModel estoque) async {
    try {
      await _client.from(_table).insert(estoque.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar estoque: $e');
    }
  }

  Future<void> updateEstoque(EstoqueModel estoque) async {
    try {
      await _client.from(_table).update(estoque.toMap()).eq('id', estoque.id);
    } catch (e) {
      throw Exception('Erro ao atualizar estoque: $e');
    }
  }

  Future<void> deleteEstoque(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar estoque: $e');
    }
  }
}
