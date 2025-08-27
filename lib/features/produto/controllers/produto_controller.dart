import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/produto_model.dart';
import '../services/produto_service.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../../core/services/user_audit_service.dart';

final produtoProvider =
    StateNotifierProvider<ProdutoController, AsyncValue<List<ProdutoModel>>>(
      (ref) => ProdutoController(ref),
    );

class ProdutoController extends StateNotifier<AsyncValue<List<ProdutoModel>>> {
  final ProdutoService _service = ProdutoService();
  final Ref _ref;

  ProdutoController(this._ref) : super(const AsyncValue.loading()) {
    loadProdutos();
  }

  Future<void> loadProdutos() async {
    try {
      state = const AsyncValue.loading();
      final produtos = await _service.getProdutos();
      state = AsyncValue.data(produtos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduto(ProdutoModel produto) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }

    // Obtém o ID do usuário logado
    final userId = await UserAuditService().getUsuarioId();
    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Verifique se você está logado corretamente.',
      );
    }

    // Cria uma cópia do produto com o usuário que criou
    final produtoComUsuario = produto.copyWith(
      criadoPor: userId,
      criadoEm: DateTime.now(),
    );

    await _service.addProduto(produtoComUsuario);
    await loadProdutos();
  }

  Future<void> updateProduto(ProdutoModel produto) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }

    // Obtém o ID do usuário logado
    final userId = await UserAuditService().getUsuarioId();
    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Verifique se você está logado corretamente.',
      );
    }

    // Cria uma cópia do produto com o usuário que atualizou
    final produtoComUsuario = produto.copyWith(
      atualizadoPor: userId,
      atualizadoEm: DateTime.now(),
    );

    await _service.updateProduto(produtoComUsuario);
    await loadProdutos();
  }

  Future<void> deleteProduto(String id) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }
    await _service.deleteProduto(id);
    await loadProdutos();
  }
}
