import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/movimentacao_estoque_controller.dart';
import '../models/movimentacao_estoque_model.dart';
import '../../produto/controllers/produto_controller.dart';
import '../../lojas/controllers/loja_controller.dart';
import '../../lojas/models/loja_model.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../../core/services/user_audit_service.dart';

class NovaTrocaEstoqueView extends ConsumerStatefulWidget {
  const NovaTrocaEstoqueView({super.key});

  @override
  ConsumerState<NovaTrocaEstoqueView> createState() =>
      _NovaTrocaEstoqueViewState();
}

class _NovaTrocaEstoqueViewState extends ConsumerState<NovaTrocaEstoqueView> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeSaidaController = TextEditingController();
  final _quantidadeEntradaController = TextEditingController();
  final _observacaoController = TextEditingController();
  String? _produtoSaidaId;
  String? _produtoEntradaId;
  bool _loading = false;

  @override
  void dispose() {
    _quantidadeSaidaController.dispose();
    _quantidadeEntradaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_produtoSaidaId == null) {
      AppFeedback.showError(context, 'Selecione o produto que está saindo');
      return;
    }
    if (_produtoEntradaId == null) {
      AppFeedback.showError(context, 'Selecione o produto que está entrando');
      return;
    }
    if (_produtoSaidaId == _produtoEntradaId) {
      AppFeedback.showError(
        context,
        'Os produtos de saída e entrada devem ser diferentes',
      );
      return;
    }

    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva == null || lojaAtiva.isEmpty) {
      AppFeedback.showError(context, 'Nenhuma loja ativa selecionada');
      return;
    }

    setState(() => _loading = true);

    try {
      final quantidadeSaida = int.parse(_quantidadeSaidaController.text);
      final quantidadeEntrada = int.parse(_quantidadeEntradaController.text);
      final observacao = _observacaoController.text.trim();
      final usuarioId = await UserAuditService().getUsuarioId();

      // Verificar estoque disponível para o produto de saída
      final estoqueAtual = await ref
          .read(movimentacaoEstoqueProvider.notifier)
          .getEstoqueAtual(_produtoSaidaId!);

      if (quantidadeSaida > estoqueAtual) {
        if (!mounted) return;
        _mostrarDialogoEstoqueInsuficiente(estoqueAtual, quantidadeSaida);
        return;
      }

      // Buscar nomes dos produtos para a observação
      final produtosAsync = ref.read(produtoProvider);
      final produtos = produtosAsync.when(
        data: (data) => data,
        loading: () => throw Exception('Erro ao carregar produtos'),
        error: (e, _) => throw Exception('Erro ao carregar produtos: $e'),
      );

      final produtoSaida = produtos.firstWhere((p) => p.id == _produtoSaidaId);
      final produtoEntrada = produtos.firstWhere(
        (p) => p.id == _produtoEntradaId,
      );

      // Criar observação explicativa da troca
      final observacaoCompleta = observacao.isNotEmpty
          ? 'Troca: ${quantidadeSaida}x ${produtoSaida.nome} → ${quantidadeEntrada}x ${produtoEntrada.nome}. $observacao'
          : 'Troca: ${quantidadeSaida}x ${produtoSaida.nome} → ${quantidadeEntrada}x ${produtoEntrada.nome}';

      // Criar movimentação de saída (troca_saida)
      final movimentacaoSaida = MovimentacaoEstoqueModel.novo(
        lojaId: lojaAtiva,
        produtoId: _produtoSaidaId!,
        tipo: TipoMovimentacao.trocaSaida,
        quantidade: quantidadeSaida,
        observacao: observacaoCompleta,
        criadoPor: usuarioId,
      );

      // Criar movimentação de entrada (troca_entrada)
      final movimentacaoEntrada = MovimentacaoEstoqueModel.novo(
        lojaId: lojaAtiva,
        produtoId: _produtoEntradaId!,
        tipo: TipoMovimentacao.trocaEntrada,
        quantidade: quantidadeEntrada,
        observacao: observacaoCompleta,
        criadoPor: usuarioId,
      );

      // Salvar ambas as movimentações
      await ref
          .read(movimentacaoEstoqueProvider.notifier)
          .addMovimentacao(movimentacaoSaida);
      await ref
          .read(movimentacaoEstoqueProvider.notifier)
          .addMovimentacao(movimentacaoEntrada);

      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Troca registrada com sucesso!');
      context.go('/trocas-estoque');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erro ao registrar troca: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _mostrarDialogoEstoqueInsuficiente(
    int estoqueAtual,
    int quantidadeSolicitada,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Estoque Insuficiente',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Não é possível realizar a troca. O produto de saída não possui estoque suficiente.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Estoque Atual (Produto de Saída)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$estoqueAtual unidades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.remove_circle,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quantidade Solicitada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantidadeSolicitada unidades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faltam ${quantidadeSolicitada - estoqueAtual} unidades para completar a troca.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Entendi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produtosAsync = ref.watch(produtoProvider);
    final lojasAsync = ref.watch(lojaProvider);
    final lojaAtiva = ref.watch(lojaAtivaProvider);

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Nova Troca',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Trocas'),
              BreadcrumbItem('Nova'),
            ],
            currentRoute: '/nova-troca-estoque',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'criar',
            );

            if (!podeCriar) {
              return MainLayout(
                title: 'Nova Troca',
                breadcrumbs: const [
                  BreadcrumbItem('Dashboard'),
                  BreadcrumbItem('Trocas'),
                  BreadcrumbItem('Nova'),
                ],
                currentRoute: '/nova-troca-estoque',
                child: const Center(child: Text('Acesso negado')),
              );
            }

            return MainLayout(
              title: 'Nova Troca de Estoque',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Trocas'),
                BreadcrumbItem('Nova'),
              ],
              currentRoute: '/nova-troca-estoque',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Voltar para Trocas',
                  onPressed: () {
                    context.go('/trocas-estoque');
                  },
                ),
              ],
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final leftPanel = AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Nova Troca de Estoque',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Loja ativa (somente leitura)
                            if (lojaAtiva != null && lojaAtiva.isNotEmpty)
                              lojasAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) =>
                                    const Text('Erro ao carregar lojas'),
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
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.store,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Loja Ativa',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          loja.nome,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (loja.shopping.isNotEmpty ||
                                            loja.andar.isNotEmpty ||
                                            loja.numero.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${loja.shopping}${loja.andar.isNotEmpty ? ' - ${loja.andar}º andar' : ''}${loja.numero.isNotEmpty ? ' - Loja ${loja.numero}' : ''}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 24),

                            // Produto que está saindo
                            Text(
                              'Produto que está Saindo',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            produtosAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) =>
                                  const Text('Erro ao carregar produtos'),
                              data: (produtos) => DropdownButtonFormField<String>(
                                value: _produtoSaidaId,
                                decoration: const InputDecoration(
                                  labelText: 'Produto que sai *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                ),
                                items: produtos.map((produto) {
                                  return DropdownMenuItem(
                                    value: produto.id,
                                    child: Text(produto.nome),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _produtoSaidaId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecione o produto que está saindo';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Mostrar estoque atual para o produto de saída
                            if (_produtoSaidaId != null)
                              FutureBuilder<int>(
                                future: ref
                                    .read(movimentacaoEstoqueProvider.notifier)
                                    .getEstoqueAtual(_produtoSaidaId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Carregando estoque...'),
                                        ],
                                      ),
                                    );
                                  }

                                  if (snapshot.hasData) {
                                    final estoqueAtual = snapshot.data!;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: estoqueAtual > 0
                                            ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: estoqueAtual > 0
                                              ? Colors.green.withValues(
                                                  alpha: 0.3,
                                                )
                                              : Colors.red.withValues(
                                                  alpha: 0.3,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            estoqueAtual > 0
                                                ? Icons.inventory_2
                                                : Icons.inventory_2_outlined,
                                            color: estoqueAtual > 0
                                                ? Colors.green
                                                : Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Estoque Atual (Produto de Saída)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  '$estoqueAtual unidades',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: estoqueAtual > 0
                                                        ? Colors.green[700]
                                                        : Colors.red[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),

                            const SizedBox(height: 16),

                            // Quantidade que está saindo
                            TextFormField(
                              controller: _quantidadeSaidaController,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade que sai *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.numbers,
                                  color: Colors.red,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_loading,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a quantidade que está saindo';
                                }
                                final quantidade = int.tryParse(value);
                                if (quantidade == null || quantidade <= 0) {
                                  return 'Quantidade deve ser um número positivo';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Produto que está entrando
                            Text(
                              'Produto que está Entrando',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            produtosAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) =>
                                  const Text('Erro ao carregar produtos'),
                              data: (produtos) => DropdownButtonFormField<String>(
                                value: _produtoEntradaId,
                                decoration: const InputDecoration(
                                  labelText: 'Produto que entra *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                  ),
                                ),
                                items: produtos.map((produto) {
                                  return DropdownMenuItem(
                                    value: produto.id,
                                    child: Text(produto.nome),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _produtoEntradaId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecione o produto que está entrando';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Quantidade que está entrando
                            TextFormField(
                              controller: _quantidadeEntradaController,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade que entra *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.numbers,
                                  color: Colors.green,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_loading,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a quantidade que está entrando';
                                }
                                final quantidade = int.tryParse(value);
                                if (quantidade == null || quantidade <= 0) {
                                  return 'Quantidade deve ser um número positivo';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Observação adicional
                            TextFormField(
                              controller: _observacaoController,
                              decoration: const InputDecoration(
                                labelText: 'Observação Adicional',
                                border: OutlineInputBorder(),
                                hintText:
                                    'Ex: Troca por defeito, troca por tamanho, etc.',
                                prefixIcon: Icon(Icons.note),
                              ),
                              maxLines: 3,
                              enabled: !_loading,
                            ),

                            const SizedBox(height: 24),

                            // Botões de ação
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            context.go('/trocas-estoque');
                                          },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Voltar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _salvar,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text('Registrar Troca'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  final rightPanel = Column(
                    children: [
                      // Card de informações
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Como Funciona a Troca',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoItem(
                                'Produto que Sai',
                                'Produto que será removido do estoque (defeituoso, troca por cliente, etc.)',
                                Icons.remove_circle,
                                Colors.red,
                              ),
                              _buildInfoItem(
                                'Produto que Entra',
                                'Produto que será adicionado ao estoque (novo produto, reposição, etc.)',
                                Icons.add_circle,
                                Colors.green,
                              ),
                              _buildInfoItem(
                                'Dois Registros',
                                'Serão criados dois registros: um de saída e outro de entrada',
                                Icons.swap_horiz,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card de dicas
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Dicas para Trocas',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTipItem(
                                'Verifique se há estoque suficiente do produto que está saindo',
                              ),
                              _buildTipItem(
                                'Confirme as quantidades antes de finalizar a troca',
                              ),
                              _buildTipItem(
                                'Use observações para documentar o motivo da troca',
                              ),
                              _buildTipItem(
                                'Dois registros serão criados automaticamente',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );

                  if (isWide) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: leftPanel),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: rightPanel),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftPanel,
                        const SizedBox(height: 16),
                        rightPanel,
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
