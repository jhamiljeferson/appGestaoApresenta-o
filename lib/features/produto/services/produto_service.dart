import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produto_model.dart';
import '../../../core/services/supabase_service.dart';

class ProdutoService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'produtos';

  Future<List<ProdutoModel>> getProdutos() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .then((value) => value as List);
      return data.map((e) => ProdutoModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }

  Future<void> addProduto(ProdutoModel produto) async {
    try {
      await _client.from(_table).insert(produto.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar produto: $e');
    }
  }

  Future<void> updateProduto(ProdutoModel produto) async {
    try {
      await _client.from(_table).update(produto.toMap()).eq('id', produto.id);
    } catch (e) {
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  Future<void> deleteProduto(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar produto: $e');
    }
  }
}
