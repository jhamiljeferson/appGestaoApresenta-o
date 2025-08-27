import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/item_venda_model.dart';
import '../models/pagamento_venda_model.dart';
import '../controllers/venda_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../features/lojas/providers/loja_ativa_provider.dart';
import '../../../features/lojas/controllers/loja_controller.dart';
import '../../../features/lojas/models/loja_model.dart';
import '../../../features/cliente/controllers/cliente_controller.dart';
import '../../../features/cliente/models/cliente_model.dart';
import '../../../features/produto/controllers/produto_controller.dart';
import '../../../features/produto/models/produto_model.dart';
import '../../../features/forma_pagamento/controllers/forma_pagamento_controller.dart';
import '../../../features/forma_pagamento/models/forma_pagamento_model.dart';
import '../../../features/auth/controllers/user_info_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/caixa/models/caixa_model.dart';
import '../../../features/caixa/services/caixa_service.dart';

class NovaVendaView extends ConsumerStatefulWidget {
  const NovaVendaView({super.key});

  @override
  ConsumerState<NovaVendaView> createState() => _NovaVendaViewState();
}

class _NovaVendaViewState extends ConsumerState<NovaVendaView> {
  // Dados da venda
  String? _clienteId;
  ClienteModel? _clienteSelecionado;
  final List<ItemVendaModel> _itens = [];
  final List<PagamentoVendaModel> _pagamentos = [];

  // Controllers
  final _searchController = TextEditingController();
  final _descontoController = TextEditingController();
  final _valorPagoController = TextEditingController();

  // Estados
  bool _loading = false;
  bool _showSearchResults = false;
  String? _formaPagamentoSelecionadaId;
  double _descontoTotal = 0.0;
  List<ProdutoModel> _produtosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _searchController.addListener(_filtrarProdutos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descontoController.dispose();
    _valorPagoController.dispose();
    super.dispose();
  }

