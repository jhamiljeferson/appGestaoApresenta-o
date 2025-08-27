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

class NovaTransferenciaEstoqueView extends ConsumerStatefulWidget {
  const NovaTransferenciaEstoqueView({super.key});

  @override
  ConsumerState<NovaTransferenciaEstoqueView> createState() =>
      _NovaTransferenciaEstoqueViewState();
}

class _NovaTransferenciaEstoqueViewState
    extends ConsumerState<NovaTransferenciaEstoqueView> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  final _observacaoController = TextEditingController();
  String? _produtoId;
  String? _lojaDestinoId;
  bool _loading = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_produtoId == null) {
      AppFeedback.showError(context, 'Selecione o produto para transferir');
      return;
    }
    if (_lojaDestinoId == null) {
      AppFeedback.showError(context, 'Selecione a loja de destino');
      return;
    }

    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva == null || lojaAtiva.isEmpty) {
      AppFeedback.showError(context, 'Nenhuma loja ativa selecionada');
      return;
    }

    if (lojaAtiva == _lojaDestinoId) {
      AppFeedback.showError(
        context,
        'A loja de destino deve ser diferente da loja ativa',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final quantidade = int.parse(_quantidadeController.text);
      final observacao = _observacaoController.text.trim();
      final usuarioId = await UserAuditService().getUsuarioId();

      // Verificar estoque disponível na loja origem
      final estoqueAtual = await ref
          .read(movimentacaoEstoqueProvider.notifier)
          .getEstoqueAtual(_produtoId!);

      if (quantidade > estoqueAtual) {
        if (!mounted) return;
        _mostrarDialogoEstoqueInsuficiente(estoqueAtual, quantidade);
        return;
      }

      // Buscar nomes dos produtos e lojas para a observação
      final produtosAsync = ref.read(produtoProvider);
      final lojasAsync = ref.read(lojaProvider);

      final produtos = produtosAsync.when(
        data: (data) => data,
        loading: () => throw Exception('Erro ao carregar produtos'),
        error: (e, _) => throw Exception('Erro ao carregar produtos: $e'),
      );

      final lojas = lojasAsync.when(
        data: (data) => data,
        loading: () => throw Exception('Erro ao carregar lojas'),
        error: (e, _) => throw Exception('Erro ao carregar lojas: $e'),
      );

      final produto = produtos.firstWhere((p) => p.id == _produtoId);
      final lojaOrigem = lojas.firstWhere((l) => l.id == lojaAtiva);
      final lojaDestino = lojas.firstWhere((l) => l.id == _lojaDestinoId);

      // Criar observação explicativa da transferência
      final observacaoCompleta = observacao.isNotEmpty
          ? 'Transferência: ${quantidade}x ${produto.nome} de ${lojaOrigem.nome} para ${lojaDestino.nome}. $observacao'
          : 'Transferência: ${quantidade}x ${produto.nome} de ${lojaOrigem.nome} para ${lojaDestino.nome}';

      // Criar movimentação de saída (transferencia_saida) na loja origem
      final movimentacaoSaida = MovimentacaoEstoqueModel.novo(
        lojaId: lojaAtiva,
        produtoId: _produtoId!,
        tipo: TipoMovimentacao.transferenciaSaida,
        quantidade: quantidade,
        observacao: observacaoCompleta,
        criadoPor: usuarioId,
      );

      // Criar movimentação de entrada (transferencia_entrada) na loja destino
      final movimentacaoEntrada = MovimentacaoEstoqueModel.novo(
        lojaId: _lojaDestinoId!,
        produtoId: _produtoId!,
        tipo: TipoMovimentacao.transferenciaEntrada,
        quantidade: quantidade,
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
      AppFeedback.showSuccess(context, 'Transferência registrada com sucesso!');
      context.go('/transferencias-estoque');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erro ao registrar transferência: $e');
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
                'Não é possível realizar a transferência. A loja origem não possui estoque suficiente.',
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
                          'Estoque Atual (Loja Origem)',
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
                      'Faltam ${quantidadeSolicitada - estoqueAtual} unidades para completar a transferência.',
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
            title: 'Nova Transferência',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Transferências'),
              BreadcrumbItem('Nova'),
            ],
            currentRoute: '/nova-transferencia-estoque',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'criar',
            );

            if (!podeCriar) {
              return MainLayout(
                title: 'Nova Transferência',
                breadcrumbs: const [
                  BreadcrumbItem('Dashboard'),
                  BreadcrumbItem('Transferências'),
                  BreadcrumbItem('Nova'),
                ],
                currentRoute: '/nova-transferencia-estoque',
                child: const Center(child: Text('Acesso negado')),
              );
            }

            return MainLayout(
              title: 'Nova Transferência de Estoque',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Transferências'),
                BreadcrumbItem('Nova'),
              ],
              currentRoute: '/nova-transferencia-estoque',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Voltar para Transferências',
                  onPressed: () {
                    context.go('/transferencias-estoque');
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
                                  Icons.swap_vert,
                                  color: Colors.purple,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Nova Transferência de Estoque',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Loja origem (somente leitura)
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
                                      color: Colors.purple.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.purple.withValues(
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
                                              color: Colors.purple,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Loja Origem',
                                              style: TextStyle(
                                                color: Colors.purple,
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

                            // Produto
                            produtosAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) =>
                                  const Text('Erro ao carregar produtos'),
                              data: (produtos) => DropdownButtonFormField<String>(
                                value: _produtoId,
                                decoration: const InputDecoration(
                                  labelText: 'Produto *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.inventory),
                                ),
                                items: produtos.map((produto) {
                                  return DropdownMenuItem(
                                    value: produto.id,
                                    child: Text(produto.nome),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _produtoId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecione o produto para transferir';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Mostrar estoque atual na loja origem
                            if (_produtoId != null)
                              FutureBuilder<int>(
                                future: ref
                                    .read(movimentacaoEstoqueProvider.notifier)
                                    .getEstoqueAtual(_produtoId!),
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
                                                  'Estoque Atual (Loja Origem)',
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

                            // Loja destino
                            lojasAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) =>
                                  const Text('Erro ao carregar lojas'),
                              data: (lojas) => DropdownButtonFormField<String>(
                                value: _lojaDestinoId,
                                decoration: const InputDecoration(
                                  labelText: 'Loja Destino *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.store,
                                    color: Colors.green,
                                  ),
                                ),
                                items: lojas
                                    .where(
                                      (loja) => loja.id != lojaAtiva,
                                    ) // Excluir loja ativa
                                    .map((loja) {
                                      return DropdownMenuItem(
                                        value: loja.id,
                                        child: Text(loja.nome),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _lojaDestinoId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecione a loja de destino';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Quantidade
                            TextFormField(
                              controller: _quantidadeController,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_loading,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a quantidade';
                                }
                                final quantidade = int.tryParse(value);
                                if (quantidade == null || quantidade <= 0) {
                                  return 'Quantidade deve ser um número positivo';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Observação
                            TextFormField(
                              controller: _observacaoController,
                              decoration: const InputDecoration(
                                labelText: 'Observação',
                                border: OutlineInputBorder(),
                                hintText:
                                    'Ex: Transferência para reposição, demanda alta, etc.',
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
                                            context.go(
                                              '/transferencias-estoque',
                                            );
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
                                      backgroundColor: Colors.purple,
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
                                        : const Text('Registrar Transferência'),
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
                                    'Como Funciona a Transferência',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoItem(
                                'Loja Origem',
                                'Loja de onde o produto será removido (loja ativa)',
                                Icons.store,
                                Colors.red,
                              ),
                              _buildInfoItem(
                                'Loja Destino',
                                'Loja para onde o produto será enviado',
                                Icons.store,
                                Colors.green,
                              ),
                              _buildInfoItem(
                                'Dois Registros',
                                'Serão criados dois registros: um de saída na origem e outro de entrada no destino',
                                Icons.swap_vert,
                                Colors.purple,
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
                                    'Dicas para Transferências',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTipItem(
                                'Verifique se há estoque suficiente na loja origem',
                              ),
                              _buildTipItem(
                                'Confirme a quantidade antes de finalizar a transferência',
                              ),
                              _buildTipItem(
                                'Use observações para documentar o motivo da transferência',
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
