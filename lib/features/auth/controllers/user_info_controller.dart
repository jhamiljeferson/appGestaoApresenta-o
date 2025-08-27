import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../usuario/models/usuario_model.dart';
import '../../usuario/services/usuario_service.dart';
import '../../cargo/services/cargo_service.dart';
import '../../cargo/models/cargo_model.dart';

class UserInfoState {
  final UsuarioModel? usuario;
  final CargoModel? cargo;
  final List<Map<String, dynamic>> lojas;
  final String? error;

  UserInfoState({this.usuario, this.cargo, this.lojas = const [], this.error});

  UserInfoState copyWith({
    UsuarioModel? usuario,
    CargoModel? cargo,
    List<Map<String, dynamic>>? lojas,
    String? error,
  }) {
    return UserInfoState(
      usuario: usuario ?? this.usuario,
      cargo: cargo ?? this.cargo,
      lojas: lojas ?? this.lojas,
      error: error ?? this.error,
    );
  }
}

final userInfoProvider =
    StateNotifierProvider<UserInfoController, AsyncValue<UserInfoState>>(
      (ref) => UserInfoController(),
    );

class UserInfoController extends StateNotifier<AsyncValue<UserInfoState>> {
  final UsuarioService _usuarioService = UsuarioService();
  final CargoService _cargoService = CargoService();

  UserInfoController() : super(AsyncValue.data(UserInfoState())) {
    print('[UserInfoController] Inicializando controller');
    // Não carrega automaticamente, será chamado pelo AuthController quando necessário
  }

  Future<void> loadUserInfo() async {
    print(
      '[UserInfoController] Iniciando carregamento das informações do usuário',
    );
    try {
      state = const AsyncValue.loading();

      final authUser = AuthService().currentUser;
      print('[UserInfoController] Verificando usuário autenticado');

      if (authUser == null) {
        print('[UserInfoController] Usuário não autenticado');
        state = AsyncValue.data(UserInfoState());
        return;
      }

      // Busca informações do usuário
      print('[UserInfoController] Buscando lista de usuários');
      final usuarios = await _usuarioService.getUsuarios();
      print('[UserInfoController] Usuários encontrados: ${usuarios.length}');

      print('[UserInfoController] Buscando informações do usuário');
      final usuario = usuarios.firstWhere(
        (u) => u.userId == authUser.id,
        orElse: () => throw Exception('Usuário não encontrado'),
      );
      print('[UserInfoController] Usuário encontrado: ${usuario.nome}');

      // Busca cargo se existir
      CargoModel? cargo;
      if (usuario.cargoId != null) {
        print('[UserInfoController] Buscando informações do cargo');
        final cargos = await _cargoService.getCargos();
        print('[UserInfoController] Cargos encontrados: ${cargos.length}');
        cargo = cargos.firstWhere(
          (c) => c.id == usuario.cargoId,
          orElse: () => throw Exception('Cargo não encontrado'),
        );
        print('[UserInfoController] Cargo encontrado: ${cargo.nome}');
      }

      // Busca lojas
      print('[UserInfoController] Buscando lojas associadas');
      final lojas = await _usuarioService.getLojasDoUsuario(usuario.id);
      print('[UserInfoController] Lojas encontradas: ${lojas.length}');

      state = AsyncValue.data(
        UserInfoState(usuario: usuario, cargo: cargo, lojas: lojas),
      );
    } catch (e, st) {
      print('[UserInfoController] Erro ao carregar informações: $e');
      print('[UserInfoController] Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
    print('[UserInfoController] Carregamento finalizado');
  }

  void clear() {
    print('[UserInfoController] Limpando informações do usuário');
    state = AsyncValue.data(UserInfoState());
  }
}
