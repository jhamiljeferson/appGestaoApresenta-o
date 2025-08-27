import '../models/item_venda_model.dart';
import '../../../core/services/supabase_service.dart';

class ItemVendaService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<ItemVendaModel>> getItensVenda(String vendaId) async {
    try {
      final response = await _supabaseService.client
          .from('itens_venda')
          .select()
          .eq('venda_id', vendaId)
          .order('criado_em');

      return (response as List)
          .map((item) => ItemVendaModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar itens da venda: $e');
    }
  }

  Future<ItemVendaModel> addItemVenda(ItemVendaModel item) async {
    try {
      final response = await _supabaseService.client
          .from('itens_venda')
          .insert(item.toMap())
          .select()
          .single();

      return ItemVendaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao adicionar item da venda: $e');
    }
  }

  Future<ItemVendaModel> updateItemVenda(ItemVendaModel item) async {
    try {
      final response = await _supabaseService.client
          .from('itens_venda')
          .update(item.toMap())
          .eq('id', item.id)
          .select()
          .single();

      return ItemVendaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao atualizar item da venda: $e');
    }
  }

  Future<void> deleteItemVenda(String id) async {
    try {
      await _supabaseService.client.from('itens_venda').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar item da venda: $e');
    }
  }

  Future<void> deleteItensVenda(String vendaId) async {
    try {
      await _supabaseService.client
          .from('itens_venda')
          .delete()
          .eq('venda_id', vendaId);
    } catch (e) {
      throw Exception('Erro ao deletar itens da venda: $e');
    }
  }

  Future<List<ItemVendaModel>> addItensVenda(List<ItemVendaModel> itens) async {
    try {
      final itensMap = itens.map((item) => item.toMap()).toList();
      final response = await _supabaseService.client
          .from('itens_venda')
          .insert(itensMap)
          .select();

      return (response as List)
          .map((item) => ItemVendaModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Erro ao adicionar itens da venda: $e');
    }
  }
}

