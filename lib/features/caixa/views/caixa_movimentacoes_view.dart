import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/caixa_model.dart';
import '../models/caixa_movimentacao_model.dart';
import '../controllers/caixa_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';

import '../../../features/lojas/providers/loja_ativa_provider.dart';
import '../../../features/lojas/controllers/loja_controller.dart';
import '../../../features/lojas/models/loja_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/usuario/controllers/usuario_controller.dart';
import '../../../core/utils/formatters.dart';
import '../providers/caixa_vendas_provider.dart';
import '../../../features/forma_pagamento/providers/forma_pagamento_provider.dart';


class CaixaMovimentacoesView extends ConsumerStatefulWidget {
  const CaixaMovimentacoesView({super.key});

  @override
  ConsumerState<CaixaMovimentacoesView> createState() =>
      _CaixaMovimentacoesViewState();
}

class _CaixaMovimentacoesViewState
    extends ConsumerState<CaixaMovimentacoesView> {
  CaixaModel? caixaAtivo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCaixaAtivo();
    });
  }

  Future<void> _carregarCaixaAtivo() async {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
      try {
        final caixa = await ref
            .read(caixaProvider.notifier)
            .getCaixaAbertoPorLoja(lojaAtiva);
        setState(() {
          caixaAtivo = caixa;
        });
      } catch (e) {
        // Ignorar erro, pode não haver caixa aberto
      }
    }
  }

  /// Recarrega todos os dados da tela após alterações
  Future<void> _recarregarDadosTela() async {
    try {
      // Preservar referência do caixa atual
      final caixaAtual = caixaAtivo;

      // Mostrar indicador de carregamento
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      // Invalidar providers para forçar recarregamento, mas manter o caixa
      if (caixaAtual != null) {
        ref.invalidate(movimentacoesCaixaProvider(caixaAtual.id));
        ref.invalidate(saldoAtualProvider(caixaAtual.id));
        ref.invalidate(resumoCaixaProvider(caixaAtual.id));

        // Recarregar apenas os dados do caixa atual, sem buscar novamente
        try {
          final caixaAtualizado = await ref
              .read(caixaServiceProvider)
              .getCaixa(caixaAtual.id);

          if (mounted) {
            setState(() {
              caixaAtivo = caixaAtualizado;
            });
          }
        } catch (e) {
          // Se não conseguir buscar o caixa específico, manter o atual
          debugPrint('⚠️ [CaixaMovimentacoesView] Mantendo caixa atual: $e');
        }
      }

      // Pequeno delay para garantir que os dados sejam atualizados
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Log de erro (remover em produção)
      debugPrint('❌ [CaixaMovimentacoesView] Erro ao recarregar dados: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _registrarEntrada() async {
    if (caixaAtivo == null) {
      if (mounted) {
        AppFeedback.showError(context, 'Não há caixa aberto');
      }
      return;
    }

    // IMPORTANTE: Usar ID do usuário, não do cargo
    final usuarioId = await AuthController.getUsuarioIdLogado();
    if (usuarioId == null) {
      if (mounted) {
        AppFeedback.showError(context, 'Usuário não autenticado');
      }
      return;
    }

    final resultado = await _mostrarDialogMovimentacao(
      'Registrar Entrada',
      TipoMovimentacaoCaixa.entrada,
    );

    if (resultado != null) {
      setState(() {
        isLoading = true;
      });

      try {
        await ref
            .read(caixaProvider.notifier)
            .registrarEntrada(
              caixaAtivo!.id,
              resultado['valor'],
              usuarioId,
              resultado['descricao'],
            );

        if (mounted) {
          AppFeedback.showSuccess(context, 'Entrada registrada com sucesso!');

          // Recarregar dados da tela após entrada
          await _recarregarDadosTela();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Erro ao registrar entrada: $e');
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _registrarSaida() async {
    if (caixaAtivo == null) {
      if (mounted) {
        AppFeedback.showError(context, 'Não há caixa aberto');
      }
      return;
    }

    // IMPORTANTE: Usar ID do usuário, não do cargo
    final usuarioId = await AuthController.getUsuarioIdLogado();
    if (usuarioId == null) {
      if (mounted) {
        AppFeedback.showError(context, 'Usuário não autenticado');
      }
      return;
    }

    final resultado = await _mostrarDialogMovimentacao(
      'Registrar Saída',
      TipoMovimentacaoCaixa.saida,
    );

    if (resultado != null) {
      setState(() {
        isLoading = true;
      });

      try {
        await ref
            .read(caixaProvider.notifier)
            .registrarSaida(
              caixaAtivo!.id,
              resultado['valor'],
              usuarioId,
              resultado['descricao'],
            );

        if (mounted) {
          AppFeedback.showSuccess(context, 'Saída registrada com sucesso!');

          // Recarregar dados da tela após saída
          await _recarregarDadosTela();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Erro ao registrar saída: $e');
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildResumoItem(
    String label,
    String valor,
    IconData icone,
    Color cor,
    bool isTinyScreen,
    bool isNarrowScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isTinyScreen ? 8 : isNarrowScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTinyScreen ? 6 : 8),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            color: cor,
            size: isTinyScreen ? 18 : isNarrowScreen ? 20 : 22,
          ),
          SizedBox(height: isTinyScreen ? 4 : isNarrowScreen ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isTinyScreen ? 11 : isNarrowScreen ? 12 : 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTinyScreen ? 2 : isNarrowScreen ? 3 : 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: isTinyScreen ? 13 : isNarrowScreen ? 14 : 15,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }





  Future<Map<String, dynamic>?> _mostrarDialogMovimentacao(
    String titulo,
    TipoMovimentacaoCaixa tipo,
  ) async {
    final valorController = TextEditingController();
    final descricaoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                tipo == TipoMovimentacaoCaixa.entrada
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color: tipo == TipoMovimentacaoCaixa.entrada
                    ? Colors.green[600]
                    : Colors.red[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: tipo == TipoMovimentacaoCaixa.entrada
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de valor com validação
                  TextFormField(
                    controller: valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Valor (R\$)',
                      hintText: '0,00',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: Text(
                          'R\$',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tipo == TipoMovimentacaoCaixa.entrada
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: tipo == TipoMovimentacaoCaixa.entrada
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: tipo == TipoMovimentacaoCaixa.entrada
                              ? Colors.green[500]!
                              : Colors.red[500]!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o valor';
                      }
                      final valor = double.tryParse(value.replaceAll(',', '.'));
                      if (valor == null || valor <= 0) {
                        return 'Digite um valor válido maior que zero';
                      }
                      if (valor > 999999.99) {
                        return 'Valor muito alto';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Formatação automática do valor
                      if (value.isNotEmpty) {
                        final cleanValue = value.replaceAll(
                          RegExp(r'[^\d,.]'),
                          '',
                        );
                        if (cleanValue != value) {
                          valorController.value = TextEditingValue(
                            text: cleanValue,
                            selection: TextSelection.collapsed(
                              offset: cleanValue.length,
                            ),
                          );
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo de descrição
                  TextFormField(
                    controller: descricaoController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descrição da movimentação',
                      hintText: tipo == TipoMovimentacaoCaixa.entrada
                          ? 'Ex: Depósito, pagamento recebido, troco...'
                          : 'Ex: Pagamento de fornecedor, saque, despesa...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue[500]!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite uma descrição';
                      }
                      if (value.trim().length < 3) {
                        return 'Descrição muito curta';
                      }
                      if (value.trim().length > 200) {
                        return 'Descrição muito longa (máx. 200 caracteres)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Dica visual
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tipo == TipoMovimentacaoCaixa.entrada
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tipo == TipoMovimentacaoCaixa.entrada
                            ? Colors.green[200]!
                            : Colors.red[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tipo == TipoMovimentacaoCaixa.entrada
                              ? Icons.info_outline
                              : Icons.warning_amber_outlined,
                          color: tipo == TipoMovimentacaoCaixa.entrada
                              ? Colors.green[600]
                              : Colors.red[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tipo == TipoMovimentacaoCaixa.entrada
                                ? 'Esta entrada será adicionada ao saldo do caixa'
                                : 'Esta saída será descontada do saldo do caixa',
                            style: TextStyle(
                              fontSize: 13,
                              color: tipo == TipoMovimentacaoCaixa.entrada
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Botão Cancelar
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(width: 8),

            // Botão Confirmar
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        try {
                          final valor = double.parse(
                            valorController.text.replaceAll(',', '.'),
                          );

                          if (valor <= 0) {
                            AppFeedback.showError(
                              context,
                              'Valor deve ser maior que zero',
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          Navigator.of(context).pop({
                            'valor': valor,
                            'descricao': descricaoController.text.trim(),
                          });
                        } catch (e) {
                          AppFeedback.showError(context, 'Valor inválido');
                          setState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: tipo == TipoMovimentacaoCaixa.entrada
                    ? Colors.green[600]
                    : Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tipo == TipoMovimentacaoCaixa.entrada
                              ? Icons.check_circle
                              : Icons.remove_circle,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTipoColor(TipoMovimentacaoCaixa tipo) {
    switch (tipo) {
      case TipoMovimentacaoCaixa.entrada:
        return Colors.green;
      case TipoMovimentacaoCaixa.saida:
        return Colors.red;
      case TipoMovimentacaoCaixa.venda:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lojaAtiva = ref.watch(lojaAtivaProvider);
    final lojasAsync = ref.watch(lojaProvider);

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Movimentações do Caixa',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Caixa'),
              BreadcrumbItem('Movimentações'),
            ],
            currentRoute: '/caixa/movimentacoes',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final scaffoldContext = context;
            return MainLayout(
              title: '💰 Movimentações do Caixa',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Caixa'),
                BreadcrumbItem('Movimentações'),
              ],
              currentRoute: '/caixa/movimentacoes',
              onSidebarItemSelected: (route) => scaffoldContext.go(route),
              actions: [
                // Botão de atualizar
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar',
                  onPressed: () {
                    ref.invalidate(movimentacoesCaixaProvider);
                    ref.invalidate(saldoAtualProvider);
                    ref.invalidate(resumoCaixaProvider);
                    AppFeedback.showSuccess(context, 'Dados atualizados!');
                  },
                ),
              ],
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com loja ativa
                    if (lojaAtiva != null && lojaAtiva.isNotEmpty)
                      lojasAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (lojas) {
                          final loja = lojas.firstWhere(
                            (l) => l.id == lojaAtiva,
                            orElse: () => LojaModel(
                              id: '',
                              nome: 'Loja não encontrada',
                              shopping: '',
                              andar: '',
                              numero: '',
                            ),
                          );
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.store, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Movimentações do Caixa',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Loja: ${loja.nome}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botão de voltar rápido no header
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/caixa'),
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text('Voltar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                    side: BorderSide(color: Colors.blue[300]!),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Status do caixa e resumo
                    if (caixaAtivo?.isAberto == true) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Caixa Aberto',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                // Botão de voltar ao caixa
                                TextButton.icon(
                                  onPressed: () => context.go('/caixa'),
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('Ver Caixa'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Consumer(
                              builder: (context, ref, child) {
                                final saldoAtualAsync = ref.watch(
                                  saldoAtualProvider(caixaAtivo!.id),
                                );
                                final resumoAsync = ref.watch(
                                  resumoCaixaProvider(caixaAtivo!.id),
                                );

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 600) {
                                      // Layout horizontal para telas maiores
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: saldoAtualAsync.when(
                                              loading: () => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              error: (e, _) => Text('Erro: $e'),
                                              data: (saldo) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Saldo Atual',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    formatCurrency(saldo),
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: saldo >= 0
                                                          ? Colors.green[700]
                                                          : Colors.red[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: resumoAsync.when(
                                              loading: () => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              error: (e, _) => Text('Erro: $e'),
                                              data: (resumo) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total Vendas',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    formatCurrency(
                                                      resumo['vendas'] ?? 0,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: resumoAsync.when(
                                              loading: () => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              error: (e, _) => Text('Erro: $e'),
                                              data: (resumo) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total Entradas',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    formatCurrency(
                                                      resumo['entradas'] ?? 0,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: resumoAsync.when(
                                              loading: () => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              error: (e, _) => Text('Erro: $e'),
                                              data: (resumo) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total Saídas',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    formatCurrency(
                                                      resumo['saidas'] ?? 0,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Layout vertical para telas menores
                                      return Column(
                                        children: [
                                          saldoAtualAsync.when(
                                            loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                            error: (e, _) => Text('Erro: $e'),
                                            data: (saldo) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Saldo Atual',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  formatCurrency(saldo),
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: saldo >= 0
                                                        ? Colors.green[700]
                                                        : Colors.red[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Grid de 3 colunas para telas menores
                                          Row(
                                            children: [
                                              Expanded(
                                                child: resumoAsync.when(
                                                  loading: () => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                  error: (e, _) =>
                                                      Text('Erro: $e'),
                                                  data: (resumo) => Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Total Vendas',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        formatCurrency(
                                                          resumo['vendas'] ?? 0,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: resumoAsync.when(
                                                  loading: () => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                  error: (e, _) =>
                                                      Text('Erro: $e'),
                                                  data: (resumo) => Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Total Entradas',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        formatCurrency(
                                                          resumo['entradas'] ??
                                                              0,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: resumoAsync.when(
                                                  loading: () => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                  error: (e, _) =>
                                                      Text('Erro: $e'),
                                                  data: (resumo) => Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Total Saídas',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        formatCurrency(
                                                          resumo['saidas'] ?? 0,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.red[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Seção de Formas de Pagamento das Vendas
                      if (caixaAtivo?.isAberto == true)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.payment,
                                      color: Colors.purple[700],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Formas de Pagamento',
                                          style: TextStyle(
                                            color: Colors.purple[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          'Resumo das vendas por método de pagamento',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Consumer(
                                builder: (context, ref, child) {
                                  final resumoPagamentosAsync = ref.watch(
                                    resumoPagamentosPorFormaProvider(caixaAtivo!.id),
                                  );
                                  final formasPagamentoAsync = ref.watch(
                                    formasPagamentoProvider,
                                  );

                                  return resumoPagamentosAsync.when(
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (e, _) => Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Erro ao carregar pagamentos: $e',
                                              style: TextStyle(color: Colors.red[700], fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    data: (resumoPagamentos) {
                                      // Verificar se resumoPagamentos é um Map válido
                                      if (resumoPagamentos is! Map<String, double>) {
                                        debugPrint('⚠️ [CaixaMovimentacoesView] resumoPagamentos não é um Map válido: ${resumoPagamentos.runtimeType}');
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Erro: Dados de pagamentos em formato inválido',
                                                  style: TextStyle(color: Colors.red[700], fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      if (resumoPagamentos.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.shopping_cart_outlined,
                                                color: Colors.blue[600],
                                                size: 48,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Nenhuma venda registrada',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'As vendas aparecerão aqui quando forem realizadas',
                                                style: TextStyle(
                                                  color: Colors.blue[600],
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return formasPagamentoAsync.when(
                                        loading: () => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        error: (e, _) => Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Erro ao carregar formas de pagamento: $e',
                                                  style: TextStyle(color: Colors.red[700], fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        data: (formasPagamento) {
                                          // Criar mapa de formas de pagamento por ID
                                          final formasPorId = {
                                            for (var forma in formasPagamento)
                                              forma.id: forma.nome
                                          };

                                          // Calcular total geral
                                          final totalGeral = resumoPagamentos.values.fold(0.0, (sum, valor) => sum + valor);

                                          return Column(
                                            children: [
                                              // Card de resumo geral
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.attach_money,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Total Geral',
                                                            style: TextStyle(
                                                              color: Colors.white.withValues(alpha: 0.9),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          Text(
                                                            formatCurrency(totalGeral),
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 20,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${resumoPagamentos.length} formas',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              
                                              // Lista de formas de pagamento
                                              ...(resumoPagamentos.entries as Iterable<MapEntry<String, dynamic>>).map((entry) {
                                                final formaPagamentoId = entry.key;
                                                final valorTotal = entry.value;
                                                final nomeForma = formasPorId[formaPagamentoId] ?? 'Forma não encontrada';
                                                final percentual = totalGeral > 0 ? (valorTotal / totalGeral * 100) : 0.0;

                                                // Definir ícone e cor baseado no nome da forma de pagamento
                                                IconData iconData;
                                                Color iconColor;
                                                
                                                if (nomeForma.toLowerCase().contains('dinheiro') || 
                                                    nomeForma.toLowerCase().contains('dinheiro')) {
                                                  iconData = Icons.attach_money;
                                                  iconColor = Colors.green[700]!;
                                                } else if (nomeForma.toLowerCase().contains('pix')) {
                                                  iconData = Icons.qr_code;
                                                  iconColor = Colors.blue[700]!;
                                                } else if (nomeForma.toLowerCase().contains('cartão') || 
                                                         nomeForma.toLowerCase().contains('cartao') ||
                                                         nomeForma.toLowerCase().contains('crédito') ||
                                                         nomeForma.toLowerCase().contains('credito')) {
                                                  iconData = Icons.credit_card;
                                                  iconColor = Colors.orange[700]!;
                                                } else if (nomeForma.toLowerCase().contains('débito') || 
                                                         nomeForma.toLowerCase().contains('debito')) {
                                                  iconData = Icons.credit_card_outlined;
                                                  iconColor = Colors.red[700]!;
                                                } else {
                                                  iconData = Icons.payment;
                                                  iconColor = Colors.purple[700]!;
                                                }

                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.grey[200]!,
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey.withValues(alpha: 0.1),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: iconColor.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Icon(
                                                          iconData,
                                                          color: iconColor,
                                                          size: 24,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              nomeForma,
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 16,
                                                                color: Colors.grey[800],
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  width: 60,
                                                                  height: 4,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.grey[300],
                                                                    borderRadius: BorderRadius.circular(2),
                                                                  ),
                                                                  child: FractionallySizedBox(
                                                                    alignment: Alignment.centerLeft,
                                                                    widthFactor: percentual / 100,
                                                                    child: Container(
                                                                      decoration: BoxDecoration(
                                                                        color: iconColor,
                                                                        borderRadius: BorderRadius.circular(2),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  '${percentual.toStringAsFixed(1)}%',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey[600],
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(
                                                            formatCurrency(valorTotal),
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 18,
                                                              color: Colors.grey[800],
                                                            ),
                                                          ),
                                                          Text(
                                                            '${resumoPagamentos.length > 1 ? '${percentual.toStringAsFixed(1)}%' : '100%'} do total',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey[500],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),


                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.red[700],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [


                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),


                              Consumer(
                                builder: (context, ref, child) {
                                  final saldoAtualAsync = ref.watch(
                                    saldoAtualProvider(caixaAtivo!.id),
                                  );
                                  final resumoAsync = ref.watch(
                                    resumoCaixaProvider(caixaAtivo!.id),
                                  );

                                  return Column(
                                    children: [
                                      // Card de saldo atual
                                      saldoAtualAsync.when(
                                        loading: () => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        error: (e, _) => Text('Erro: $e'),
                                        data: (saldoAtual) => Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.account_balance_wallet,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [

                                                    Text(
                                                      formatCurrency(saldoAtual),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Resumo detalhado
                                      resumoAsync.when(
                                        loading: () => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        error: (e, _) => Text('Erro: $e'),
                                        data: (resumo) => Column(
                                          children: [
                                            // Grid responsivo para telas pequenas
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                final isNarrowScreen = constraints.maxWidth >= 350 && constraints.maxWidth < 400;
                                                final isTinyScreen = constraints.maxWidth < 350;

                                                if (isNarrowScreen || isTinyScreen) {
                                                  // Layout vertical para telas pequenas
                                                  return Column(
                                                    children: [
                                                      _buildResumoItem(
                                                        'Saldo Inicial',
                                                        formatCurrency(caixaAtivo!.saldoInicial),
                                                        Icons.account_balance,
                                                        Colors.blue[600]!,
                                                        isTinyScreen,
                                                        isNarrowScreen,
                                                      ),
                                                      SizedBox(height: isTinyScreen ? 8 : 12),
                                                      _buildResumoItem(
                                                        'Total Vendas',
                                                        formatCurrency(resumo['vendas'] ?? 0),
                                                        Icons.shopping_cart,
                                                        Colors.purple[600]!,
                                                        isTinyScreen,
                                                        isNarrowScreen,
                                                      ),
                                                      SizedBox(height: isTinyScreen ? 8 : 12),
                                                      _buildResumoItem(
                                                        'Total Entradas',
                                                        formatCurrency(resumo['entradas'] ?? 0),
                                                        Icons.trending_up,
                                                        Colors.green[600]!,
                                                        isTinyScreen,
                                                        isNarrowScreen,
                                                      ),
                                                      SizedBox(height: isTinyScreen ? 8 : 12),
                                                      _buildResumoItem(
                                                        'Total Saídas',
                                                        formatCurrency(resumo['saidas'] ?? 0),
                                                        Icons.trending_down,
                                                        Colors.red[600]!,
                                                        isTinyScreen,
                                                        isNarrowScreen,
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  // Layout horizontal para telas maiores
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: _buildResumoItem(
                                                          'Saldo Inicial',
                                                          formatCurrency(caixaAtivo!.saldoInicial),
                                                          Icons.account_balance,
                                                          Colors.blue[600]!,
                                                          isTinyScreen,
                                                          isNarrowScreen,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: _buildResumoItem(
                                                          'Total Vendas',
                                                          formatCurrency(resumo['vendas'] ?? 0),
                                                          Icons.shopping_cart,
                                                          Colors.purple[600]!,
                                                          isTinyScreen,
                                                          isNarrowScreen,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: _buildResumoItem(
                                                          'Total Entradas',
                                                          formatCurrency(resumo['entradas'] ?? 0),
                                                          Icons.trending_up,
                                                          Colors.green[600]!,
                                                          isTinyScreen,
                                                          isNarrowScreen,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: _buildResumoItem(
                                                          'Total Saídas',
                                                          formatCurrency(resumo['saidas'] ?? 0),
                                                          Icons.trending_down,
                                                          Colors.red[600]!,
                                                          isTinyScreen,
                                                          isNarrowScreen,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20),


                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Botões de Entrada e Saída - Posicionados após o resumo
                      if (caixaAtivo?.isAberto == true &&
                          permissoes.any(
                            (p) =>
                                p['recurso'] == 'caixa' &&
                                p['acao'] == 'atualizar',
                          ))
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Ações do Caixa',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Botões lado a lado
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _registrarEntrada,
                                      icon: const Icon(
                                        Icons.add_circle,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Registrar Entrada',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _registrarSaida,
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Registrar Saída',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Use estes botões para registrar entradas e saídas de dinheiro no caixa',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                    ] else ...[
                      AppCard(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: const Text(
                                  'Não há caixa aberto. Abra um caixa para visualizar movimentações.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Botão para ir ao caixa
                              ElevatedButton.icon(
                                onPressed: () => context.go('/caixa'),
                                icon: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 16,
                                ),
                                label: const Text('Ir ao Caixa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Lista de movimentações
                    if (caixaAtivo?.isAberto == true)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Movimentações',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (caixaAtivo != null)
                                        Row(
                                          children: [
                                            Text(
                                              'Caixa: ${caixaAtivo!.id.substring(0, 8)}...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            if (isLoading) ...[
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.blue[400]!),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Atualizando...',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blue[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                // Botão de voltar ao caixa
                                TextButton.icon(
                                  onPressed: () => context.go('/caixa'),
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text('Voltar ao Caixa'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Consumer(
                              builder: (context, ref, child) {
                                final movimentacoesAsync = ref.watch(
                                  movimentacoesCaixaProvider(caixaAtivo!.id),
                                );

                                return movimentacoesAsync.when(
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (e, _) => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 64,
                                            color: Colors.red[300],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Erro ao carregar movimentações: $e',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              ref.invalidate(
                                                movimentacoesCaixaProvider,
                                              );
                                            },
                                            icon: const Icon(Icons.refresh),
                                            label: const Text(
                                              'Tentar Novamente',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  data: (movimentacoes) {
                                    if (movimentacoes.isEmpty) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.history,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Nenhuma movimentação encontrada',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'As movimentações aparecerão aqui quando forem registradas',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: [
                                        // Resumo das movimentações
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${movimentacoes.length} movimentação(ões) encontrada(s)',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Lista de movimentações
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: movimentacoes.length,
                                          itemBuilder: (context, index) {
                                            final mov = movimentacoes[index];
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              elevation: 1,
                                              child: ListTile(
                                                leading: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getTipoColor(
                                                      mov.tipo,
                                                    ).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    mov.isEntrada
                                                        ? Icons.add
                                                        : mov.isSaida
                                                        ? Icons.remove
                                                        : Icons.shopping_cart,
                                                    color: _getTipoColor(
                                                      mov.tipo,
                                                    ),
                                                    size: 20,
                                                  ),
                                                ),
                                                title: Text(
                                                  mov.descricao ??
                                                      mov.tipo.label,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${formatDate(mov.data)} - ${mov.tipo.label}',
                                                ),
                                                trailing: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      mov.isSaida ? '-' : '+',
                                                      style: TextStyle(
                                                        color: _getTipoColor(
                                                          mov.tipo,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      formatCurrency(mov.valor),
                                                      style: TextStyle(
                                                        color: _getTipoColor(
                                                          mov.tipo,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
