import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fornecedor_model.dart';
import '../services/fornecedor_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';

final fornecedorProvider =
    StateNotifierProvider<
      FornecedorController,
      AsyncValue<List<FornecedorModel>>
    >((ref) => FornecedorController(ref));

class FornecedorController
    extends StateNotifier<AsyncValue<List<FornecedorModel>>> {
  final FornecedorService _service = FornecedorService();
  final Ref _ref;

  FornecedorController(this._ref) : super(const AsyncValue.loading()) {
    loadFornecedores();
  }

  Future<void> loadFornecedores() async {
    try {
      state = const AsyncValue.loading();
      final fornecedores = await _service.getFornecedores();
      state = AsyncValue.data(fornecedores);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Método para obter o ID do usuário da tabela usuarios
  Future<String?> getUsuarioId() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        print('❌ [DEBUG] Usuário não autenticado no Supabase Auth');
        return null;
      }

      print(
        '🔍 [DEBUG] Buscando usuário na tabela usuarios com user_id: ${user.id}',
      );

      final client = SupabaseService().client;
      final data = await client
          .from('usuarios')
          .select('id, nome, email')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        final usuarioId = data['id'] as String?;
        print('✅ [DEBUG] Usuário encontrado: ${data['nome']} (ID: $usuarioId)');
        return usuarioId;
      } else {
        print('❌ [DEBUG] Usuário não encontrado na tabela usuarios');
        return null;
      }
    } catch (e) {
      print('❌ [DEBUG] Erro ao obter ID do usuário: $e');
      return null;
    }
  }

  Future<void> addFornecedor(FornecedorModel fornecedor) async {
    try {
      print('🚀 [DEBUG] Iniciando adição de fornecedor');

      // Obtém o ID do usuário da tabela usuarios
      final userId = await getUsuarioId();

      print('👤 [DEBUG] Usuário logado ID da tabela usuarios: $userId');

      if (userId == null) {
        print('❌ [DEBUG] Usuário não encontrado na tabela usuarios');
        throw Exception(
          'Usuário não encontrado. Verifique se você está logado corretamente.',
        );
      }

      // Cria uma cópia do fornecedor com o usuário que criou
      final fornecedorComUsuario = FornecedorModel(
        id: fornecedor.id,
        nome: fornecedor.nome,
        tipoDocumento: fornecedor.tipoDocumento,
        documento: fornecedor.documento,
        email: fornecedor.email,
        telefone: fornecedor.telefone,
        endereco: fornecedor.endereco,
        criadoEm: fornecedor.criadoEm,
        criadoPor: userId,
        atualizadoEm: fornecedor.atualizadoEm,
        atualizadoPor: fornecedor.atualizadoPor,
      );

      print(
        '📝 [DEBUG] Fornecedor preparado: ${fornecedorComUsuario.nome} - ${fornecedorComUsuario.documento}',
      );

      await _service.addFornecedor(fornecedorComUsuario);
      print('✅ [DEBUG] Fornecedor adicionado com sucesso no serviço');

      await loadFornecedores();
      print('✅ [DEBUG] Lista de fornecedores recarregada');
    } catch (e) {
      print('❌ [DEBUG] Erro no controller: $e');
      throw Exception('Erro ao adicionar fornecedor: $e');
    }
  }

  Future<void> updateFornecedor(FornecedorModel fornecedor) async {
    try {
      // Obtém o ID do usuário da tabela usuarios
      final userId = await getUsuarioId();

      if (userId == null) {
        throw Exception(
          'Usuário não encontrado. Verifique se você está logado corretamente.',
        );
      }

      // Cria uma cópia do fornecedor com o usuário que atualizou
      final fornecedorComUsuario = FornecedorModel(
        id: fornecedor.id,
        nome: fornecedor.nome,
        tipoDocumento: fornecedor.tipoDocumento,
        documento: fornecedor.documento,
        email: fornecedor.email,
        telefone: fornecedor.telefone,
        endereco: fornecedor.endereco,
        criadoEm: fornecedor.criadoEm,
        criadoPor: fornecedor.criadoPor,
        atualizadoEm: DateTime.now(),
        atualizadoPor: userId,
      );

      await _service.updateFornecedor(fornecedorComUsuario);
      await loadFornecedores();
    } catch (e) {
      throw Exception('Erro ao atualizar fornecedor: $e');
    }
  }

  Future<void> deleteFornecedor(String id) async {
    try {
      await _service.deleteFornecedor(id);
      await loadFornecedores();
    } catch (e) {
      throw Exception('Erro ao deletar fornecedor: $e');
    }
  }
}
