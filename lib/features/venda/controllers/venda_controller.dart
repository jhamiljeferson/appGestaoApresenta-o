import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';
import '../models/pagamento_venda_model.dart';
import '../services/venda_service.dart';
import '../services/item_venda_service.dart';
import '../services/pagamento_venda_service.dart';
import '../../../core/utils/formatters.dart';

final vendaProvider =
    StateNotifierProvider<VendaController, AsyncValue<List<VendaModel>>>(
      (ref) => VendaController(
        ref.read(vendaServiceProvider),
        ref.read(itemVendaServiceProvider),
        ref.read(pagamentoVendaServiceProvider),
      ),
    );

final vendaServiceProvider = Provider((ref) => VendaService());
final itemVendaServiceProvider = Provider((ref) => ItemVendaService());
final pagamentoVendaServiceProvider = Provider(
  (ref) => PagamentoVendaService(),
);

class VendaController extends StateNotifier<AsyncValue<List<VendaModel>>> {
  final VendaService _vendaService;
  final ItemVendaService _itemVendaService;
  final PagamentoVendaService _pagamentoVendaService;

  VendaController(
    this._vendaService,
    this._itemVendaService,
    this._pagamentoVendaService,
  ) : super(const AsyncValue.loading()) {
    // Carregar vendas automaticamente quando o controller for criado
    loadVendas();
  }

  Future<void> loadVendas() async {
    state = const AsyncValue.loading();
    try {
      final vendas = await _vendaService.getVendas();
      state = AsyncValue.data(vendas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadVendasPorLoja(String lojaId) async {
    state = const AsyncValue.loading();
    try {
      final vendas = await _vendaService.getVendasPorLoja(lojaId);
      state = AsyncValue.data(vendas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addVenda(
    String lojaId,
    String? clienteId,
    String usuarioId,
    List<ItemVendaModel> itens,
    List<PagamentoVendaModel> pagamentos,
    double descontoTotal,
  ) async {
    try {
      print(
        '🔧 [VendaController] Iniciando criação de venda para loja: $lojaId',
      );

      // Calcular valor total dos itens
      final valorTotal = itens.fold<double>(
        0.0,
        (sum, item) => sum + item.valorTotal,
      );

      print(
        '🔧 [VendaController] Valor total da venda: ${formatCurrency(valorTotal)}',
      );

      // Criar venda
      final venda = VendaModel.novo(
        lojaId: lojaId,
        clienteId: clienteId,
        usuarioId: usuarioId,
        valorTotal: valorTotal,
        descontoTotal: descontoTotal,
      );

      print(
        '🔧 [VendaController] Venda criada localmente, enviando para o serviço...',
      );

      final vendaCriada = await _vendaService.addVenda(venda);

      print('✅ [VendaController] Venda criada com sucesso: ${vendaCriada.id}');

      // Adicionar itens da venda
      print('🔧 [VendaController] Adicionando itens da venda...');
      for (final item in itens) {
        final itemVenda = item.copyWith(vendaId: vendaCriada.id);
        await _itemVendaService.addItemVenda(itemVenda);
      }

      // Adicionar pagamentos da venda
      print('🔧 [VendaController] Adicionando pagamentos da venda...');
      for (final pagamento in pagamentos) {
        final pagamentoVenda = pagamento.copyWith(vendaId: vendaCriada.id);
        await _pagamentoVendaService.addPagamentoVenda(pagamentoVenda);
      }

      print('✅ [VendaController] Venda completamente finalizada');

      // Recarregar lista
      await loadVendasPorLoja(lojaId);
    } catch (e, stack) {
      print('❌ [VendaController] Erro ao criar venda: $e');
      print('❌ [VendaController] Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteVenda(String vendaId) async {
    try {
      await _pagamentoVendaService.deletePagamentosVenda(vendaId);
      await _itemVendaService.deleteItensVenda(vendaId);
      await _vendaService.deleteVenda(vendaId);

      // Recarregar lista
      final currentState = state.value ?? [];
      final updatedVendas = currentState.where((v) => v.id != vendaId).toList();
      state = AsyncValue.data(updatedVendas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
