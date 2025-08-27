import '../../../core/services/supabase_service.dart';
import '../../venda/models/venda_model.dart';
import '../../venda/models/pagamento_venda_model.dart';
import '../../venda/services/pagamento_venda_service.dart';
import '../models/caixa_movimentacao_model.dart';

class CaixaVendasService {
  final SupabaseService _supabaseService = SupabaseService();
  final PagamentoVendaService _pagamentoVendaService = PagamentoVendaService();

  /// Busca todas as vendas realizadas em um caixa específico
  Future<List<VendaModel>> getVendasPorCaixa(String caixaId) async {
    try {
      // Buscar movimentações de venda do caixa
      final response = await _supabaseService.client
          .from('caixa_movimentacao')
          .select('venda_id')
          .eq('caixa_id', caixaId)
          .eq('tipo', TipoMovimentacaoCaixa.venda.name)
          .not('venda_id', 'is', null);

      if (response == null || response.isEmpty) {
        return [];
      }

      // Extrair IDs das vendas
      final vendaIds = (response as List<dynamic>)
          .map((mov) => mov['venda_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .map((id) => id!)
          .toSet()
          .toList();

      if (vendaIds.isEmpty) {
        return [];
      }

      // Buscar detalhes das vendas
      final vendasResponse = await _supabaseService.client
          .from('vendas')
          .select()
          .in_('id', vendaIds)
          .order('criado_em', ascending: false);

      return (vendasResponse as List<dynamic>)
          .map((venda) => VendaModel.fromMap(venda as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas do caixa: $e');
    }
  }

  /// Busca os pagamentos de todas as vendas de um caixa
  Future<Map<String, List<PagamentoVendaModel>>> getPagamentosVendasPorCaixa(
    String caixaId,
  ) async {
    try {
      // Buscar vendas do caixa
      final vendas = await getVendasPorCaixa(caixaId);
      
      if (vendas.isEmpty) {
        return {};
      }

      // Buscar pagamentos de cada venda
      final Map<String, List<PagamentoVendaModel>> pagamentosPorVenda = {};
      
      for (final venda in vendas) {
        try {
          final pagamentos = await _pagamentoVendaService.getPagamentosVenda(venda.id);
          if (pagamentos.isNotEmpty) {
            pagamentosPorVenda[venda.id] = pagamentos;
          }
        } catch (e) {
          // Ignorar erro individual, continuar com outras vendas
        }
      }

      return pagamentosPorVenda;
    } catch (e) {
      throw Exception('Erro ao buscar pagamentos das vendas do caixa: $e');
    }
  }

  /// Busca resumo dos pagamentos por forma de pagamento para um caixa
  Future<Map<String, double>> getResumoPagamentosPorForma(String caixaId) async {
    try {
      final pagamentosPorVenda = await getPagamentosVendasPorCaixa(caixaId);
      
      final Map<String, double> resumoPorForma = {};
      
      for (final pagamentos in pagamentosPorVenda.values) {
        for (final pagamento in pagamentos) {
          final formaPagamentoId = pagamento.formaPagamentoId;
          resumoPorForma[formaPagamentoId] = 
              (resumoPorForma[formaPagamentoId] ?? 0) + pagamento.valorPago;
        }
      }
      
      return resumoPorForma;
    } catch (e) {
      throw Exception('Erro ao buscar resumo dos pagamentos por forma: $e');
    }
  }

}
