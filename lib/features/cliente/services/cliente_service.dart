import '../models/cliente_model.dart';
import '../../../core/services/supabase_service.dart';

class ClienteService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<ClienteModel>> getClientes() async {
    try {
      print('🔍 Buscando clientes...');
      final response = await _supabaseService.client
          .from('clientes')
          .select()
          .order('nome');

      print('✅ Clientes encontrados: ${response.length}');
      return (response as List)
          .map((cliente) => ClienteModel.fromMap(cliente))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar clientes: $e');
      throw Exception('Erro ao buscar clientes: $e');
    }
  }

  Future<List<ClienteModel>> getClientesPorLoja(String lojaId) async {
    try {
      if (lojaId.isEmpty) {
        throw Exception('ID da loja não pode estar vazio');
      }

      final response = await _supabaseService.client
          .from('clientes')
          .select()
          .eq('loja_id', lojaId)
          .order('nome');

      return (response as List)
          .map((cliente) => ClienteModel.fromMap(cliente))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar clientes da loja: $e');
    }
  }

  Future<ClienteModel> getCliente(String id) async {
    try {
      final response = await _supabaseService.client
          .from('clientes')
          .select()
          .eq('id', id)
          .single();

      return ClienteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao buscar cliente: $e');
    }
  }

  Future<ClienteModel> addCliente(ClienteModel cliente) async {
    try {
      final data = cliente.toMap();
      print('➕ Adicionando cliente: $data');

      final response = await _supabaseService.client
          .from('clientes')
          .insert(data)
          .select()
          .single();

      print('✅ Cliente adicionado com sucesso');
      return ClienteModel.fromMap(response);
    } catch (e) {
      print('❌ Erro ao adicionar cliente: $e');
      throw Exception('Erro ao adicionar cliente: $e');
    }
  }

  Future<ClienteModel> updateCliente(ClienteModel cliente) async {
    try {
      final response = await _supabaseService.client
          .from('clientes')
          .update(cliente.toMap())
          .eq('id', cliente.id)
          .select()
          .single();

      return ClienteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao atualizar cliente: $e');
    }
  }

  Future<void> deleteCliente(String id) async {
    try {
      await _supabaseService.client.from('clientes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar cliente: $e');
    }
  }

  Future<List<ClienteModel>> searchClientes(String query) async {
    try {
      final response = await _supabaseService.client
          .from('clientes')
          .select()
          .or(
            'nome.ilike.%$query%,documento.ilike.%$query%,email.ilike.%$query%',
          )
          .order('nome');

      return (response as List)
          .map((cliente) => ClienteModel.fromMap(cliente))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar clientes: $e');
    }
  }
}
