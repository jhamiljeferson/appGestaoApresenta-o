import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loja_model.dart';
import '../services/loja_service.dart';
import '../../../core/services/user_audit_service.dart';

final lojaProvider =
    StateNotifierProvider<LojaController, AsyncValue<List<LojaModel>>>(
      (ref) => LojaController(),
    );

class LojaController extends StateNotifier<AsyncValue<List<LojaModel>>> {
  final LojaService _service = LojaService();

  LojaController() : super(const AsyncValue.loading()) {
    loadLojas();
  }

  Future<void> loadLojas() async {
    try {
      state = const AsyncValue.loading();
      final lojas = await _service.getLojas();
      state = AsyncValue.data(lojas);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLoja(LojaModel loja) async {
    // Obtém o ID do usuário logado
    final userId = await UserAuditService().getUsuarioId();
    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Verifique se você está logado corretamente.',
      );
    }

    // Cria uma cópia da loja com o usuário que criou
    final lojaComUsuario = loja.copyWith(
      criadoPor: userId,
      criadoEm: DateTime.now(),
    );

    await _service.addLoja(lojaComUsuario);
    await loadLojas();
  }

  Future<void> updateLoja(LojaModel loja) async {
    // Obtém o ID do usuário logado
    final userId = await UserAuditService().getUsuarioId();
    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Verifique se você está logado corretamente.',
      );
    }

    // Cria uma cópia da loja com o usuário que atualizou
    final lojaComUsuario = loja.copyWith(
      atualizadoPor: userId,
      atualizadoEm: DateTime.now(),
    );

    await _service.updateLoja(lojaComUsuario);
    await loadLojas();
  }

  Future<void> deleteLoja(String id) async {
    await _service.deleteLoja(id);
    await loadLojas();
  }
}