  void _carregarDados() {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
      ref.read(clienteProvider.notifier).loadClientesPorLoja(lojaAtiva);
    }
    ref.read(produtoProvider.notifier).loadProdutos();
    ref.read(formaPagamentoProvider.notifier).loadFormasPagamento();
  }

  void _filtrarProdutos() {
    final searchTerm = _searchController.text.toLowerCase().trim();
    if (searchTerm.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _produtosFiltrados = [];
      });
      return;
    }

    final produtos = ref.read(produtoProvider).value ?? [];
    final filtrados = produtos.where((produto) {
      // Busca por nome (mais relevante)
      if (produto.nome.toLowerCase().contains(searchTerm)) return true;

      // Busca exata por SKU
      if (produto.sku.toLowerCase() == searchTerm) return true;

      // Busca por SKU (parcial)
      if (produto.sku.toLowerCase().contains(searchTerm)) return true;

      // Busca por código de barras
      if (produto.codigo.toLowerCase().contains(searchTerm)) return true;

      return false;
    }).toList();

    setState(() {
      _produtosFiltrados = filtrados;
      _showSearchResults = true;
    });
  }

  void _adicionarProdutoDireto(ProdutoModel produto) {
    // Verificar se o produto já existe no carrinho
    final indexExistente = _itens.indexWhere(
      (item) => item.produtoId == produto.id,
    );

    if (indexExistente != -1) {
      // Produto já existe, incrementar quantidade
      final itemExistente = _itens[indexExistente];
      final novaQuantidade = itemExistente.quantidade + 1;
      final novoPreco = _calcularPrecoPorQuantidade(produto, novaQuantidade);

      setState(() {
        _itens[indexExistente] = itemExistente.copyWith(
          quantidade: novaQuantidade,
          precoUnitario: novoPreco,
        );
      });

      final tipoPreco = _getTipoPreco(produto, novaQuantidade);
      AppFeedback.showSuccess(
        context,
        'Quantidade atualizada para $novaQuantidade com preço $tipoPreco!',
      );
    } else {
      // Produto não existe, adicionar novo item
      final quantidade = 1;
      final precoFinal = _calcularPrecoPorQuantidade(produto, quantidade);
      final tipoPreco = _getTipoPreco(produto, quantidade);

      final item = ItemVendaModel.novo(
        vendaId: '',
        produtoId: produto.id,
        quantidade: quantidade,
        precoUnitario: precoFinal,
        descontoUnitario: 0.0,
      );

      setState(() {
        _itens.add(item);
      });

      AppFeedback.showSuccess(
        context,
        'Produto adicionado com preço $tipoPreco!',
      );
    }
  }

  double _calcularPrecoPorQuantidade(ProdutoModel produto, int quantidade) {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    final lojas = ref.read(lojaProvider).value ?? [];
    final loja = lojas.firstWhere(
      (l) => l.id == lojaAtiva,
      orElse: () => LojaModel(
        id: '',
        nome: '',
        shopping: '',
        andar: '',
        numero: '',
        quantidadeMinimaAtacado: 4,
      ),
    );

    final quantidadeMinimaAtacado = loja.quantidadeMinimaAtacado ?? 4;

    // 1-2 peças: preço de varejo
    if (quantidade <= 2) {
      return produto.precoVarejo;
    }

    // 3 até quantidade_minima_atacado: preço promocional
    if (quantidade >= 3 && quantidade < quantidadeMinimaAtacado) {
      return produto.precoPromocional ?? produto.precoVarejo;
    }

    // A partir da quantidade_minima_atacado: preço de atacado
    if (quantidade >= quantidadeMinimaAtacado) {
      return produto.precoAtacado > 0
          ? produto.precoAtacado
          : produto.precoVarejo;
    }

    return produto.precoVarejo;
  }

  String _getTipoPreco(ProdutoModel produto, int quantidade) {
    final lojaAtiva = ref.read(lojaAtivaProvider);
    final lojas = ref.read(lojaProvider).value ?? [];
    final loja = lojas.firstWhere(
      (l) => l.id == lojaAtiva,
      orElse: () => LojaModel(
        id: '',
        nome: '',
        shopping: '',
        andar: '',
        numero: '',
        quantidadeMinimaAtacado: 4,
      ),
    );

    final quantidadeMinimaAtacado = loja.quantidadeMinimaAtacado ?? 4;

    if (quantidade <= 2) return 'Varejo';
    if (quantidade >= 3 && quantidade < quantidadeMinimaAtacado) {
      return 'Promocional';
    }
    if (quantidade >= quantidadeMinimaAtacado) return 'Atacado';
    return 'Varejo';
  }

  void _atualizarQuantidadeItem(int index, int novaQuantidade) {
    if (novaQuantidade <= 0) {
      setState(() {
        _itens.removeAt(index);
      });
      AppFeedback.showSuccess(context, 'Item removido do carrinho');
      return;
    }

    final item = _itens[index];
    final produtos = ref.read(produtoProvider).value ?? [];
    final produto = produtos.firstWhere(
      (p) => p.id == item.produtoId,
      orElse: () => ProdutoModel(
        id: '',
        nome: 'Produto não encontrado',
        sku: '',
        codigo: '',
        categoriaId: '',
        precoCusto: 0.0,
        precoAtacado: 0.0,
        precoVarejo: 0.0,
      ),
    );

    final novoPreco = _calcularPrecoPorQuantidade(produto, novaQuantidade);

    setState(() {
      _itens[index] = item.copyWith(
        quantidade: novaQuantidade,
        precoUnitario: novoPreco,
      );
    });
  }

  void _removerItem(int index) {
    setState(() {
      _itens.removeAt(index);
    });
    AppFeedback.showSuccess(context, 'Item removido do carrinho');
  }

  void _aplicarDescontoUnitario(int index, double desconto) {
    if (desconto < 0) {
      AppFeedback.showError(context, 'O desconto não pode ser negativo');
      return;
    }

    final item = _itens[index];
    final produtos = ref.read(produtoProvider).value ?? [];
    final produto = produtos.firstWhere(
      (p) => p.id == item.produtoId,
      orElse: () => ProdutoModel(
        id: '',
        nome: 'Produto não encontrado',
        sku: '',
        codigo: '',
        categoriaId: '',
        precoCusto: 0.0,
        precoAtacado: 0.0,
        precoVarejo: 0.0,
      ),
    );

    if (desconto > item.precoUnitario) {
      AppFeedback.showError(
        context,
        'O desconto não pode ser maior que o preço unitário',
      );
      return;
    }

    setState(() {
      _itens[index] = item.copyWith(descontoUnitario: desconto);
    });

    AppFeedback.showSuccess(context, 'Desconto aplicado ao item');
  }

  void _mostrarDialogDescontoUnitario(int index) {
    final item = _itens[index];
    final descontoController = TextEditingController(
      text: item.descontoUnitario > 0 ? item.descontoUnitario.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aplicar Desconto Unitário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Preço unitário: ${formatCurrency(item.precoUnitario)}'),
            const SizedBox(height: 16),
            TextField(
              controller: descontoController,
              decoration: const InputDecoration(
                labelText: 'Valor do Desconto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.discount),
              ),
              keyboardType: TextInputType.number,
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
              final desconto = double.tryParse(descontoController.text) ?? 0.0;
              Navigator.of(context).pop();
              _aplicarDescontoUnitario(index, desconto);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  // Função para obter ícone baseado no nome da forma de pagamento
  IconData _getPaymentIcon(String nomeFormaPagamento) {
    final nome = nomeFormaPagamento.toLowerCase();
    if (nome.contains('dinheiro') || nome.contains('espécie')) {
      return Icons.payments;
    } else if (nome.contains('cartão') || nome.contains('card')) {
      if (nome.contains('débito')) {
        return Icons.credit_card;
      } else if (nome.contains('crédito')) {
        return Icons.credit_card_outlined;
      }
      return Icons.credit_card;
    } else if (nome.contains('pix')) {
      return Icons.qr_code_2;
    } else if (nome.contains('boleto')) {
      return Icons.receipt_long;
    } else if (nome.contains('transferência') ||
        nome.contains('ted') ||
        nome.contains('doc')) {
      return Icons.account_balance;
    } else if (nome.contains('cheque')) {
      return Icons.receipt;
    }
    return Icons.payment;
  }

  void _adicionarPagamento() {
    if (_formaPagamentoSelecionadaId == null) {
      AppFeedback.showError(context, 'Selecione uma forma de pagamento');
      return;
    }

    final valorPago = double.tryParse(_valorPagoController.text);
    if (valorPago == null || valorPago <= 0) {
      AppFeedback.showError(context, 'Digite um valor válido');
      return;
    }

    final pagamento = PagamentoVendaModel.novo(
      vendaId: '',
      formaPagamentoId: _formaPagamentoSelecionadaId!,
      valorPago: valorPago,
    );

    setState(() {
      _pagamentos.add(pagamento);
      _formaPagamentoSelecionadaId = null;
      _valorPagoController.clear();
    });

    AppFeedback.showSuccess(context, 'Pagamento adicionado');
  }

  void _removerPagamento(int index) {
    setState(() {
      _pagamentos.removeAt(index);
    });
    AppFeedback.showSuccess(context, 'Pagamento removido');
  }

  void _mostrarSeletorCliente() {
    showDialog(
      context: context,
      builder: (context) => _ClienteSelectorDialog(
        onClienteSelecionado: (cliente) {
          setState(() {
            _clienteId = cliente.id;
            _clienteSelecionado = cliente;
          });
          Navigator.of(context).pop();
        },
        onCriarCliente: () {
          Navigator.of(context).pop();
          context.go('/clientes/novo');
        },
      ),
    );
  }

  void _cancelarVenda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Venda'),
        content: const Text('Tem certeza que deseja cancelar esta venda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _itens.clear();
                _pagamentos.clear();
                _descontoTotal = 0.0;
                _clienteId = null;
                _clienteSelecionado = null;
              });
              AppFeedback.showSuccess(context, 'Venda cancelada');
            },
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  void _finalizarVenda() {
    if (_itens.isEmpty) {
      AppFeedback.showError(context, 'Adicione pelo menos um produto');
      return;
    }

    if (_valorRestante > 0.01) {
      AppFeedback.showError(
        context,
        'O valor pago deve cobrir o total da venda',
      );
      return;
    }

    // IMPORTANTE: Verificar se há caixa aberto antes de finalizar a venda
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva == null || lojaAtiva.isEmpty) {
      AppFeedback.showError(context, 'Selecione uma loja ativa');
      return;
    }

    // Verificar status do caixa
    _verificarCaixaAberto()
        .then((caixaAberto) {
          if (caixaAberto == null) {
            AppFeedback.showError(
              context,
              'Não é possível realizar vendas sem caixa aberto. Abra um caixa primeiro.',
            );
            return;
          }

          if (caixaAberto.isFechado) {
            AppFeedback.showError(
              context,
              'Não é possível realizar vendas em caixa fechado. Abra um caixa primeiro.',
            );
            return;
          }

          // Se chegou até aqui, o caixa está aberto e pode prosseguir
          _processarVenda();
        })
        .catchError((error) {
          AppFeedback.showError(context, 'Erro ao verificar caixa: $error');
        });
  }

  Future<void> _processarVenda() async {
    setState(() {
      _loading = true;
    });

    try {
      print('🔧 [NovaVendaView] Processando venda...');

      await ref
          .read(vendaProvider.notifier)
          .addVenda(
            ref.read(lojaAtivaProvider) ?? '',
            _clienteId,
            ref.read(userInfoProvider).value?.usuario?.id ?? '',
            _itens,
            _pagamentos,
            _descontoTotal,
          );

      if (mounted) {
        setState(() {
          _loading = false;
        });
        AppFeedback.showSuccess(context, 'Venda finalizada com sucesso!');
        context.go('/vendas');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        AppFeedback.showError(context, 'Erro ao finalizar venda: $error');
      }
    }
  }

  Future<CaixaModel?> _verificarCaixaAberto() async {
    try {
      final lojaAtiva = ref.read(lojaAtivaProvider);
      if (lojaAtiva == null || lojaAtiva.isEmpty) return null;

      // Importar o CaixaService para verificar o caixa
      final caixaService = CaixaService();
      return await caixaService.getCaixaAbertoPorLoja(lojaAtiva);
    } catch (e) {
      print('❌ [NovaVendaView] Erro ao verificar caixa: $e');
      return null;
    }
  }

  // Getters para cálculos
  double get _valorTotal => _itens.fold(
    0.0,
    (total, item) => total + (item.precoUnitario * item.quantidade),
  );

  double get _descontoUnitarioTotal => _itens.fold(
    0.0,
    (total, item) => total + (item.descontoUnitario * item.quantidade),
  );

  double get _valorLiquido =>
      _valorTotal - _descontoUnitarioTotal - _descontoTotal;

  double get _valorTotalPagamentos =>
      _pagamentos.fold(0.0, (total, pagamento) => total + pagamento.valorPago);

  double get _valorRestante => _valorLiquido - _valorTotalPagamentos;

  @override
  Widget build(BuildContext context) {
    final formaPagamentoAsync = ref.watch(formaPagamentoProvider);
    final lojaAtiva = ref.watch(lojaAtivaProvider);
    final lojasAsync = ref.watch(lojaProvider);

    return MainLayout(
      title: '🛒 Venda Rápida',
      breadcrumbs: const [
        BreadcrumbItem('Dashboard'),
        BreadcrumbItem('Vendas'),
        BreadcrumbItem('Nova'),
      ],
      currentRoute: '/vendas',
      onSidebarItemSelected: (route) => context.go(route),
      actions: [
        TextButton.icon(
          onPressed: _loading ? null : () => context.go('/vendas'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar'),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com loja ativa e status do caixa
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.store, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Venda Rápida - ${loja.nome}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status do caixa
                        FutureBuilder<CaixaModel?>(
                          future: _verificarCaixaAberto(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Verificando status do caixa...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              );
                            }

                            final caixa = snapshot.data;
                            if (caixa == null) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '❌ CAIXA FECHADO - Não é possível realizar vendas',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => context.go('/caixa'),
                                      icon: const Icon(
                                        Icons.account_balance_wallet,
                                        size: 16,
                                      ),
                                      label: const Text('Abrir Caixa'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (caixa.isFechado) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '⚠️ CAIXA FECHADO - Não é possível realizar vendas',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => context.go('/caixa'),
                                      icon: const Icon(
                                        Icons.account_balance_wallet,
                                        size: 16,
                                      ),
                                      label: const Text('Abrir Caixa'),
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
                              );
                            }

                            // Caixa aberto
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '✅ CAIXA ABERTO - Vendas permitidas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => context.go('/caixa'),
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 16,
                                    ),
                                    label: const Text('Ver Caixa'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            // Header com informações da venda
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      lojasAsync.when(
                        loading: () => const Text(
                          'Carregando...',
                          style: TextStyle(fontSize: 12),
                        ),
                        error: (e, _) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            '⚠️ Erro ao carregar loja',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                        data: (lojas) {
                          if (lojaAtiva == null || lojaAtiva.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                '⚠️ Nenhuma loja selecionada',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[700],
                                ),
                              ),
                            );
                          }

                          final loja = lojas.firstWhere(
                            (l) => l.id == lojaAtiva,
                            orElse: () => LojaModel(
                              id: '',
                              nome: 'Loja não encontrada',
                              shopping: '',
                              andar: '',
                              numero: '',
                              quantidadeMinimaAtacado: 4,
                            ),
                          );

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Text(
                              '🏪 ${loja.nome}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            ),
                          );
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total: ${formatCurrency(_valorLiquido)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_descontoTotal > 0)
                            Text(
                              'Desconto: ${formatCurrency(_descontoTotal)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: (lojaAtiva != null && lojaAtiva.isNotEmpty)
                              ? _mostrarSeletorCliente
                              : () => AppFeedback.showError(
                                  context,
                                  'Selecione uma loja antes de escolher o cliente',
                                ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _clienteSelecionado != null
                                      ? Icons.person
                                      : Icons.person_add,
                                  color: _clienteSelecionado != null
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    _clienteSelecionado?.nome ??
                                        'Selecionar Cliente',
                                    style: TextStyle(
                                      color: _clienteSelecionado != null
                                          ? Colors.black
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_clienteSelecionado != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _clienteId = null;
                              _clienteSelecionado = null;
                            });
                          },
                          icon: const Icon(Icons.clear, color: Colors.red),
                          tooltip: 'Remover cliente',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Campo de pesquisa com scanner
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesquisar Produtos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Buscar produtos por nome, SKU ou código...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[400],
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showSearchResults = false;
                                        _produtosFiltrados = [];
                                      });
                                      _searchController.clear();
                                    },
                                    icon: const Icon(Icons.clear),
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                _showSearchResults = false;
                                _produtosFiltrados = [];
                              });
                            } else {
                              _filtrarProdutos();
                            }
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _filtrarProdutos();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Implementar scanner de código de barras
                          AppFeedback.showSuccess(
                            context,
                            'Scanner de código de barras em desenvolvimento',
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_showSearchResults)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _produtosFiltrados.isEmpty
                                    ? 'Nenhum produto encontrado'
                                    : '${_produtosFiltrados.length} produto(s) encontrado(s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _produtosFiltrados.isEmpty
                                      ? Colors.red[600]
                                      : Colors.grey[600],
                                ),
                              ),
                              if (_produtosFiltrados.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showSearchResults = false;
                                      _produtosFiltrados = [];
                                      _searchController.clear();
                                    });
                                  },
                                  child: const Text('Fechar'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_produtosFiltrados.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _produtosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final produto = _produtosFiltrados[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () =>
                                          _adicionarProdutoDireto(produto),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue[50],
                                        child: Text(
                                          produto.nome
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        produto.nome,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              produto.sku,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: [
                                              // Preço Varejo (1-2)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.green[200]!,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  '1-2: ${formatCurrency(produto.precoVarejo)}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              // Preço Promocional (3+)
                                              if (produto.precoPromocional !=
                                                  null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.orange[200]!,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '3+: ${formatCurrency(produto.precoPromocional!)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.orange[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              // Preço Atacado
                                              if (produto.precoAtacado > 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.purple[200]!,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Atacado: ${formatCurrency(produto.precoAtacado)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.purple[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Carrinho de compras
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header do carrinho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Carrinho de Compras',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          '${_itens.length} item(s)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lista de itens do carrinho
                  if (_itens.isEmpty)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Carrinho vazio',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Adicione produtos para começar',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _itens.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final produtos = ref.read(produtoProvider).value ?? [];
                        final produto = produtos.firstWhere(
                          (p) => p.id == item.produtoId,
                          orElse: () => ProdutoModel(
                            id: '',
                            nome: 'Produto não encontrado',
                            sku: '',
                            codigo: '',
                            categoriaId: '',
                            precoCusto: 0.0,
                            precoAtacado: 0.0,
                            precoVarejo: 0.0,
                          ),
                        );

                        final precoComDesconto =
                            item.precoUnitario - item.descontoUnitario;
                        final subtotalItem = precoComDesconto * item.quantidade;
                        final descontoTotalItem =
                            item.descontoUnitario * item.quantidade;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // Cabeçalho do item
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            produto.nome,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'SKU: ${produto.sku}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removerItem(index),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red[50],
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Controles de quantidade e preços
                                Row(
                                  children: [
                                    // Controles de quantidade
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _atualizarQuantidadeItem(
                                                index,
                                                item.quantidade - 1,
                                              ),
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 16,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[100],
                                            minimumSize: const Size(28, 28),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${item.quantidade}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _atualizarQuantidadeItem(
                                                index,
                                                item.quantidade + 1,
                                              ),
                                          icon: const Icon(Icons.add, size: 16),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[100],
                                            minimumSize: const Size(28, 28),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),

                                    // Preços
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Preço unitário original
                                          Text(
                                            formatCurrency(item.precoUnitario),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              decoration:
                                                  item.descontoUnitario > 0
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          // Preço com desconto (se houver)
                                          if (item.descontoUnitario > 0)
                                            Text(
                                              formatCurrency(precoComDesconto),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                          // Subtotal do item
                                          Text(
                                            formatCurrency(subtotalItem),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Desconto unitário
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      if (item.descontoUnitario > 0) ...[
                                        Icon(
                                          Icons.discount,
                                          size: 14,
                                          color: Colors.orange[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Desconto unitário: ${formatCurrency(item.descontoUnitario)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Total desconto: ${formatCurrency(descontoTotalItem)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ] else ...[
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.discount_outlined,
                                                size: 14,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Aplicar desconto',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              _mostrarDialogDescontoUnitario(
                                                index,
                                              ),
                                          child: Text(
                                            'Desconto',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Seção de totais e desconto
            if (_itens.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Resumo da Venda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Totais
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                formatCurrency(_valorTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (_descontoUnitarioTotal > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Desconto Unitário:',
                                  style: TextStyle(
                                    color: Colors.orange[600],
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '-${formatCurrency(_descontoUnitarioTotal)}',
                                  style: TextStyle(
                                    color: Colors.orange[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_descontoTotal > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Desconto Geral:',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '-${formatCurrency(_descontoTotal)}',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total a Pagar:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatCurrency(_valorLiquido),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo de desconto geral
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descontoController,
                            decoration: const InputDecoration(
                              labelText: 'Desconto Geral',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.discount),
                              hintText: '0.00',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final desconto = double.tryParse(value) ?? 0.0;
                              setState(() {
                                _descontoTotal = desconto;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Seção de pagamento
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Formas de Pagamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Resumo de valores
                  if (_itens.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total a Pagar:'),
                              Text(
                                formatCurrency(_valorLiquido),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Já Pago:'),
                              Text(
                                formatCurrency(_valorTotalPagamentos),
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Restante:',
                                style: TextStyle(
                                  color: _valorRestante > 0
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatCurrency(_valorRestante),
                                style: TextStyle(
                                  color: _valorRestante > 0
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Formulário de pagamento
                  Column(
                    children: [
                      // Dropdown de forma de pagamento
                      formaPagamentoAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: const Text(
                            'Erro ao carregar formas de pagamento',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        data: (formasPagamento) =>
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Forma de Pagamento',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payment),
                              ),
                              value: _formaPagamentoSelecionadaId,
                              items: formasPagamento
                                  .map(
                                    (forma) => DropdownMenuItem(
                                      value: forma.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getPaymentIcon(forma.nome),
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(forma.nome),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                () => _formaPagamentoSelecionadaId = value,
                              ),
                            ),
                      ),

                      const SizedBox(height: 12),

                      // Campo de valor e botão adicionar
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _valorPagoController,
                              decoration: InputDecoration(
                                labelText: 'Valor Pago',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.attach_money),
                                hintText: '0,00',
                                helperText: _valorRestante > 0
                                    ? 'Restante: ${formatCurrency(_valorRestante)}'
                                    : null,
                                helperStyle: TextStyle(
                                  color: _valorRestante > 0
                                      ? Colors.orange[600]
                                      : Colors.green[600],
                                  fontSize: 11,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                // Atualiza em tempo real para mostrar se o valor está correto
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _formaPagamentoSelecionadaId != null
                                ? _adicionarPagamento
                                : null,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Lista de pagamentos
                  if (_pagamentos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Pagamentos Adicionados (${_pagamentos.length}):',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: _pagamentos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final pagamento = entry.value;
                          final formaPagamento = formaPagamentoAsync.value
                              ?.firstWhere(
                                (f) => f.id == pagamento.formaPagamentoId,
                                orElse: () => FormaPagamentoModel(
                                  id: '',
                                  nome: 'Forma não encontrada',
                                  tipoTaxa: TipoTaxa.acrescimo,
                                  percentualTaxa: 0.0,
                                ),
                              );

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: index < _pagamentos.length - 1
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 0.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Ícone da forma de pagamento
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.green[200]!,
                                    ),
                                  ),
                                  child: Icon(
                                    _getPaymentIcon(formaPagamento?.nome ?? ''),
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Informações do pagamento
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formaPagamento?.nome ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Pagamento ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Valor e botão remover
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        formatCurrency(pagamento.valorPago),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _removerPagamento(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Status do pagamento
                  if (_pagamentos.isNotEmpty || _valorRestante <= 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _valorRestante <= 0
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _valorRestante <= 0
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _valorRestante <= 0
                                ? Icons.check_circle
                                : Icons.warning,
                            color: _valorRestante <= 0
                                ? Colors.green[600]
                                : Colors.orange[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _valorRestante <= 0
                                      ? 'Pagamento Completo!'
                                      : 'Pagamento Parcial',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _valorRestante <= 0
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                                if (_valorRestante > 0)
                                  Text(
                                    'Restante: ${formatCurrency(_valorRestante)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(_valorTotalPagamentos),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _valorRestante <= 0
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            const SizedBox(height: 16),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _cancelarVenda,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar Venda'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _finalizarVenda,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _loading ? 'Finalizando...' : 'Finalizar Venda',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteSelectorDialog extends ConsumerStatefulWidget {
  final Function(ClienteModel) onClienteSelecionado;
  final VoidCallback onCriarCliente;

  const _ClienteSelectorDialog({
    required this.onClienteSelecionado,
    required this.onCriarCliente,
  });

  @override
  ConsumerState<_ClienteSelectorDialog> createState() =>
      _ClienteSelectorDialogState();
}

class _ClienteSelectorDialogState
    extends ConsumerState<_ClienteSelectorDialog> {
  final _searchController = TextEditingController();
  List<ClienteModel> _clientesFiltrados = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarClientes() {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _clientesFiltrados = [];
      });
      return;
    }

    final clientes = ref.read(clienteProvider).value ?? [];
    final filtrados = clientes.where((cliente) {
      return cliente.nome.toLowerCase().contains(searchTerm) ||
          (cliente.documento != null &&
              cliente.documento!.toLowerCase().contains(searchTerm));
    }).toList();

    setState(() {
      _clientesFiltrados = filtrados;
      _showSearchResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clienteProvider);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Selecionar Cliente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão para criar novo cliente
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCriarCliente,
                icon: const Icon(Icons.add),
                label: const Text('Criar Novo Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes por nome ou documento...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de clientes
            clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
              data: (clientes) {
                final clientesParaMostrar = _showSearchResults
                    ? _clientesFiltrados
                    : clientes;

                if (clientesParaMostrar.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado'));
                }

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: clientesParaMostrar.length,
                    itemBuilder: (context, index) {
                      final cliente = clientesParaMostrar[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Text(
                            cliente.nome.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(cliente.nome),
                        subtitle: Text(
                          '${cliente.tipoDocumento ?? ''}: ${cliente.documento ?? ''}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => widget.onClienteSelecionado(cliente),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
