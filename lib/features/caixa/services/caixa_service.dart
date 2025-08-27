import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/caixa_model.dart';
import '../models/caixa_movimentacao_model.dart';
import '../../../core/services/supabase_service.dart';

class CaixaService {
  final SupabaseService _supabaseService = SupabaseService();

  // ==================================
  // OPERAÇÕES DO CAIXA
  // ==================================

  Future<List<CaixaModel>> getCaixas() async {
    try {
      final response = await _supabaseService.client
          .from('caixa')
          .select()
          .order('criado_em', ascending: false);

      return (response as List<dynamic>)
          .map((caixa) => CaixaModel.fromMap(caixa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar caixas: $e');
    }
  }

  Future<List<CaixaModel>> getCaixasPorLoja(String lojaId) async {
    try {
      final response = await _supabaseService.client
          .from('caixa')
          .select()
          .eq('loja_id', lojaId)
          .order('criado_em', ascending: false);

      return (response as List<dynamic>)
          .map((caixa) => CaixaModel.fromMap(caixa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar caixas da loja: $e');
    }
  }

  Future<CaixaModel?> getCaixaAbertoPorLoja(String lojaId) async {
    try {
      final response = await _supabaseService.client
          .from('caixa')
          .select()
          .eq('loja_id', lojaId)
          .eq('status', 'aberto')
          .maybeSingle();

      if (response == null) return null;
      return CaixaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao buscar caixa aberto da loja: $e');
    }
  }

  Future<CaixaModel> getCaixa(String id) async {
    try {
      final response = await _supabaseService.client
          .from('caixa')
          .select()
          .eq('id', id)
          .single();

      return CaixaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao buscar caixa: $e');
    }
  }

  Future<CaixaModel> abrirCaixa(CaixaModel caixa) async {
    try {
      print(
        '🔧 [CaixaService] Tentando abrir caixa para loja: ${caixa.lojaId}',
      );

      // Verificar se já existe um caixa aberto para a loja
      final caixaExistente = await getCaixaAbertoPorLoja(caixa.lojaId);
      if (caixaExistente != null) {
        print('❌ [CaixaService] Já existe caixa aberto: ${caixaExistente.id}');
        throw Exception(
          'Já existe um caixa aberto para esta loja. Feche o caixa atual antes de abrir um novo.',
        );
      }

      // Verificar se o usuário existe antes de inserir
      try {
        final usuario = await _supabaseService.client
            .from('usuarios')
            .select('id')
            .eq('id', caixa.usuarioAberturaId)
            .maybeSingle();

        if (usuario == null) {
          throw Exception(
            'Usuário não encontrado com ID: ${caixa.usuarioAberturaId}',
          );
        }
        print('✅ [CaixaService] Usuário validado: ${usuario['id']}');
      } catch (e) {
        print('❌ [CaixaService] Erro ao validar usuário: $e');
        throw Exception('Erro ao validar usuário: $e');
      }

      // Verificar se a loja existe
      try {
        final loja = await _supabaseService.client
            .from('lojas')
            .select('id')
            .eq('id', caixa.lojaId)
            .maybeSingle();

        if (loja == null) {
          throw Exception('Loja não encontrada com ID: ${caixa.lojaId}');
        }
        print('✅ [CaixaService] Loja validada: ${loja['id']}');
      } catch (e) {
        print('❌ [CaixaService] Erro ao validar loja: $e');
        throw Exception('Erro ao validar loja: $e');
      }

      // Preparar dados para inserção (SEM ID - deixar o banco gerar)
      final dados = {
        'loja_id': caixa.lojaId,
        'usuario_abertura_id': caixa.usuarioAberturaId,
        'data_abertura': caixa.dataAbertura.toIso8601String(),
        'saldo_inicial': caixa.saldoInicial,
        'status': caixa.status.name,
        'criado_por': caixa.criadoPor,
      };

      print('🔧 [CaixaService] Dados para inserção: $dados');
      print('🔧 [CaixaService] ID será gerado pelo banco de dados');

      // Inserir caixa
      final response = await _supabaseService.client
          .from('caixa')
          .insert(dados)
          .select(
            'id, loja_id, usuario_abertura_id, data_abertura, saldo_inicial, status, criado_em, criado_por',
          )
          .single();

      print('✅ [CaixaService] Caixa criado com sucesso: ${response['id']}');

      return CaixaModel.fromMap(response);
    } catch (e) {
      print('❌ [CaixaService] Erro ao abrir caixa: $e');
      if (e.toString().contains('duplicate key')) {
        throw Exception(
          'Erro: Já existe um caixa aberto para esta loja. Verifique o status atual.',
        );
      }
      if (e.toString().contains('foreign key constraint')) {
        throw Exception(
          'Erro: Dados inválidos. Verifique se a loja e o usuário existem.',
        );
      }
      throw Exception('Erro ao abrir caixa: $e');
    }
  }

  /// Fecha um caixa e calcula o saldo final
  Future<CaixaModel> fecharCaixa(
    String caixaId,
    String usuarioFechamentoId, {
    double? saldoFinalManual,
    String? observacoes,
  }) async {
    try {
      print('🔧 [CaixaService] Tentando fechar caixa: $caixaId');

      // Buscar o caixa atual
      final caixa = await getCaixa(caixaId);
      if (caixa == null) {
        throw Exception('Caixa não encontrado: $caixaId');
      }

      // Verificar se o caixa já está fechado
      if (caixa.isFechado) {
        throw Exception('Caixa já está fechado');
      }

      // Verificar se o usuário de fechamento existe
      try {
        final usuario = await _supabaseService.client
            .from('usuarios')
            .select('id')
            .eq('id', usuarioFechamentoId)
            .maybeSingle();

        if (usuario == null) {
          throw Exception(
            'Usuário de fechamento não encontrado com ID: $usuarioFechamentoId',
          );
        }
        print('✅ [CaixaService] Usuário de fechamento validado: ${usuario['id']}');
      } catch (e) {
        print('❌ [CaixaService] Erro ao validar usuário de fechamento: $e');
        throw Exception('Erro ao validar usuário de fechamento: $e');
      }

      // Calcular saldo final se não fornecido
      double saldoFinal = saldoFinalManual ?? await calcularSaldoAtual(caixaId);

      // Preparar dados para atualização
      final dados = {
        'status': StatusCaixa.fechado.name,
        'usuario_fechamento_id': usuarioFechamentoId,
        'data_fechamento': DateTime.now().toIso8601String(),
        'saldo_final': saldoFinal,
        'atualizado_em': DateTime.now().toIso8601String(),
        'atualizado_por': usuarioFechamentoId,
      };

      print('🔧 [CaixaService] Dados para fechamento: $dados');

      // Atualizar caixa
      final response = await _supabaseService.client
          .from('caixa')
          .update(dados)
          .eq('id', caixaId)
          .select()
          .single();

      print('✅ [CaixaService] Caixa fechado com sucesso: ${response['id']}');

      // Se houver observações, criar movimentação de observação
      if (observacoes != null && observacoes.isNotEmpty) {
        try {
          final movimentacao = CaixaMovimentacaoModel.novo(
            caixaId: caixaId,
            tipo: TipoMovimentacaoCaixa.saida,
            valor: 0.0, // Valor zero para observações
            usuarioId: usuarioFechamentoId,
            descricao: 'Fechamento: $observacoes',
            criadoPor: usuarioFechamentoId,
          );

          await addMovimentacao(movimentacao);
          print('✅ [CaixaService] Observações de fechamento registradas');
        } catch (e) {
          print('⚠️ [CaixaService] Erro ao registrar observações: $e');
          // Não falhar o fechamento por erro nas observações
        }
      }

      return CaixaModel.fromMap(response);
    } catch (e) {
      print('❌ [CaixaService] Erro ao fechar caixa: $e');
      throw Exception('Erro ao fechar caixa: $e');
    }
  }

  Future<void> deleteCaixa(String id) async {
    try {
      await _supabaseService.client.from('caixa').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar caixa: $e');
    }
  }

  // ==================================
  // OPERAÇÕES DE MOVIMENTAÇÃO
  // ==================================

  Future<List<CaixaMovimentacaoModel>> getMovimentacoesPorCaixa(
    String caixaId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('caixa_movimentacao')
          .select()
          .eq('caixa_id', caixaId)
          .order('data', ascending: false);

      return (response as List<dynamic>)
          .map((mov) => CaixaMovimentacaoModel.fromMap(mov as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar movimentações do caixa: $e');
    }
  }

  Future<CaixaMovimentacaoModel> addMovimentacao(
    CaixaMovimentacaoModel movimentacao,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('caixa_movimentacao')
          .insert(movimentacao.toMap())
          .select()
          .single();

      return CaixaMovimentacaoModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao adicionar movimentação: $e');
    }
  }

  Future<void> deleteMovimentacao(String id) async {
    try {
      await _supabaseService.client
          .from('caixa_movimentacao')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar movimentação: $e');
    }
  }

  // ==================================
  // OPERAÇÕES ESPECÍFICAS
  // ==================================

  Future<void> registrarVenda(
    String caixaId,
    String vendaId,
    double valor,
    String usuarioId,
  ) async {
    try {
      print('🔧 [CaixaService] Registrando venda no caixa: $caixaId');
      print('🔧 [CaixaService] Venda ID: $vendaId, Valor: $valor');

      // Verificar se o caixa existe e está aberto
      final caixa = await getCaixa(caixaId);
      if (caixa == null) {
        throw Exception('Caixa não encontrado: $caixaId');
      }

      if (caixa.isFechado) {
        throw Exception('Não é possível registrar vendas em caixa fechado');
      }

      print(
        '✅ [CaixaService] Caixa validado: ${caixa.id} - Status: ${caixa.status.name}',
      );

      // Criar movimentação da venda
      final movimentacao = CaixaMovimentacaoModel.novo(
        caixaId: caixaId,
        tipo: TipoMovimentacaoCaixa.venda,
        valor: valor,
        usuarioId: usuarioId,
        vendaId: vendaId,
        descricao: 'Venda registrada',
        criadoPor: usuarioId,
      );

      print('🔧 [CaixaService] Movimentação criada, inserindo no banco...');

      // Inserir movimentação
      final response = await _supabaseService.client
          .from('caixa_movimentacao')
          .insert(movimentacao.toMap())
          .select()
          .single();

      print(
        '✅ [CaixaService] Venda registrada no caixa com sucesso: ${response['id']}',
      );

      // Invalidar providers relacionados para atualizar a interface
      // Note: Em uma implementação mais robusta, você pode querer
      // atualizar o estado local também
    } catch (e) {
      print('❌ [CaixaService] Erro ao registrar venda no caixa: $e');
      throw Exception('Erro ao registrar venda no caixa: $e');
    }
  }

  Future<void> registrarEntrada(
    String caixaId,
    double valor,
    String usuarioId,
    String? descricao,
  ) async {
    try {
      // Verificar se o caixa está aberto
      final caixa = await getCaixa(caixaId);
      if (caixa.isFechado) {
        throw Exception('Não é possível registrar entradas em caixa fechado');
      }

      final movimentacao = CaixaMovimentacaoModel.novo(
        caixaId: caixaId,
        tipo: TipoMovimentacaoCaixa.entrada,
        valor: valor,
        usuarioId: usuarioId,
        descricao: descricao ?? 'Entrada de dinheiro',
        criadoPor: usuarioId,
      );

      await addMovimentacao(movimentacao);
    } catch (e) {
      throw Exception('Erro ao registrar entrada no caixa: $e');
    }
  }

  Future<void> registrarSaida(
    String caixaId,
    double valor,
    String usuarioId,
    String? descricao,
  ) async {
    try {
      // Verificar se o caixa está aberto
      final caixa = await getCaixa(caixaId);
      if (caixa.isFechado) {
        throw Exception('Não é possível registrar saídas em caixa fechado');
      }

      // Verificar se há saldo suficiente
      final saldoAtual = await calcularSaldoAtual(caixaId);
      if (saldoAtual < valor) {
        throw Exception('Saldo insuficiente para esta saída. Saldo atual: ${saldoAtual.toStringAsFixed(2)}');
      }

      final movimentacao = CaixaMovimentacaoModel.novo(
        caixaId: caixaId,
        tipo: TipoMovimentacaoCaixa.saida,
        valor: valor,
        usuarioId: usuarioId,
        descricao: descricao ?? 'Saída de dinheiro',
        criadoPor: usuarioId,
      );

      await addMovimentacao(movimentacao);
    } catch (e) {
      throw Exception('Erro ao registrar saída no caixa: $e');
    }
  }

  // ==================================
  // CÁLCULOS E RELATÓRIOS
  // ==================================

  Future<double> calcularSaldoAtual(String caixaId) async {
    try {
      final movimentacoes = await getMovimentacoesPorCaixa(caixaId);
      final caixa = await getCaixa(caixaId);

      double saldo = caixa.saldoInicial;

      for (final mov in movimentacoes) {
        if (mov.isEntrada || mov.isVenda) {
          saldo += mov.valor;
        } else if (mov.isSaida) {
          saldo -= mov.valor;
        }
      }

      return saldo;
    } catch (e) {
      throw Exception('Erro ao calcular saldo atual: $e');
    }
  }

  Future<Map<String, double>> calcularResumoCaixa(String caixaId) async {
    try {
      final movimentacoes = await getMovimentacoesPorCaixa(caixaId);

      double totalEntradas = 0;
      double totalSaidas = 0;
      double totalVendas = 0;

      for (final mov in movimentacoes) {
        if (mov.isEntrada) {
          totalEntradas += mov.valor;
        } else if (mov.isSaida) {
          totalSaidas += mov.valor;
        } else if (mov.isVenda) {
          totalVendas += mov.valor;
        }
      }

      return {
        'entradas': totalEntradas,
        'saidas': totalSaidas,
        'vendas': totalVendas,
      };
    } catch (e) {
      throw Exception('Erro ao calcular resumo do caixa: $e');
    }
  }

  /// Calcula o resumo completo para fechamento de caixa
  Future<Map<String, dynamic>> calcularResumoFechamento(String caixaId) async {
    try {
      final caixa = await getCaixa(caixaId);
      final movimentacoes = await getMovimentacoesPorCaixa(caixaId);
      
      double totalEntradas = 0;
      double totalSaidas = 0;
      double totalVendas = 0;
      int totalMovimentacoes = 0;
      int totalItensVendidos = 0;
      int totalVendasRealizadas = 0;

      // Calcular totais das movimentações
      for (final mov in movimentacoes) {
        totalMovimentacoes++;
        if (mov.isEntrada) {
          totalEntradas += mov.valor;
        } else if (mov.isSaida) {
          totalSaidas += mov.valor;
        } else if (mov.isVenda) {
          totalVendas += mov.valor;
          totalVendasRealizadas++;
        }
      }

      // Calcular total de itens vendidos
      try {
        final vendasIds = movimentacoes
            .where((mov) => mov.isVenda && mov.vendaId != null)
            .map((mov) => mov.vendaId!)
            .toSet()
            .toList();

        if (vendasIds.isNotEmpty) {
          final itensResponse = await _supabaseService.client
              .from('itens_venda')
              .select('quantidade')
              .in_('venda_id', vendasIds);

          for (final item in itensResponse as List<dynamic>) {
            totalItensVendidos += (item['quantidade'] as int?) ?? 0;
          }
        }
      } catch (e) {
        print('⚠️ [CaixaService] Erro ao calcular itens vendidos: $e');
        // Não falhar o cálculo por erro nos itens
      }

      // Calcular resumo por forma de pagamento
      Map<String, double> resumoPorFormaPagamento = {};
      try {
        final vendasIds = movimentacoes
            .where((mov) => mov.isVenda && mov.vendaId != null)
            .map((mov) => mov.vendaId!)
            .toSet()
            .toList();

        if (vendasIds.isNotEmpty) {
          final pagamentosResponse = await _supabaseService.client
              .from('pagamentos_venda')
              .select('''
                valor_pago,
                forma_pagamento_id,
                formas_pagamento(nome)
              ''')
              .in_('venda_id', vendasIds);

          for (final pagamento in pagamentosResponse as List<dynamic>) {
            final formaPagamentoId = pagamento['forma_pagamento_id'] as String?;
            final valorPago = (pagamento['valor_pago'] as num?)?.toDouble() ?? 0.0;
            final formaPagamentoNome = pagamento['formas_pagamento']?['nome'] as String? ?? 'Forma não encontrada';
            
            if (formaPagamentoId != null && valorPago > 0) {
              resumoPorFormaPagamento[formaPagamentoNome] = 
                  (resumoPorFormaPagamento[formaPagamentoNome] ?? 0) + valorPago;
            }
          }
        }
      } catch (e) {
        print('⚠️ [CaixaService] Erro ao calcular resumo por forma de pagamento: $e');
        // Não falhar o cálculo por erro nos pagamentos
      }

      final saldoFinal = caixa.saldoInicial + totalEntradas - totalSaidas + totalVendas;
      final diferenca = saldoFinal - caixa.saldoInicial;

      return {
        'saldo_inicial': caixa.saldoInicial,
        'total_entradas': totalEntradas,
        'total_saidas': totalSaidas,
        'total_vendas': totalVendas,
        'total_vendas_realizadas': totalVendasRealizadas,
        'total_itens_vendidos': totalItensVendidos,
        'saldo_final_calculado': saldoFinal,
        'diferenca': diferenca,
        'total_movimentacoes': totalMovimentacoes,
        'data_abertura': caixa.dataAbertura,
        'tempo_aberto': DateTime.now().difference(caixa.dataAbertura),
        'resumo_por_forma_pagamento': resumoPorFormaPagamento,
      };
    } catch (e) {
      throw Exception('Erro ao calcular resumo de fechamento: $e');
    }
  }
}
