import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fornecedor_model.dart';
import '../../../core/services/supabase_service.dart';

class FornecedorService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'fornecedores';

  // Método para testar a estrutura da tabela
  Future<void> testarEstruturaTabela() async {
    try {
      print('🔍 [DEBUG] Testando estrutura da tabela fornecedores');

      // Tenta buscar a estrutura da tabela
      final data = await _client
          .from(_table)
          .select('*')
          .limit(1)
          .then((value) => value as List);

      print(
        '✅ [DEBUG] Estrutura da tabela OK. Colunas disponíveis: ${data.isNotEmpty ? data.first.keys.toList() : 'Tabela vazia'}',
      );
    } catch (e) {
      print('❌ [DEBUG] Erro ao testar estrutura da tabela: $e');
      throw Exception('Erro ao testar estrutura da tabela: $e');
    }
  }

  Future<List<FornecedorModel>> getFornecedores() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .then((value) => value as List);
      return data.map((e) => FornecedorModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar fornecedores: $e');
    }
  }

  Future<bool> documentoExiste(String documento) async {
    try {
      print('🔍 [DEBUG] Verificando documento: $documento');

      final data = await _client
          .from(_table)
          .select('id')
          .eq('documento', documento)
          .then((value) => value as List);

      final existe = data.isNotEmpty;
      print(
        '🔍 [DEBUG] Documento existe: $existe (${data.length} registros encontrados)',
      );

      return existe;
    } catch (e) {
      print('❌ [DEBUG] Erro ao verificar documento: $e');
      throw Exception('Erro ao verificar documento: $e');
    }
  }

  Future<void> addFornecedor(FornecedorModel fornecedor) async {
    try {
      print(
        '🔍 [DEBUG] Verificando se documento já existe: ${fornecedor.documento}',
      );

      // Testa a estrutura da tabela primeiro
      await testarEstruturaTabela();

      // Verifica se o documento já existe
      final existe = await documentoExiste(fornecedor.documento);
      if (existe) {
        print('❌ [DEBUG] Documento já existe no banco');
        throw Exception(
          'Já existe um fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      }

      print('✅ [DEBUG] Documento não existe, preparando dados para inserção');

      // Usa o método específico para inserção (sem ID)
      final dados = fornecedor.toMapForInsert();
      print('📤 [DEBUG] Dados para inserção: $dados');

      final response = await _client.from(_table).insert(dados).select();
      print('✅ [DEBUG] Inserção realizada com sucesso: $response');
    } catch (e) {
      print('❌ [DEBUG] Erro na inserção: $e');

      if (e.toString().contains('duplicate key value')) {
        throw Exception(
          'Já existe um fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      } else if (e.toString().contains('violates unique constraint')) {
        throw Exception(
          'Já existe um fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      } else if (e.toString().contains('409')) {
        throw Exception(
          'Já existe um fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      } else if (e.toString().contains('foreign key constraint') ||
          e.toString().contains('23503')) {
        throw Exception(
          'Erro de referência: Usuário não encontrado. Verifique se você está logado corretamente.',
        );
      } else {
        throw Exception('Erro ao adicionar fornecedor: $e');
      }
    }
  }

  Future<void> updateFornecedor(FornecedorModel fornecedor) async {
    try {
      // Verifica se existe outro fornecedor com o mesmo documento
      final data = await _client
          .from(_table)
          .select('id')
          .eq('documento', fornecedor.documento)
          .neq('id', fornecedor.id)
          .then((value) => value as List);

      if (data.isNotEmpty) {
        throw Exception(
          'Já existe outro fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      }

      await _client
          .from(_table)
          .update(fornecedor.toMap())
          .eq('id', fornecedor.id);
    } catch (e) {
      if (e.toString().contains('duplicate key value')) {
        throw Exception(
          'Já existe outro fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      } else if (e.toString().contains('violates unique constraint')) {
        throw Exception(
          'Já existe outro fornecedor cadastrado com este ${fornecedor.tipoDocumento}',
        );
      } else {
        throw Exception('Erro ao atualizar fornecedor: $e');
      }
    }
  }

  Future<void> deleteFornecedor(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar fornecedor: $e');
    }
  }
}
