import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estoque_model.dart';
import '../services/estoque_service.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../../core/services/user_audit_service.dart';

final estoqueProvider =
    StateNotifierProvider<EstoqueController, AsyncValue<List<EstoqueModel>>>(
      (ref) => EstoqueController(ref),
    );

class EstoqueController extends StateNotifier<AsyncValue<List<EstoqueModel>>> {
  final EstoqueService _service = EstoqueService();
  final Ref _ref;

  EstoqueController(this._ref) : super(const AsyncValue.loading()) {
    // Não carrega automaticamente no construtor
  }

  Future<void> loadEstoques() async {
    try {
      state = const AsyncValue.loading();
      final estoque = await _service.getEstoques();
      state = AsyncValue.data(estoque);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEstoque(EstoqueModel estoque) async {
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

    // Cria uma cópia do estoque com o usuário que criou
    final estoqueComUsuario = estoque.copyWith(
      criadoPor: userId,
      criadoEm: DateTime.now(),
    );

    await _service.addEstoque(estoqueComUsuario);
    await loadEstoques();
  }

  Future<void> updateEstoque(EstoqueModel estoque) async {
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

    // Cria uma cópia do estoque com o usuário que atualizou
    final estoqueComUsuario = estoque.copyWith(
      atualizadoPor: userId,
      atualizadoEm: DateTime.now(),
    );

    await _service.updateEstoque(estoqueComUsuario);
    await loadEstoques();
  }

  Future<void> deleteEstoque(String id) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }
    await _service.deleteEstoque(id);
    await loadEstoques();
  }
}
