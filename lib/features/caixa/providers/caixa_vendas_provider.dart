import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/caixa_vendas_service.dart';
import '../../venda/models/venda_model.dart';
import '../../venda/models/pagamento_venda_model.dart';

final caixaVendasServiceProvider = Provider<CaixaVendasService>((ref) {
  return CaixaVendasService();
});

final vendasPorCaixaProvider = FutureProvider.family<List<VendaModel>, String>(
  (ref, caixaId) async {
    final service = ref.read(caixaVendasServiceProvider);
    return await service.getVendasPorCaixa(caixaId);
  },
);

final pagamentosVendasPorCaixaProvider = FutureProvider.family<Map<String, List<PagamentoVendaModel>>, String>(
  (ref, caixaId) async {
    final service = ref.read(caixaVendasServiceProvider);
    return await service.getPagamentosVendasPorCaixa(caixaId);
  },
);

final resumoPagamentosPorFormaProvider = FutureProvider.family<Map<String, double>, String>(
  (ref, caixaId) async {
    final service = ref.read(caixaVendasServiceProvider);
    return await service.getResumoPagamentosPorForma(caixaId);
  },
);
