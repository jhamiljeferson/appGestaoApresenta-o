import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cargo_model.dart';
import '../models/permissao_model.dart';
import '../services/cargo_service.dart';
import '../../../core/services/user_audit_service.dart';

final cargoProvider =
    StateNotifierProvider<CargoController, AsyncValue<List<CargoModel>>>(
      (ref) => CargoController(),
    );

// Provider para adicionar cargo e retornar o cargo criado
final addCargoProvider = FutureProvider.family<CargoModel, CargoModel>((
  ref,
  cargo,
) async {
  final controller = ref.read(cargoProvider.notifier);
  return await controller.addCargo(cargo);
});

final permissoesDoCargoProvider =
    FutureProvider.family<List<PermissaoModel>, String>((ref, cargoId) async {
      return await CargoService().getPermissoesDoCargo(cargoId);
    });

final permissoesIdsDoCargoProvider =
    FutureProvider.family<List<String>, String>((ref, cargoId) async {
      final service = CargoService();
      return await service.getPermissoesIdsDoCargo(cargoId);
    });

// ==================================
// PROVIDERS PARA OPERAÇÕES EM LOTE
// ==================================

/// Provider para buscar permissões de múltiplos cargos em lote
final permissoesDeMultiplosCargosProvider =
    FutureProvider.family<Map<String, List<PermissaoModel>>, List<String>>((
      ref,
      cargoIds,
    ) async {
      final service = CargoService();
      return await service.getPermissoesDeMultiplosCargos(cargoIds);
    });

/// Provider para buscar cargos com suas permissões em lote
final cargosComPermissoesEmLoteProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final service = CargoService();
      return await service.getCargosComPermissoesEmLote();
    });

/// Provider para operações em lote de permissões
final permissoesEmLoteProvider =
    StateNotifierProvider<CargoController, AsyncValue<List<CargoModel>>>((ref) {
      return CargoController();
    });

final permissoesProvider = FutureProvider<List<PermissaoModel>>((ref) async {
  return await CargoService().getPermissoes();
});

class CargoController extends StateNotifier<AsyncValue<List<CargoModel>>> {
  final CargoService _service = CargoService();

  CargoController() : super(const AsyncValue.loading()) {
    loadCargos();
  }

