import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_model.dart';
import '../../../core/services/supabase_service.dart';

class CategoriaService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'categorias';

  Future<List<CategoriaModel>> getCategorias() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .order('nome')
          .then((value) => value as List);
      return data.map((e) => CategoriaModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar categorias: $e');
    }
  }

  Future<bool> hasCategorias() async {
    try {
      final data = await _client
          .from(_table)
          .select('id')
          .limit(1)
          .then((value) => value as List);
      return data.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar categorias: $e');
    }
  }

  Future<int> getCategoriasCount() async {
    try {
      final data = await _client
          .from(_table)
          .select('id', const FetchOptions(count: CountOption.exact))
          .then((value) => value as List);
      return data.length;
    } catch (e) {
      throw Exception('Erro ao contar categorias: $e');
    }
  }

  Future<void> addCategoria(CategoriaModel categoria) async {
    try {
      await _client.from(_table).insert(categoria.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar categoria: $e');
    }
  }

  Future<void> updateCategoria(CategoriaModel categoria) async {
    try {
      await _client
          .from(_table)
          .update(categoria.toMap())
          .eq('id', categoria.id);
    } catch (e) {
      throw Exception('Erro ao atualizar categoria: $e');
    }
  }

  Future<void> deleteCategoria(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar categoria: $e');
    }
  }
}
