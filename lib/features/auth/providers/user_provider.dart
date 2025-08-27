import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../usuario/models/usuario_model.dart';
import '../../usuario/services/usuario_service.dart';
import '../../cargo/services/cargo_service.dart';
import '../../cargo/models/cargo_model.dart';

class UserState {
  final UsuarioModel? usuario;
  final CargoModel? cargo;
  final List<Map<String, dynamic>> lojas;
  final bool isLoading;
  final String? error;

  UserState({
    this.usuario,
    this.cargo,
    this.lojas = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UsuarioModel? usuario,
    CargoModel? cargo,
    List<Map<String, dynamic>>? lojas,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      usuario: usuario ?? this.usuario,
      cargo: cargo ?? this.cargo,
      lojas: lojas ?? this.lojas,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UsuarioService _usuarioService;
  final CargoService _cargoService;

  UserNotifier(this._usuarioService, this._cargoService) : super(UserState());

  Future<void> loadUserInfo() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final authUser = AuthService().currentUser;
      if (authUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Usuário não autenticado',
        );
        return;
      }

      // Busca informações do usuário
      final usuarios = await _usuarioService.getUsuarios();
      final usuario = usuarios.firstWhere(
        (u) => u.userId == authUser.id,
        orElse: () => throw Exception('Usuário não encontrado'),
      );

      // Busca cargo se existir
      CargoModel? cargo;
      if (usuario.cargoId != null) {
        final cargos = await _cargoService.getCargos();
        cargo = cargos.firstWhere(
          (c) => c.id == usuario.cargoId,
          orElse: () => throw Exception('Cargo não encontrado'),
        );
      }

      // Busca lojas
      final lojas = await _usuarioService.getLojasDoUsuario(usuario.id);

      state = state.copyWith(
        usuario: usuario,
        cargo: cargo,
        lojas: lojas,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = UserState();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(UsuarioService(), CargoService());
});
