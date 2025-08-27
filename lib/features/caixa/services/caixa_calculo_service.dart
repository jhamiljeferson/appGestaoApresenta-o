import '../models/caixa_model.dart';
import '../models/caixa_movimentacao_model.dart';
import '../../../core/services/supabase_service.dart';

class CaixaCalculoService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Cache interno para evitar consultas repetidas
  final Map<String, Map<String, dynamic>> _cacheSaldoDetalhado = {};

  /// Calcula o saldo atual do caixa considerando formas de pagamento
  /// OTIMIZADO: Consultas paralelas e cache interno
  Future<Map<String, dynamic>> calcularSaldoDetalhado(String caixaId) async {
    try {
      // Verificar cache primeiro
      if (_cacheSaldoDetalhado.containsKey(caixaId)) {
        return _cacheSaldoDetalhado[caixaId]!;
      }

      // Buscar todos os dados em paralelo para máxima performance
      final futures = await Future.wait([
        _getCaixa(caixaId),
        _getMovimentacoes(caixaId),
        _getVendasComPagamentos(caixaId),
      ]);

      final caixa = futures[0] as CaixaModel?;
      final movimentacoes = futures[1] as List<CaixaMovimentacaoModel>;
      final vendasComPagamentos = futures[2] as List<Map<String, dynamic>>;

      if (caixa == null) {
        throw Exception('Caixa não encontrado');
      }

      // Calcular por tipo de movimentação
      double totalEntradas = 0;
      double totalSaidas = 0;
      double totalVendas = 0;

      for (final mov in movimentacoes) {
        if (mov.isEntrada) {
          totalEntradas += mov.valor;
        } else if (mov.isSaida) {
          totalSaidas += mov.valor;
        }
      }

      // Calcular por forma de pagamento
      Map<String, double> formasPagamento = {};
      double totalDinheiro = 0;
      double totalCartao = 0;
      double totalPix = 0;
      double totalOutros = 0;
      int totalItensVendidos = 0;

      for (final venda in vendasComPagamentos) {
        totalVendas += venda['valor_total'];
        totalItensVendidos += (venda['total_itens'] ?? 0) as int;

        for (final pagamento in venda['pagamentos']) {
          final formaPagamentoId = pagamento['forma_pagamento_id'];
          final formaPagamentoNome = pagamento['forma_pagamento_nome'];
          final valor = pagamento['valor_pago'];

          // Agrupar por ID da forma de pagamento (mesma lógica da movimentação)
          formasPagamento[formaPagamentoId] =
              (formasPagamento[formaPagamentoId] ?? 0) + valor;

          // Categorizar por tipo para cálculos internos
          if (formaPagamentoNome.toLowerCase().contains('dinheiro') ||
              formaPagamentoNome.toLowerCase().contains('espécie') ||
              formaPagamentoNome.toLowerCase().contains('especie')) {
            totalDinheiro += valor;
          } else if (formaPagamentoNome.toLowerCase().contains('cartão') ||
              formaPagamentoNome.toLowerCase().contains('cartao')) {
            totalCartao += valor;
          } else if (formaPagamentoNome.toLowerCase().contains('pix')) {
            totalPix += valor;
          } else {
            totalOutros += valor;
          }
        }
      }

      // Calcular saldo atual (apenas dinheiro físico)
      double saldoAtual =
          caixa.saldoInicial + totalEntradas - totalSaidas + totalDinheiro;

      final resultado = {
        'saldo_inicial': caixa.saldoInicial,
        'saldo_atual': saldoAtual,
        'saldo_fisico': saldoAtual, // Apenas dinheiro em espécie
        'total_entradas': totalEntradas,
        'total_saidas': totalSaidas,
        'total_vendas': totalVendas,
        'total_itens_vendidos': totalItensVendidos,
        'formas_pagamento': formasPagamento, // Por ID (mesma lógica da movimentação)
        'resumo_formas': {
          'dinheiro': totalDinheiro,
          'cartao': totalCartao,
          'pix': totalPix,
          'outros': totalOutros,
        },
        'movimentacoes_count': movimentacoes.length,
        'vendas_count': vendasComPagamentos.length,
        'ultima_atualizacao': DateTime.now(),
        'caixa_info': {
          'id': caixa.id,
          'loja_id': caixa.lojaId,
          'data_abertura': caixa.dataAbertura,
          'status': caixa.status.name,
        },
      };

      // Armazenar no cache
      _cacheSaldoDetalhado[caixaId] = resultado;
      
      return resultado;
    } catch (e) {
      throw Exception('Erro ao calcular saldo detalhado: $e');
    }
  }



  /// Limpa o cache para um caixa específico
  void limparCache(String caixaId) {
    _cacheSaldoDetalhado.remove(caixaId);
  }

  /// Limpa todo o cache
  void limparCacheCompleto() {
    _cacheSaldoDetalhado.clear();
  }



  // Métodos auxiliares OTIMIZADOS
  Future<CaixaModel?> _getCaixa(String caixaId) async {
    try {
      final response = await _supabaseService.client
          .from('caixa')
          .select()
          .eq('id', caixaId)
          .single();
      return CaixaModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<CaixaMovimentacaoModel>> _getMovimentacoes(String caixaId) async {
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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getVendasComPagamentos(
    String caixaId,
  ) async {
    try {
      // OTIMIZAÇÃO: Consulta única com JOIN para buscar vendas e pagamentos
      final vendasResponse = await _supabaseService.client
          .from('caixa_movimentacao')
          .select('''
            venda_id,
            vendas!inner(
              id,
              valor_total,
              pagamentos_venda(
                id,
                valor_pago,
                forma_pagamento_id,
                formas_pagamento(nome)
              ),
              itens_venda(quantidade)
            )
          ''')
          .eq('caixa_id', caixaId)
          .eq('tipo', TipoMovimentacaoCaixa.venda.name)
          .not('venda_id', 'is', null);

      if (vendasResponse == null || vendasResponse.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> vendasComPagamentos = [];

      for (final movimentacao in vendasResponse) {
        final venda = movimentacao['vendas'];
        if (venda == null) continue;

        List<Map<String, dynamic>> pagamentos = [];
        
        if (venda['pagamentos_venda'] != null) {
          for (final pag in venda['pagamentos_venda']) {
            pagamentos.add({
              'id': pag['id'],
              'valor_pago': pag['valor_pago'],
              'forma_pagamento_id': pag['forma_pagamento_id'],
              'forma_pagamento_nome': pag['formas_pagamento']['nome'],
            });
          }
        }

        // Calcular total de itens da venda
        int totalItens = 0;
        if (venda['itens_venda'] != null) {
          for (final item in venda['itens_venda']) {
            totalItens += (item['quantidade'] ?? 0) as int;
          }
        }

        vendasComPagamentos.add({
          'id': venda['id'],
          'valor_total': venda['valor_total'],
          'total_itens': totalItens,
          'pagamentos': pagamentos,
        });
      }

      return vendasComPagamentos;
    } catch (e) {
      return [];
    }
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }

  /// Calcula operações por hora
  double _calcularOperacoesPorHora(DateTime dataAbertura) {
    final agora = DateTime.now();
    final duracao = agora.difference(dataAbertura);
    final horas = duracao.inHours > 0 ? duracao.inHours : 1;
    return horas.toDouble();
  }

  /// Calcula tempo que o caixa está aberto
  String _calcularTempoAberto(DateTime dataAbertura) {
    final agora = DateTime.now();
    final duracao = agora.difference(dataAbertura);

    if (duracao.inDays > 0) {
      return '${duracao.inDays}d ${duracao.inHours % 24}h ${duracao.inMinutes % 60}m';
    } else if (duracao.inHours > 0) {
      return '${duracao.inHours}h ${duracao.inMinutes % 60}m';
    } else {
      return '${duracao.inMinutes}m';
    }
  }
}
