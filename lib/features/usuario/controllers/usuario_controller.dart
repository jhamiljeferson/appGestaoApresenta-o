import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario_model.dart';
import '../services/usuario_service.dart';
import '../../../core/services/auth_service.dart';
import 'dart:math';
import '../../cargo/services/cargo_service.dart';

final usuarioProvider =
    StateNotifierProvider<UsuarioController, AsyncValue<List<UsuarioModel>>>(
      (ref) => UsuarioController(),
    );

final permissoesUsuarioProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((
      ref,
      cargoId,
    ) async {
      return await CargoService().getPermissoesDoUsuario(cargoId);
    });

// Providers para lojas
final lojasDisponiveisProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await UsuarioService().getLojasDisponiveis();
});

final lojasDoUsuarioProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      usuarioId,
    ) async {
      try {
        return await UsuarioService().getLojasDoUsuario(usuarioId);
      } catch (e) {
        // Se o usuário não for encontrado, retorna lista vazia
        if (e.toString().contains('não encontrado') ||
            e.toString().contains('not found')) {
          return [];
        }
        throw e;
      }
    });

class UsuarioController extends StateNotifier<AsyncValue<List<UsuarioModel>>> {
  final UsuarioService _service = UsuarioService();

  UsuarioController() : super(const AsyncValue.loading()) {
    loadUsuarios();
  }

  Future<void> loadUsuarios() async {
    try {
      state = const AsyncValue.loading();
      final usuarios = await _service.getUsuarios();
      state = AsyncValue.data(usuarios);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> addUsuario(
    UsuarioModel usuario, {
    String? nomeEmpresa,
  }) async {
    // Gera senha temporária
    String gerarSenhaTemporaria({int length = 10}) {
      const chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%&*';
      final rand = Random.secure();
      return List.generate(
        length,
        (_) => chars[rand.nextInt(chars.length)],
      ).join();
    }

    final senhaTemporaria = gerarSenhaTemporaria();
    try {
      // Cria usuário no Supabase Auth
      final authResponse = await AuthService().signUp(
        usuario.email,
        senhaTemporaria,
      );
      final userId = authResponse.user?.id;
      if (userId == null)
        throw Exception('Erro ao criar usuário no Supabase Auth');
      // Salva usuário na tabela local
      final usuarioComId = UsuarioModel(
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        ativo: usuario.ativo,
        cargoId: usuario.cargoId,
        userId: userId,
        lojasIds: usuario.lojasIds,
        criadoEm: usuario.criadoEm,
      );
      await _service.addUsuario(usuarioComId);

      // Salva as relações com as lojas
      if (usuario.lojasIds.isNotEmpty) {
        await _service.salvarLojasDoUsuario(usuario.id, usuario.lojasIds);
      }

      await loadUsuarios();
      return senhaTemporaria;
    } catch (e) {
      throw Exception('Erro ao adicionar usuário: $e');
    }
  }

  Future<void> updateUsuario(UsuarioModel usuario) async {
    await _service.updateUsuario(usuario);

    // Atualiza as relações com as lojas
    await _service.salvarLojasDoUsuario(usuario.id, usuario.lojasIds);

    await loadUsuarios();
  }

  Future<void> deleteUsuario(String id) async {
    try {
      // Remove o usuário e suas relações
      await _service.deleteUsuario(id);

      // Recarrega a lista de usuários
      await loadUsuarios();
    } catch (e) {
      // Se houver erro, recarrega a lista para garantir consistência
      await loadUsuarios();
      throw Exception('Erro ao deletar usuário: $e');
    }
  }

  // Método para invalidar providers relacionados a um usuário específico
  void invalidarProvidersDoUsuario(Ref ref, String usuarioId) {
    ref.invalidate(lojasDoUsuarioProvider(usuarioId));
  }
}