  Future<void> loadCargos() async {
    try {
      state = const AsyncValue.loading();
      final cargos = await _service.getCargos();
      state = AsyncValue.data(cargos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CargoModel> addCargo(CargoModel cargo) async {
    try {
      print('🔧 [CargoController] Adicionando cargo: ${cargo.nome}');

      // Verificar se já existe um cargo com o mesmo nome
      final cargosExistentes = await _service.getCargos();
      final cargoExistente = cargosExistentes.any(
        (c) => c.nome.toLowerCase() == cargo.nome.toLowerCase(),
      );

      if (cargoExistente) {
        throw Exception('Já existe um cargo com o nome "${cargo.nome}"');
      }

      // Adicionar cargo e obter o cargo criado
      final cargoCriado = await _service.addCargo(cargo);

      print(
        '✅ [CargoController] Cargo criado com sucesso: ${cargoCriado.nome} (ID: ${cargoCriado.id})',
      );

      // Recarregar a lista
      await loadCargos();

      print('✅ [CargoController] Lista de cargos recarregada');

      // IMPORTANTE: Retornar o cargo criado com o ID correto
      return cargoCriado;
    } catch (e) {
      print('❌ [CargoController] Erro ao adicionar cargo: $e');
      rethrow;
    }
  }

  Future<void> updateCargo(CargoModel cargo) async {
    try {
      // Verificar se já existe outro cargo com o mesmo nome
      final cargosExistentes = await _service.getCargos();
      final cargoExistente = cargosExistentes
          .where(
            (c) =>
                c.id != cargo.id &&
                c.nome.toLowerCase() == cargo.nome.toLowerCase(),
          )
          .firstOrNull;

      if (cargoExistente != null) {
        throw Exception('Já existe um cargo com o nome "${cargo.nome}"');
      }

      // Atualizar o cargo
      await _service.updateCargo(cargo);

      // Recarregar a lista
      await loadCargos();
    } catch (e) {
      print('❌ [CargoController] Erro ao atualizar cargo: $e');
      rethrow;
    }
  }

  Future<void> deleteCargo(String id) async {
    try {
      await _service.deleteCargo(id);
      await loadCargos();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ==================================
  // MÉTODOS EM LOTE PARA CARGOS_PERMISSOES
  // ==================================

  /// Adiciona múltiplas permissões a um cargo em uma única operação
  Future<void> adicionarPermissoesEmLote(
    String cargoId,
    List<String> permissaoIds,
  ) async {
    try {
      print(
        '🔧 [CargoController] Adicionando ${permissaoIds.length} permissões em lote para cargo $cargoId',
      );

      // Validar se o cargo existe usando retry
      final cargo = await _service.getCargoComRetry(cargoId);
      if (cargo == null) {
        throw Exception(
          'Cargo não encontrado com ID: $cargoId após múltiplas tentativas',
        );
      }

      // Validar se as permissões existem
      final todasPermissoes = await _service.getPermissoes();
      final permissoesExistentes = todasPermissoes.map((p) => p.id).toSet();
      final permissoesInvalidas = permissaoIds
          .where((id) => !permissoesExistentes.contains(id))
          .toList();

      if (permissoesInvalidas.isNotEmpty) {
        throw Exception(
          'Permissões inválidas encontradas: $permissoesInvalidas',
        );
      }

      // Adicionar permissões em lote
      await _service.adicionarPermissoesEmLote(cargoId, permissaoIds);

      print(
        '✅ [CargoController] ${permissaoIds.length} permissões adicionadas em lote com sucesso',
      );
    } catch (e) {
      print('❌ [CargoController] Erro ao adicionar permissões em lote: $e');
      print('❌ [CargoController] Cargo ID: $cargoId');
      print('❌ [CargoController] Permissões IDs: $permissaoIds');
      rethrow;
    }
  }

  /// Remove múltiplas permissões de um cargo em uma única operação
  Future<void> removerPermissoesEmLote(
    String cargoId,
    List<String> permissaoIds,
  ) async {
    try {
      print(
        '🔧 [CargoController] Removendo ${permissaoIds.length} permissões em lote do cargo $cargoId',
      );

      // Validar se o cargo existe usando retry
      final cargo = await _service.getCargoComRetry(cargoId);
      if (cargo == null) {
        throw Exception(
          'Cargo não encontrado com ID: $cargoId após múltiplas tentativas',
        );
      }

      // Remover permissões em lote
      await _service.removerPermissoesEmLote(cargoId, permissaoIds);

      print(
        '✅ [CargoController] ${permissaoIds.length} permissões removidas em lote com sucesso',
      );
    } catch (e) {
      print('❌ [CargoController] Erro ao remover permissões em lote: $e');
      print('❌ [CargoController] Cargo ID: $cargoId');
      print('❌ [CargoController] Permissões IDs: $permissaoIds');
      rethrow;
    }
  }

  /// Sincroniza permissões de um cargo (remove todas e adiciona as novas)
  Future<void> sincronizarPermissoesEmLote(
    String cargoId,
    List<String> novasPermissaoIds,
  ) async {
    try {
      print(
        '🔧 [CargoController] Sincronizando permissões em lote para cargo $cargoId',
      );
      print('🔧 [CargoController] Novas permissões: $novasPermissaoIds');

      // Validar se o cargo existe usando retry
      final cargo = await _service.getCargoComRetry(cargoId);
      if (cargo == null) {
        throw Exception(
          'Cargo não encontrado com ID: $cargoId após múltiplas tentativas',
        );
      }

      // Validar se as permissões existem
      final todasPermissoes = await _service.getPermissoes();
      final permissoesExistentes = todasPermissoes.map((p) => p.id).toSet();
      final permissoesInvalidas = novasPermissaoIds
          .where((id) => !permissoesExistentes.contains(id))
          .toList();

      if (permissoesInvalidas.isNotEmpty) {
        throw Exception(
          'Permissões inválidas encontradas: $permissoesInvalidas',
        );
      }

      // Sincronizar permissões em lote
      await _service.sincronizarPermissoesEmLote(cargoId, novasPermissaoIds);

      print('✅ [CargoController] Sincronização em lote concluída com sucesso');
    } catch (e) {
      print('❌ [CargoController] Erro na sincronização em lote: $e');
      print('❌ [CargoController] Cargo ID: $cargoId');
      print('❌ [CargoController] Novas permissões: $novasPermissaoIds');
      rethrow;
    }
  }

  /// Busca permissões de múltiplos cargos em uma única operação
  Future<Map<String, List<PermissaoModel>>> getPermissoesDeMultiplosCargos(
    List<String> cargoIds,
  ) async {
    try {
      return await _service.getPermissoesDeMultiplosCargos(cargoIds);
    } catch (e) {
      print(
        '❌ [CargoController] Erro ao buscar permissões de múltiplos cargos: $e',
      );
      rethrow;
    }
  }

  /// Busca cargos com suas permissões em uma única operação
  Future<List<Map<String, dynamic>>> getCargosComPermissoesEmLote() async {
    try {
      return await _service.getCargosComPermissoesEmLote();
    } catch (e) {
      print(
        '❌ [CargoController] Erro ao buscar cargos com permissões em lote: $e',
      );
      rethrow;
    }
  }

  // ==================================
  // MÉTODOS EXISTENTES ATUALIZADOS
  // ==================================

  Future<void> salvarPermissoesDoCargo(
    String cargoId,
    List<String> permissaoIds,
  ) async {
    try {
      print('🔧 [CargoController] Salvando permissões para cargo $cargoId');
      print('🔧 [CargoController] Permissões a salvar: $permissaoIds');

      // Validar se o cargo existe usando retry
      final cargo = await _service.getCargoComRetry(cargoId);
      if (cargo == null) {
        throw Exception(
          'Cargo não encontrado com ID: $cargoId após múltiplas tentativas',
        );
      }

      // Validar se as permissões existem
      final todasPermissoes = await _service.getPermissoes();
      final permissoesExistentes = todasPermissoes.map((p) => p.id).toSet();
      final permissoesInvalidas = permissaoIds
          .where((id) => !permissoesExistentes.contains(id))
          .toList();

      if (permissoesInvalidas.isNotEmpty) {
        throw Exception(
          'Permissões inválidas encontradas: $permissoesInvalidas',
        );
      }

      // Usar sincronização em lote para melhor performance
      await sincronizarPermissoesEmLote(cargoId, permissaoIds);

      print(
        '✅ [CargoController] Permissões salvas com sucesso usando sincronização em lote',
      );
    } catch (e) {
      print('❌ [CargoController] Erro ao salvar permissões do cargo: $e');
      print('❌ [CargoController] Cargo ID: $cargoId');
      print('❌ [CargoController] Permissões IDs: $permissaoIds');
      rethrow;
    }
  }

  Future<void> adicionarPermissaoAoCargo(
    String cargoId,
    String permissaoId,
  ) async {
    try {
      await _service.adicionarPermissaoAoCargo(cargoId, permissaoId);
    } catch (e) {
      throw Exception('Erro ao adicionar permissão ao cargo: $e');
    }
  }

  Future<void> removerPermissaoDoCargo(
    String cargoId,
    String permissaoId,
  ) async {
    try {
      await _service.removerPermissaoDoCargo(cargoId, permissaoId);
    } catch (e) {
      throw Exception('Erro ao remover permissão do cargo: $e');
    }
  }

  Future<bool> cargoTemPermissao(
    String cargoId,
    String recurso,
    String acao,
  ) async {
    try {
      return await _service.cargoTemPermissao(cargoId, recurso, acao);
    } catch (e) {
      return false;
    }
  }

  Future<CargoModel?> getCargo(String id) async {
    try {
      return await _service.getCargo(id);
    } catch (e) {
      return null;
    }
  }
}
