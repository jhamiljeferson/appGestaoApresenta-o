import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/caixa_model.dart';
import '../controllers/caixa_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../features/lojas/providers/loja_ativa_provider.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/utils/formatters.dart';

class CaixaFechamentoView extends ConsumerStatefulWidget {
  final String caixaId;
  
  const CaixaFechamentoView({
    super.key,
    required this.caixaId,
  });

  @override
  ConsumerState<CaixaFechamentoView> createState() => _CaixaFechamentoViewState();
}

class _CaixaFechamentoViewState extends ConsumerState<CaixaFechamentoView> {
  bool isLoading = false;
  CaixaModel? caixa;
  Map<String, dynamic>? resumoFechamento;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  Future<void> _carregarDados() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Carregar dados do caixa
      final caixaData = await ref.read(caixaServiceProvider).getCaixa(widget.caixaId);
      final resumo = await ref.read(caixaServiceProvider).calcularResumoFechamento(widget.caixaId);
      
      setState(() {
        caixa = caixaData;
        resumoFechamento = resumo;
      });
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao carregar dados: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fecharCaixa() async {
    if (caixa == null || resumoFechamento == null) return;

    final usuarioId = await AuthController.getUsuarioIdLogado();
    if (usuarioId == null) {
      AppFeedback.showError(context, 'Usuário não autenticado');
      return;
    }

    final resultado = await _solicitarConfirmacaoFechamento();
    if (resultado == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await ref.read(caixaProvider.notifier).fecharCaixa(
        widget.caixaId,
        usuarioId,
        saldoFinalManual: resultado['saldoFinal'],
        observacoes: resultado['observacoes'],
      );

      if (mounted) {
        AppFeedback.showSuccess(context, 'Caixa fechado com sucesso!');
        context.go('/caixa');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao fechar caixa: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _solicitarConfirmacaoFechamento() async {
    final saldoController = TextEditingController();
    final observacoesController = TextEditingController();
    
    // Usar saldo calculado como padrão
    if (resumoFechamento != null) {
      saldoController.text = resumoFechamento!['saldo_final_calculado'].toStringAsFixed(2);
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Fechamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirme as informações finais:'),
            const SizedBox(height: 16),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Final',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
                helperText: 'Confirme o valor em caixa',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Informações sobre o fechamento',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final saldoFinal = double.tryParse(saldoController.text);
              if (saldoFinal == null || saldoFinal < 0) {
                AppFeedback.showError(context, 'Saldo final inválido');
                return;
              }
              
              Navigator.of(context).pop({
                'saldoFinal': saldoFinal,
                'observacoes': observacoesController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Fechamento'),
          ),
        ],
      ),
    );
  }

  String _formatarTempo(Duration duracao) {
    if (duracao.inDays > 0) {
      return '${duracao.inDays}d ${duracao.inHours % 24}h ${duracao.inMinutes % 60}m';
    } else if (duracao.inHours > 0) {
      return '${duracao.inHours}h ${duracao.inMinutes % 60}m';
    } else {
      return '${duracao.inMinutes}m';
    }
  }

  Widget _buildCalculationRow(String label, String value, Color color, IconData icon, {bool isPositive = false}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MainLayout(
        title: 'Fechamento de Caixa',
        breadcrumbs: [
          BreadcrumbItem('Dashboard'),
          BreadcrumbItem('Caixa'),
          BreadcrumbItem('Fechamento'),
        ],
        currentRoute: '/caixa',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (caixa == null || resumoFechamento == null) {
      return MainLayout(
        title: 'Fechamento de Caixa',
        breadcrumbs: const [
          BreadcrumbItem('Dashboard'),
          BreadcrumbItem('Caixa'),
          BreadcrumbItem('Fechamento'),
        ],
        currentRoute: '/caixa',
        child: const Center(child: Text('Dados não encontrados')),
      );
    }

    return MainLayout(
      title: '🔒 Fechamento de Caixa',
      breadcrumbs: const [
        BreadcrumbItem('Dashboard'),
        BreadcrumbItem('Caixa'),
        BreadcrumbItem('Fechamento'),
      ],
      currentRoute: '/caixa',
      onSidebarItemSelected: (route) => context.go(route),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações do caixa
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Caixa #${caixa!.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          'ABERTO',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data de Abertura',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatDate(caixa!.dataAbertura),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tempo Aberto',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatarTempo(resumoFechamento!['tempo_aberto']),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Inicial',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatCurrency(caixa!.saldoInicial),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Resumo financeiro
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Resumo Financeiro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Informações de vendas
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resumo de Vendas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total de Vendas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  Text(
                                    '${resumoFechamento!['total_vendas_realizadas']} vendas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Itens Vendidos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  Text(
                                    '${resumoFechamento!['total_itens_vendidos']} peças',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  Text(
                                    formatCurrency(resumoFechamento!['total_vendas']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Breakdown detalhado dos cálculos
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calculate,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Como Chegou ao Valor Final',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Saldo inicial
                        _buildCalculationRow(
                          'Saldo Inicial',
                          formatCurrency(resumoFechamento!['saldo_inicial']),
                          Colors.green,
                          Icons.account_balance_wallet,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Entradas
                        if (resumoFechamento!['total_entradas'] > 0)
                          _buildCalculationRow(
                            '+ Entradas',
                            formatCurrency(resumoFechamento!['total_entradas']),
                            Colors.green,
                            Icons.add_circle,
                            isPositive: true,
                          ),
                        
                        // Vendas
                        if (resumoFechamento!['total_vendas'] > 0)
                          _buildCalculationRow(
                            '+ Vendas',
                            formatCurrency(resumoFechamento!['total_vendas']),
                            Colors.blue,
                            Icons.shopping_cart,
                            isPositive: true,
                          ),
                        
                        // Saídas
                        if (resumoFechamento!['total_saidas'] > 0)
                          _buildCalculationRow(
                            '- Saídas',
                            formatCurrency(resumoFechamento!['total_saidas']),
                            Colors.red,
                            Icons.remove_circle,
                            isPositive: false,
                          ),
                        
                        const Divider(height: 24),
                        
                        // Saldo final calculado
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calculate,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo Final Calculado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(resumoFechamento!['saldo_final_calculado']),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${resumoFechamento!['total_movimentacoes']} mov.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Diferencial
                        if (resumoFechamento!['diferenca'] != 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (resumoFechamento!['diferenca'] > 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (resumoFechamento!['diferenca'] > 0 ? Colors.green : Colors.red).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  resumoFechamento!['diferenca'] > 0 ? Icons.trending_up : Icons.trending_down,
                                  color: resumoFechamento!['diferenca'] > 0 ? Colors.green[700] : Colors.red[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  resumoFechamento!['diferenca'] > 0 
                                    ? 'Lucro: ${formatCurrency(resumoFechamento!['diferenca'])}'
                                    : 'Prejuízo: ${formatCurrency(resumoFechamento!['diferenca'].abs())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: resumoFechamento!['diferenca'] > 0 ? Colors.green[700] : Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Entradas',
                          formatCurrency(resumoFechamento!['total_entradas']),
                          Icons.add_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Saídas',
                          formatCurrency(resumoFechamento!['total_saidas']),
                          Icons.remove_circle,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Vendas',
                          formatCurrency(resumoFechamento!['total_vendas']),
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Resumo por forma de pagamento
            if (resumoFechamento!['resumo_por_forma_pagamento'] != null &&
                (resumoFechamento!['resumo_por_forma_pagamento'] as Map<String, dynamic>).isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Formas de Pagamento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Lista de formas de pagamento
                    ...(resumoFechamento!['resumo_por_forma_pagamento'] as Map<String, dynamic>)
                        .entries
                        .map((entry) => _buildFormaPagamentoRow(entry.key, entry.value))
                        .toList(),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Botão de fechamento
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Confirmar Fechamento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⚠️ Atenção: Esta ação não pode ser desfeita. O caixa será fechado e não será possível registrar novas movimentações.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/caixa'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Sair'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[400]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _fecharCaixa,
                          icon: const Icon(Icons.close),
                          label: const Text('Fechar Caixa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String titulo, String valor, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: cor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: cor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFormaPagamentoRow(String formaPagamento, dynamic valor) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_getPaymentIcon(formaPagamento), color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formaPagamento,
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatCurrency(valor),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
        ],
      ),
    );
  }

  // Função para obter ícone baseado no nome da forma de pagamento
  IconData _getPaymentIcon(String formaPagamento) {
    final nome = formaPagamento.toLowerCase();
    
    if (nome.contains('dinheiro') || nome.contains('dinheiro')) {
      return Icons.money;
    } else if (nome.contains('cartão') || nome.contains('card') || nome.contains('credito') || nome.contains('debito')) {
      return Icons.credit_card;
    } else if (nome.contains('pix')) {
      return Icons.qr_code;
    } else if (nome.contains('transferência') || nome.contains('transferencia')) {
      return Icons.account_balance;
    } else if (nome.contains('boleto')) {
      return Icons.receipt;
    } else if (nome.contains('cheque')) {
      return Icons.description;
    } else {
      return Icons.payment;
    }
  }
}
