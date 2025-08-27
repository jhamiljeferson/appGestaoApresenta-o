import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/caixa_model.dart';
import '../models/caixa_movimentacao_model.dart';
import '../services/caixa_service.dart';
import '../services/caixa_calculo_service.dart';


final caixaProvider =
    StateNotifierProvider<CaixaController, AsyncValue<List<CaixaModel>>>(
      (ref) => CaixaController(ref.read(caixaServiceProvider)),
    );

final caixaServiceProvider = Provider((ref) => CaixaService());
final caixaCalculoServiceProvider = Provider((ref) => CaixaCalculoService());


final caixaAtivoProvider = StateProvider<CaixaModel?>((ref) => null);

final movimentacoesCaixaProvider =
    FutureProvider.family<List<CaixaMovimentacaoModel>, String>((
      ref,
      caixaId,
    ) async {
      final service = ref.read(caixaServiceProvider);
      return service.getMovimentacoesPorCaixa(caixaId);
    });

final saldoAtualProvider = FutureProvider.family<double, String>((
  ref,
  caixaId,
) async {
  final service = ref.read(caixaServiceProvider);
  return service.calcularSaldoAtual(caixaId);
});

final resumoCaixaProvider = FutureProvider.family<Map<String, double>, String>((
  ref,
  caixaId,
) async {
  final service = ref.read(caixaServiceProvider);
  return service.calcularResumoCaixa(caixaId);
});

final resumoFechamentoProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  caixaId,
) async {
  final service = ref.read(caixaServiceProvider);
  return service.calcularResumoFechamento(caixaId);
});

class CaixaController extends StateNotifier<AsyncValue<List<CaixaModel>>> {
  final CaixaService _caixaService;

  CaixaController(this._caixaService) : super(const AsyncValue.loading()) {
    loadCaixas();
  }

  Future<void> loadCaixas() async {
    state = const AsyncValue.loading();
    try {
      final caixas = await _caixaService.getCaixas();
      state = AsyncValue.data(caixas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadCaixasPorLoja(String lojaId) async {
    state = const AsyncValue.loading();
    try {
      final caixas = await _caixaService.getCaixasPorLoja(lojaId);
      state = AsyncValue.data(caixas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<CaixaModel?> getCaixaAbertoPorLoja(String lojaId) async {
    try {
      return await _caixaService.getCaixaAbertoPorLoja(lojaId);
    } catch (e) {
      rethrow;
    }
  }

  Future<CaixaModel> abrirCaixa(
    String lojaId,
    String usuarioId,
    double saldoInicial,
  ) async {
    try {
      print(
        '🔧 [CaixaController] Abrindo caixa para loja: $lojaId, usuário: $usuarioId',
      );

      // Validar parâmetros
      if (lojaId.isEmpty) {
        throw Exception('ID da loja é obrigatório');
      }
      if (usuarioId.isEmpty) {
        throw Exception('ID do usuário é obrigatório');
      }
      if (saldoInicial < 0) {
        throw Exception('Saldo inicial não pode ser negativo');
      }

      final caixa = CaixaModel.novo(
        lojaId: lojaId,
        usuarioAberturaId: usuarioId,
        saldoInicial: saldoInicial,
        criadoPor: usuarioId,
      );

      print('🔧 [CaixaController] Caixa criado localmente: ${caixa.toMap()}');

      final caixaCriado = await _caixaService.abrirCaixa(caixa);

      print('✅ [CaixaController] Caixa criado no banco: ${caixaCriado.id}');

      // Recarregar lista
      await loadCaixasPorLoja(lojaId);

      return caixaCriado;
    } catch (e, stack) {
      print('❌ [CaixaController] Erro ao abrir caixa: $e');
      print('❌ [CaixaController] Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Fecha um caixa e atualiza o estado
  Future<CaixaModel> fecharCaixa(
    String caixaId,
    String usuarioFechamentoId, {
    double? saldoFinalManual,
    String? observacoes,
  }) async {
    try {
      print(
        '🔧 [CaixaController] Fechando caixa: $caixaId, usuário: $usuarioFechamentoId',
      );

      // Validar parâmetros
      if (caixaId.isEmpty) {
        throw Exception('ID do caixa é obrigatório');
      }
      if (usuarioFechamentoId.isEmpty) {
        throw Exception('ID do usuário de fechamento é obrigatório');
      }

      // Fechar caixa
      final caixaFechado = await _caixaService.fecharCaixa(
        caixaId,
        usuarioFechamentoId,
        saldoFinalManual: saldoFinalManual,
        observacoes: observacoes,
      );

      print('✅ [CaixaController] Caixa fechado com sucesso: ${caixaFechado.id}');

      // Recarregar lista de caixas
      await loadCaixasPorLoja(caixaFechado.lojaId);

      return caixaFechado;
    } catch (e, stack) {
      print('❌ [CaixaController] Erro ao fechar caixa: $e');
      print('❌ [CaixaController] Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> registrarMovimentacao(
    String caixaId,
    TipoMovimentacaoCaixa tipo,
    double valor,
    String usuarioId, {
    String? descricao,
    String? vendaId,
  }) async {
    try {
      final movimentacao = CaixaMovimentacaoModel.novo(
        caixaId: caixaId,
        tipo: tipo,
        valor: valor,
        usuarioId: usuarioId,
        descricao: descricao,
        vendaId: vendaId,
        criadoPor: usuarioId,
      );

      await _caixaService.addMovimentacao(movimentacao);

      // Invalidar providers relacionados
      // Note: Em uma implementação mais robusta, você pode querer
      // atualizar o estado local também
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registrarVenda(
    String caixaId,
    String vendaId,
    double valor,
    String usuarioId,
  ) async {
    try {
      await _caixaService.registrarVenda(caixaId, vendaId, valor, usuarioId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registrarEntrada(
    String caixaId,
    double valor,
    String usuarioId,
    String? descricao,
  ) async {
    try {
      await _caixaService.registrarEntrada(
        caixaId,
        valor,
        usuarioId,
        descricao,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registrarSaida(
    String caixaId,
    double valor,
    String usuarioId,
    String? descricao,
  ) async {
    try {
      await _caixaService.registrarSaida(caixaId, valor, usuarioId, descricao);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCaixa(String caixaId) async {
    try {
      await _caixaService.deleteCaixa(caixaId);

      // Recarregar lista
      final currentState = state.value ?? [];
      final updatedCaixas = currentState.where((c) => c.id != caixaId).toList();
      state = AsyncValue.data(updatedCaixas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteMovimentacao(String movimentacaoId, String caixaId) async {
    try {
      await _caixaService.deleteMovimentacao(movimentacaoId);

      // Invalidar providers relacionados
      // Note: Em uma implementação mais robusta, você pode querer
      // atualizar o estado local também
    } catch (e) {
      rethrow;
    }
  }
}
