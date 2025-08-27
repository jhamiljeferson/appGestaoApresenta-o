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

class NovaMovimentacaoView extends ConsumerStatefulWidget {
  const NovaMovimentacaoView({super.key});

  @override
  ConsumerState<NovaMovimentacaoView> createState() =>
      _NovaMovimentacaoViewState();
}

class _NovaMovimentacaoViewState extends ConsumerState<NovaMovimentacaoView> {
  final _formKey = GlobalKey<FormState>();
  String? produtoId;
  TipoMovimentacao tipoSelecionado = TipoMovimentacao.entrada;
  late final TextEditingController quantidadeController;
  late final TextEditingController observacaoController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    quantidadeController = TextEditingController();
    observacaoController = TextEditingController();
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final lojaId = ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      AppFeedback.showError(
        context,
        'Selecione uma loja ativa para realizar operações.',
      );
      return;
    }

    if (produtoId == null || produtoId!.isEmpty) {
      AppFeedback.showError(context, 'Selecione um produto.');
      return;
    }

    setState(() => _loading = true);

    try {
      final movimentacao = MovimentacaoEstoqueModel.novo(
        lojaId: lojaId,
        produtoId: produtoId!,
        tipo: tipoSelecionado,
        quantidade: int.parse(quantidadeController.text),
        observacao: observacaoController.text.isNotEmpty
            ? observacaoController.text
            : null,
      );

      await ref
          .read(movimentacaoEstoqueProvider.notifier)
          .addMovimentacao(movimentacao);

      AppFeedback.showSuccess(context, 'Movimentação registrada com sucesso!');

      // Limpa o formulário
      setState(() {
        produtoId = null;
        quantidadeController.clear();
        observacaoController.clear();
      });
    } catch (e) {
      AppFeedback.showError(context, 'Erro ao registrar movimentação: $e');
    } finally {
      setState(() => _loading = false);
    }
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
            title: 'Nova Movimentação',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Movimentações'),
              BreadcrumbItem('Nova'),
            ],
            currentRoute: '/nova-movimentacao',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'criar',
            );

            if (!podeCriar) {
              return MainLayout(
                title: 'Nova Movimentação',
                breadcrumbs: const [
                  BreadcrumbItem('Dashboard'),
                  BreadcrumbItem('Movimentações'),
                  BreadcrumbItem('Nova'),
                ],
                currentRoute: '/nova-movimentacao',
                child: const Center(child: Text('Acesso negado')),
              );
            }

            return MainLayout(
              title: 'Nova Movimentação',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Movimentações'),
                BreadcrumbItem('Nova'),
              ],
              currentRoute: '/nova-movimentacao',
              onSidebarItemSelected: (route) => context.go(route),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formulário de movimentação
                    Expanded(
                      flex: 1,
                      child: AppCard(
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
                                      Icons.add_circle_outline,
                                      color: Theme.of(context).primaryColor,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Nova Movimentação',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Loja ativa (somente leitura)
                                if (lojaAtiva != null && lojaAtiva.isNotEmpty)
                                  lojasAsync.when(
                                    loading: () =>
                                        const LinearProgressIndicator(),
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
                                      return TextFormField(
                                        initialValue: loja.nome,
                                        decoration: const InputDecoration(
                                          labelText: 'Loja',
                                          filled: true,
                                          enabled: false,
                                          prefixIcon: Icon(Icons.store),
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 16),

                                // Tipo de movimentação
                                DropdownButtonFormField<TipoMovimentacao>(
                                  value: tipoSelecionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de Movimentação',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  items: TipoMovimentacao.values.map((tipo) {
                                    return DropdownMenuItem<TipoMovimentacao>(
                                      value: tipo,
                                      child: Row(
                                        children: [
                                          Icon(
                                            tipo == TipoMovimentacao.entrada ||
                                                    tipo ==
                                                        TipoMovimentacao
                                                            .trocaEntrada ||
                                                    tipo ==
                                                        TipoMovimentacao
                                                            .transferenciaEntrada
                                                ? Icons.add_circle
                                                : Icons.remove_circle,
                                            color:
                                                tipo ==
                                                        TipoMovimentacao
                                                            .entrada ||
                                                    tipo ==
                                                        TipoMovimentacao
                                                            .trocaEntrada ||
                                                    tipo ==
                                                        TipoMovimentacao
                                                            .transferenciaEntrada
                                                ? Colors.green
                                                : Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_getTipoDisplay(tipo)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _loading
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(
                                              () => tipoSelecionado = value,
                                            );
                                          }
                                        },
                                  validator: (value) =>
                                      value == null ? 'Selecione o tipo' : null,
                                ),

                                const SizedBox(height: 16),

                                // Produto
                                produtosAsync.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) =>
                                      const Text('Erro ao carregar produtos'),
                                  data: (produtos) =>
                                      DropdownButtonFormField<String>(
                                        value: produtoId,
                                        decoration: const InputDecoration(
                                          labelText: 'Produto',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.inventory),
                                        ),
                                        items: produtos.map((produto) {
                                          return DropdownMenuItem<String>(
                                            value: produto.id,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(produto.nome),
                                                Text(
                                                  'SKU: ${produto.sku}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _loading
                                            ? null
                                            : (value) {
                                                setState(
                                                  () => produtoId = value,
                                                );
                                              },
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Selecione um produto'
                                            : null,
                                      ),
                                ),

                                const SizedBox(height: 16),

                                // Quantidade
                                TextFormField(
                                  controller: quantidadeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantidade',
                                    border: OutlineInputBorder(),
                                    hintText: 'Ex: 10',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
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
                                  enabled: !_loading,
                                ),

                                const SizedBox(height: 16),

                                // Observação
                                TextFormField(
                                  controller: observacaoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Observação (opcional)',
                                    border: OutlineInputBorder(),
                                    hintText:
                                        'Ex: Compra de fornecedor, troca de cliente, etc.',
                                    prefixIcon: Icon(Icons.note),
                                  ),
                                  maxLines: 3,
                                  enabled: !_loading,
                                ),

                                const SizedBox(height: 24),

                                // Botão salvar
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _salvar,
                                    style: ElevatedButton.styleFrom(
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
                                            ),
                                          )
                                        : const Text('Registrar Movimentação'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Informações e ajuda
                    Expanded(
                      flex: 1,
                      child: Column(
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
                                        'Informações',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoItem(
                                    'Entrada',
                                    'Adiciona produtos ao estoque',
                                    Icons.add_circle,
                                    Colors.green,
                                  ),
                                  _buildInfoItem(
                                    'Saída',
                                    'Remove produtos do estoque',
                                    Icons.remove_circle,
                                    Colors.red,
                                  ),
                                  _buildInfoItem(
                                    'Troca',
                                    'Movimentação de troca de produtos',
                                    Icons.swap_horiz,
                                    Colors.orange,
                                  ),
                                  _buildInfoItem(
                                    'Transferência',
                                    'Movimentação entre lojas',
                                    Icons.swap_vert,
                                    Colors.blue,
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
                                        'Dicas',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTipItem(
                                    'Verifique sempre a quantidade em estoque antes de fazer saídas',
                                  ),
                                  _buildTipItem(
                                    'Use observações para documentar o motivo da movimentação',
                                  ),
                                  _buildTipItem(
                                    'As movimentações são registradas automaticamente com seu usuário',
                                  ),
                                  _buildTipItem(
                                    'O estoque é atualizado automaticamente após cada movimentação',
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildInfoItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _getTipoDisplay(TipoMovimentacao tipo) {
    switch (tipo) {
      case TipoMovimentacao.entrada:
        return 'Entrada';
      case TipoMovimentacao.saida:
        return 'Saída';
      case TipoMovimentacao.trocaEntrada:
        return 'Troca (Entrada)';
      case TipoMovimentacao.trocaSaida:
        return 'Troca (Saída)';
      case TipoMovimentacao.transferenciaEntrada:
        return 'Transferência (Entrada)';
      case TipoMovimentacao.transferenciaSaida:
        return 'Transferência (Saída)';
    }
  }
}
