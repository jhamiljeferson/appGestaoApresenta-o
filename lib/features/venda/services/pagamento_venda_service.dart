import '../models/pagamento_venda_model.dart';
import '../../../core/services/supabase_service.dart';

class PagamentoVendaService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<PagamentoVendaModel>> getPagamentosVenda(String vendaId) async {
    try {
      final response = await _supabaseService.client
          .from('pagamentos_venda')
          .select()
          .eq('venda_id', vendaId)
          .order('criado_em', ascending: false);

      return (response as List)
          .map((data) => PagamentoVendaModel.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar pagamentos da venda: $e');
    }
  }

  Future<PagamentoVendaModel> addPagamentoVenda(
    PagamentoVendaModel pagamento,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('pagamentos_venda')
          .insert(pagamento.toMap())
          .select()
          .single();

      return PagamentoVendaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao adicionar pagamento: $e');
    }
  }

  Future<PagamentoVendaModel> updatePagamentoVenda(
    PagamentoVendaModel pagamento,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('pagamentos_venda')
          .update(pagamento.toMap())
          .eq('id', pagamento.id)
          .select()
          .single();

      return PagamentoVendaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao atualizar pagamento: $e');
    }
  }

  Future<void> deletePagamentoVenda(String id) async {
    try {
      await _supabaseService.client
          .from('pagamentos_venda')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar pagamento: $e');
    }
  }

  Future<void> deletePagamentosVenda(String vendaId) async {
    try {
      await _supabaseService.client
          .from('pagamentos_venda')
          .delete()
          .eq('venda_id', vendaId);
    } catch (e) {
      throw Exception('Erro ao deletar pagamentos da venda: $e');
    }
  }

  Future<List<PagamentoVendaModel>> addPagamentosVenda(
    List<PagamentoVendaModel> pagamentos,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('pagamentos_venda')
          .insert(pagamentos.map((p) => p.toMap()).toList())
          .select();

      return (response as List)
          .map((data) => PagamentoVendaModel.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao adicionar pagamentos: $e');
    }
  }
}
