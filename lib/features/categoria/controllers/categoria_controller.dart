import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../../core/services/user_audit_service.dart';

final categoriaProvider =
    StateNotifierProvider<
      CategoriaController,
      AsyncValue<List<CategoriaModel>>
    >((ref) => CategoriaController(ref));

final categoriaCountProvider = FutureProvider<int>((ref) async {
  final service = CategoriaService();
  return await service.getCategoriasCount();
});

final hasCategoriasProvider = FutureProvider<bool>((ref) async {
  final service = CategoriaService();
  return await service.hasCategorias();
});

class CategoriaController
    extends StateNotifier<AsyncValue<List<CategoriaModel>>> {
  final CategoriaService _service = CategoriaService();
  final Ref _ref;

  CategoriaController(this._ref) : super(const AsyncValue.loading()) {
    loadCategorias();
  }

  Future<void> loadCategorias() async {
    try {
      state = const AsyncValue.loading();
      final categorias = await _service.getCategorias();
      state = AsyncValue.data(categorias);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> hasCategorias() async {
    try {
      return await _service.hasCategorias();
    } catch (e) {
      return false;
    }
  }

  Future<int> getCategoriasCount() async {
    try {
      return await _service.getCategoriasCount();
    } catch (e) {
      return 0;
    }
  }

  Future<void> addCategoria(CategoriaModel categoria) async {
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

    // Cria uma cópia da categoria com o usuário que criou
    final categoriaComUsuario = categoria.copyWith(
      criadoPor: userId,
      criadoEm: DateTime.now(),
    );

    await _service.addCategoria(categoriaComUsuario);
    await loadCategorias();
  }

  Future<void> updateCategoria(CategoriaModel categoria) async {
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

    // Cria uma cópia da categoria com o usuário que atualizou
    final categoriaComUsuario = categoria.copyWith(
      atualizadoPor: userId,
      atualizadoEm: DateTime.now(),
    );

    await _service.updateCategoria(categoriaComUsuario);
    await loadCategorias();
  }

  Future<void> deleteCategoria(String id) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }
    await _service.deleteCategoria(id);
    await loadCategorias();
  }
}
