import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movimentacao_estoque_model.dart';
import '../services/movimentacao_estoque_service.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../auth/controllers/user_info_controller.dart';

final movimentacaoEstoqueProvider =
    StateNotifierProvider<
      MovimentacaoEstoqueController,
      AsyncValue<List<MovimentacaoEstoqueModel>>
    >((ref) => MovimentacaoEstoqueController(ref));

class MovimentacaoEstoqueController
    extends StateNotifier<AsyncValue<List<MovimentacaoEstoqueModel>>> {
  final MovimentacaoEstoqueService _service = MovimentacaoEstoqueService();
  final Ref _ref;

  MovimentacaoEstoqueController(this._ref) : super(const AsyncValue.loading()) {
    // Não carrega automaticamente no construtor
  }

  Future<void> loadMovimentacoes() async {
    try {
      state = const AsyncValue.loading();
      final lojaId = _ref.read(lojaAtivaProvider);
      if (lojaId == null || lojaId.isEmpty) {
        // Aguarda um pouco e tenta novamente se não há loja ativa
        await Future.delayed(const Duration(milliseconds: 500));
        final lojaIdRetry = _ref.read(lojaAtivaProvider);
        if (lojaIdRetry == null || lojaIdRetry.isEmpty) {
          state = const AsyncValue.data([]);
          return;
        }
        final movimentacoes = await _service.getMovimentacoesPorLoja(
          lojaIdRetry,
        );
        state = AsyncValue.data(movimentacoes);
        return;
      }
      final movimentacoes = await _service.getMovimentacoesPorLoja(lojaId);
      state = AsyncValue.data(movimentacoes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMovimentacao(MovimentacaoEstoqueModel movimentacao) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }

    // Obtém o usuário logado
    final userInfoState = _ref.read(userInfoProvider);
    final usuarioId = userInfoState.maybeWhen(
      data: (state) => state.usuario?.id,
      orElse: () => null,
    );

    if (usuarioId == null) {
      throw Exception('Usuário não identificado.');
    }

    // Cria a movimentação com o usuário logado
    final movimentacaoComUsuario = MovimentacaoEstoqueModel(
      id: movimentacao.id,
      lojaId: movimentacao.lojaId,
      produtoId: movimentacao.produtoId,
      tipo: movimentacao.tipo,
      quantidade: movimentacao.quantidade,
      observacao: movimentacao.observacao,
      criadoEm: movimentacao.criadoEm,
      criadoPor: usuarioId,
    );

    // Adiciona a movimentação
    await _service.addMovimentacao(movimentacaoComUsuario);

    // Atualiza o estoque
    final estoqueAtual = await _service.getEstoqueAtual(
      movimentacao.produtoId,
      movimentacao.lojaId,
    );

    int novaQuantidade;
    switch (movimentacao.tipo) {
      case TipoMovimentacao.entrada:
      case TipoMovimentacao.trocaEntrada:
      case TipoMovimentacao.transferenciaEntrada:
        novaQuantidade = estoqueAtual + movimentacao.quantidade;
        break;
      case TipoMovimentacao.saida:
      case TipoMovimentacao.trocaSaida:
      case TipoMovimentacao.transferenciaSaida:
        novaQuantidade = estoqueAtual - movimentacao.quantidade;
        if (novaQuantidade < 0) {
          throw Exception(
            'Quantidade insuficiente em estoque para esta operação.',
          );
        }
        break;
    }

    await _service.atualizarEstoque(
      movimentacao.produtoId,
      movimentacao.lojaId,
      novaQuantidade,
      atualizadoPorUsuarioId: usuarioId,
    );

    await loadMovimentacoes();
  }

  Future<void> updateMovimentacao(MovimentacaoEstoqueModel movimentacao) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }
    await _service.updateMovimentacao(movimentacao);
    await loadMovimentacoes();
  }

  Future<void> deleteMovimentacao(String id) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }
    await _service.deleteMovimentacao(id);
    await loadMovimentacoes();
  }

  // Método para obter o estoque atual de um produto
  Future<int> getEstoqueAtual(String produtoId) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      return 0;
    }
    return await _service.getEstoqueAtual(produtoId, lojaId);
  }
}
