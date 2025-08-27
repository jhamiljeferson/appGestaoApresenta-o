import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimentacao_estoque_model.dart';
import '../../../core/services/supabase_service.dart';

class MovimentacaoEstoqueService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'movimentacoes_estoque';

  Future<List<MovimentacaoEstoqueModel>> getMovimentacoes() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .order('criado_em', ascending: false)
          .then((value) => value as List);
      return data.map((e) => MovimentacaoEstoqueModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar movimentações: $e');
    }
  }

  Future<List<MovimentacaoEstoqueModel>> getMovimentacoesPorLoja(
    String lojaId,
  ) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('loja_id', lojaId)
          .order('criado_em', ascending: false)
          .then((value) => value as List);
      return data.map((e) => MovimentacaoEstoqueModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar movimentações da loja: $e');
    }
  }

  Future<void> addMovimentacao(MovimentacaoEstoqueModel movimentacao) async {
    try {
      print('Adicionando movimentação: ${movimentacao.toMap()}');
      await _client.from(_table).insert(movimentacao.toMap());
      print('Movimentação adicionada com sucesso');
    } catch (e) {
      print('Erro ao adicionar movimentação: $e');
      throw Exception('Erro ao adicionar movimentação: $e');
    }
  }

  Future<void> updateMovimentacao(MovimentacaoEstoqueModel movimentacao) async {
    try {
      await _client
          .from(_table)
          .update(movimentacao.toMap())
          .eq('id', movimentacao.id);
    } catch (e) {
      throw Exception('Erro ao atualizar movimentação: $e');
    }
  }

  Future<void> deleteMovimentacao(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar movimentação: $e');
    }
  }

  // Método para buscar o estoque atual de um produto em uma loja
  Future<int> getEstoqueAtual(String produtoId, String lojaId) async {
    try {
      print('Consultando estoque para produto: $produtoId, loja: $lojaId');
      final data = await _client
          .from('estoque')
          .select('quantidade')
          .eq('produto_id', produtoId)
          .eq('loja_id', lojaId)
          .maybeSingle();

      if (data != null) {
        final int quantidadeAtual = data['quantidade'] as int;
        print('Estoque encontrado: $quantidadeAtual');
        return quantidadeAtual;
      }
      print('Nenhum estoque encontrado, retornando 0');
      return 0;
    } catch (e) {
      print('Erro ao consultar estoque: $e');
      // Se não encontrar estoque, retorna 0
      return 0;
    }
  }

  // Método para atualizar o estoque após uma movimentação
  Future<void> atualizarEstoque(
    String produtoId,
    String lojaId,
    int novaQuantidade, {
    String? atualizadoPorUsuarioId,
  }) async {
    try {
      print(
        'Atualizando estoque para produto: $produtoId, loja: $lojaId, quantidade: $novaQuantidade',
      );
      // Verifica se já existe um registro de estoque (busca apenas o id)
      final estoqueExistente = await _client
          .from('estoque')
          .select('id')
          .eq('produto_id', produtoId)
          .eq('loja_id', lojaId)
          .maybeSingle();

      if (estoqueExistente != null) {
        print('Atualizando estoque existente: ${estoqueExistente['id']}');
        // Atualiza o estoque existente
        // Atualiza a quantidade e auditoria
        await _client
            .from('estoque')
            .update({
              'quantidade': novaQuantidade,
              'atualizado_por': atualizadoPorUsuarioId,
              'atualizado_em': DateTime.now().toIso8601String(),
            })
            .eq('id', estoqueExistente['id']);
      } else {
        print('Criando novo registro de estoque');
        // Cria um novo registro de estoque
        await _client.from('estoque').insert({
          'produto_id': produtoId,
          'loja_id': lojaId,
          'quantidade': novaQuantidade,
          'estoque_minimo': 0, // Valor padrão
          'criado_por': atualizadoPorUsuarioId,
          'criado_em': DateTime.now().toIso8601String(),
        });
      }
      print('Estoque atualizado com sucesso');
    } catch (e) {
      print('Erro ao atualizar estoque: $e');
      throw Exception('Erro ao atualizar estoque: $e');
    }
  }
}
