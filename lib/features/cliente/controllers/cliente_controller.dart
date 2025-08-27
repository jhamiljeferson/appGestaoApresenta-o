import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';
import '../../../core/services/user_audit_service.dart';

class ClienteController extends StateNotifier<AsyncValue<List<ClienteModel>>> {
  final ClienteService _clienteService = ClienteService();

  ClienteController() : super(const AsyncValue.loading()) {
    loadClientes();
  }

  Future<void> loadClientes() async {
    state = const AsyncValue.loading();
    try {
      final clientes = await _clienteService.getClientes();
      state = AsyncValue.data(clientes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadClientesPorLoja(String lojaId) async {
    state = const AsyncValue.loading();
    try {
      final clientes = await _clienteService.getClientesPorLoja(lojaId);
      state = AsyncValue.data(clientes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCliente(ClienteModel cliente) async {
    try {
      final usuarioId = await UserAuditService().getUsuarioId();
      final clienteComAuditoria = cliente.copyWith(criadoPor: usuarioId);

      final novoCliente = await _clienteService.addCliente(clienteComAuditoria);

      state.whenData((clientes) {
        final novaLista = [...clientes, novoCliente];
        novaLista.sort((a, b) => a.nome.compareTo(b.nome));
        state = AsyncValue.data(novaLista);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCliente(ClienteModel cliente) async {
    try {
      final usuarioId = await UserAuditService().getUsuarioId();
      final clienteComAuditoria = cliente.copyWith(
        atualizadoPor: usuarioId,
        atualizadoEm: DateTime.now(),
      );

      final clienteAtualizado = await _clienteService.updateCliente(
        clienteComAuditoria,
      );

      state.whenData((clientes) {
        final novaLista = clientes.map((c) {
          return c.id == clienteAtualizado.id ? clienteAtualizado : c;
        }).toList();
        novaLista.sort((a, b) => a.nome.compareTo(b.nome));
        state = AsyncValue.data(novaLista);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCliente(String id) async {
    try {
      await _clienteService.deleteCliente(id);

      state.whenData((clientes) {
        final novaLista = clientes.where((c) => c.id != id).toList();
        state = AsyncValue.data(novaLista);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<ClienteModel>> searchClientes(String query) async {
    try {
      return await _clienteService.searchClientes(query);
    } catch (e) {
      throw Exception('Erro ao buscar clientes: $e');
    }
  }

  Future<ClienteModel?> getCliente(String id) async {
    try {
      return await _clienteService.getCliente(id);
    } catch (e) {
      throw Exception('Erro ao buscar cliente: $e');
    }
  }
}

final clienteProvider =
    StateNotifierProvider<ClienteController, AsyncValue<List<ClienteModel>>>(
      (ref) => ClienteController(),
    );
