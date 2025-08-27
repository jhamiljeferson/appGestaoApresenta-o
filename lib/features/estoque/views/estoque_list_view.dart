import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/estoque_controller.dart';
import '../models/estoque_model.dart';
import '../services/estoque_service.dart';
import '../../produto/controllers/produto_controller.dart';
import '../../produto/models/produto_model.dart';
import '../../lojas/controllers/loja_controller.dart';
import '../../lojas/models/loja_model.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../categoria/controllers/categoria_controller.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/services/user_audit_service.dart';

class EstoqueListView extends ConsumerStatefulWidget {
  const EstoqueListView({super.key});

  @override
  ConsumerState<EstoqueListView> createState() => _EstoqueListViewState();
}

class _EstoqueListViewState extends ConsumerState<EstoqueListView> {
  @override
  void initState() {
    super.initState();
    // Carregar estoque quando a tela for montada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(estoqueProvider.notifier).loadEstoques();
    });
  }

  Future<void> _editarQuantidadeMinima(EstoqueModel estoque) async {
    final TextEditingController controller = TextEditingController(
      text: estoque.quantidadeMinima.toString(),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Quantidade Mínima'),
          content: FutureBuilder<String>(
            future: _getNomeProduto(estoque.produtoId),
            builder: (context, snapshot) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Produto: ${snapshot.data ?? 'Carregando...'}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade Mínima',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final novaQuantidade = int.tryParse(result);
      if (novaQuantidade != null && novaQuantidade >= 0) {
        try {
          final estoqueService = EstoqueService();
          final usuarioId = await UserAuditService().getUsuarioId();

          final estoqueAtualizado = estoque.copyWith(
            quantidadeMinima: novaQuantidade,
            atualizadoPor: usuarioId,
            atualizadoEm: DateTime.now(),
          );

          await estoqueService.updateEstoque(estoqueAtualizado);

          if (!mounted) return;
          AppFeedback.showSuccess(
            context,
            'Quantidade mínima atualizada com sucesso!',
          );

          // Recarregar a lista
          ref.read(estoqueProvider.notifier).loadEstoques();
        } catch (e) {
          if (!mounted) return;
          AppFeedback.showError(
            context,
            'Erro ao atualizar quantidade mínima: $e',
          );
        }
      } else {
        if (!mounted) return;
        AppFeedback.showError(context, 'Quantidade inválida');
      }
    }
  }

  Future<String> _getNomeProduto(String produtoId) async {
    try {
      final produtosAsync = ref.read(produtoProvider);
      final produtos = produtosAsync.when(
        data: (data) => data,
        loading: () => throw Exception('Erro ao carregar produtos'),
        error: (e, _) => throw Exception('Erro ao carregar produtos: $e'),
      );

      final produto = produtos.firstWhere(
        (p) => p.id == produtoId,
        orElse: () => throw Exception('Produto não encontrado'),
      );

      return produto.nome;
    } catch (e) {
      return 'Produto não encontrado';
    }
  }

  Widget _buildStatusChip(EstoqueModel estoque) {
    if (estoque.qtd <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              'Sem estoque',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      );
    } else if (estoque.qtd <= estoque.quantidadeMinima) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_outlined, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Baixo estoque',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'OK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estoqueAsync = ref.watch(estoqueProvider);
    final produtosAsync = ref.watch(produtoProvider);
    final lojasAsync = ref.watch(lojaProvider);
    final categoriasAsync = ref.watch(categoriaProvider);
    final lojaAtiva = ref.watch(lojaAtivaProvider);
    String filtroCategoriaId = '';
    String filtroEstoqueBaixo = '';
    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));
        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Estoque',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Estoque'),
            ],
            currentRoute: '/estoque',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            return MainLayout(
              title: '📦 Controle de Estoque',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Estoque'),
              ],
              currentRoute: '/estoque',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar lista',
                  onPressed: () {
                    ref.read(estoqueProvider.notifier).loadEstoques();
                  },
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    // Header da loja ativa
                    if (lojaAtiva != null && lojaAtiva.isNotEmpty)
                      lojasAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => const Text('Erro ao carregar loja'),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                                  child: Text(
                                    'Estoque da Loja: ${loja.nome}',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (lojaAtiva != null && lojaAtiva.isNotEmpty)
                      const SizedBox(height: 16),
                    // Filtros compactos
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;

                        if (isWide) {
                          // Layout horizontal compacto para telas maiores
                          return Row(
                            children: [
                              // Filtro por categoria
                              categoriasAsync.when(
                                loading: () => const SizedBox(
                                  width: 120,
                                  child: LinearProgressIndicator(),
                                ),
                                error: (e, _) => const SizedBox(
                                  width: 120,
                                  child: Text('Erro'),
                                ),
                                data: (categorias) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<String>(
                                    value: filtroCategoriaId.isEmpty
                                        ? null
                                        : filtroCategoriaId,
                                    hint: const Text(
                                      'Categoria',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    underline: const SizedBox(),
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text(
                                          'Todas',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      ...categorias.map(
                                        (c) => DropdownMenuItem<String>(
                                          value: c.id,
                                          child: Text(
                                            c.nome,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        filtroCategoriaId = v ?? '';
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Filtro por estoque baixo
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButton<String>(
                                  value: filtroEstoqueBaixo.isEmpty
                                      ? null
                                      : filtroEstoqueBaixo,
                                  hint: const Text(
                                    'Status',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                  ),
                                  items: const [
                                    DropdownMenuItem<String>(
                                      value: '',
                                      child: Text(
                                        'Todos',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'baixo',
                                      child: Text(
                                        'Baixo',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'sem',
                                      child: Text(
                                        'Sem',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      filtroEstoqueBaixo = v ?? '';
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Layout vertical compacto para telas pequenas - COMPACTO PARA IPHONE SE
                          return Column(
                            children: [
                              // Filtro por categoria
                              categoriasAsync.when(
                                loading: () => Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                error: (e, _) => Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Erro',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                data: (categorias) => Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.grey.withValues(alpha: 0.05),
                                  ),
                                  child: DropdownButton<String>(
                                    value: filtroCategoriaId.isEmpty
                                        ? null
                                        : filtroCategoriaId,
                                    hint: Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Categoria',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    underline: const SizedBox(),
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text(
                                          'Todas',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      ...categorias.map(
                                        (c) => DropdownMenuItem<String>(
                                          value: c.id,
                                          child: Text(
                                            c.nome,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        filtroCategoriaId = v ?? '';
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Filtro por status
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.grey.withValues(alpha: 0.05),
                                ),
                                child: DropdownButton<String>(
                                  value: filtroEstoqueBaixo.isEmpty
                                      ? null
                                      : filtroEstoqueBaixo,
                                  hint: Row(
                                    children: [
                                      Icon(
                                        Icons.filter_list,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  underline: const SizedBox(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem<String>(
                                      value: '',
                                      child: Text(
                                        'Todos',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'baixo',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_outlined,
                                            size: 14,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Baixo',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'sem',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Sem',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      filtroEstoqueBaixo = v ?? '';
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Resumo estatístico
                    estoqueAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (estoque) {
                        // Filtrar apenas estoque da loja ativa para os cálculos
                        final estoqueLojaAtiva = estoque.where((e) {
                          return lojaAtiva != null && e.lojaId == lojaAtiva;
                        }).toList();

                        final totalProdutos = estoqueLojaAtiva.length;
                        final semEstoque = estoqueLojaAtiva
                            .where((e) => e.qtd <= 0)
                            .length;
                        final baixoEstoque = estoqueLojaAtiva
                            .where(
                              (e) => e.qtd > 0 && e.qtd <= e.quantidadeMinima,
                            )
                            .length;
                        final estoqueOk = estoqueLojaAtiva
                            .where((e) => e.qtd > e.quantidadeMinima)
                            .length;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 600;

                            if (isWide) {
                              // Layout horizontal para telas maiores
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$totalProdutos',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                      ),
                                                ),
                                                Text(
                                                  'Total',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 16,
                                            color: Colors.red[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$semEstoque',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red[700],
                                                      ),
                                                ),
                                                Text(
                                                  'Sem Estoque',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_outlined,
                                            size: 16,
                                            color: Colors.orange[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$baixoEstoque',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                ),
                                                Text(
                                                  'Baixo',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.green.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 16,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$estoqueOk',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                ),
                                                Text(
                                                  'OK',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Layout vertical compacto para telas pequenas (iPhone SE) - 4 EM UMA LINHA
                              return Row(
                                children: [
                                  // Total
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$totalProdutos',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                          ),
                                          Text(
                                            'Total',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Sem
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 16,
                                            color: Colors.red[700],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$semEstoque',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700],
                                                ),
                                          ),
                                          Text(
                                            'Sem',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Baixo
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_outlined,
                                            size: 16,
                                            color: Colors.orange[700],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$baixoEstoque',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                ),
                                          ),
                                          Text(
                                            'Baixo',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // OK
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.green.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 16,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$estoqueOk',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                          ),
                                          Text(
                                            'OK',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Expanded(
                      child: estoqueAsync.when(
                        loading: () => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Carregando estoque...'),
                            ],
                          ),
                        ),
                        error: (e, _) =>
                            Center(child: Text('Erro ao carregar estoque')),
                        data: (estoque) {
                          // Filtrar apenas estoque da loja ativa
                          final estoqueLojaAtiva = estoque.where((e) {
                            return lojaAtiva != null && e.lojaId == lojaAtiva;
                          }).toList();

                          final filtrados = estoqueLojaAtiva.where((e) {
                            // Filtro por categoria
                            final matchCategoria =
                                filtroCategoriaId.isEmpty ||
                                produtosAsync.maybeWhen(
                                  data: (produtos) {
                                    final produto = produtos.firstWhere(
                                      (p) => p.id == e.produtoId,
                                      orElse: () => ProdutoModel(
                                        id: '',
                                        nome: '',
                                        sku: '',
                                        codigo: '',
                                        precoCusto: 0,
                                        precoAtacado: 0,
                                        precoVarejo: 0,
                                        categoriaId: '',
                                        fornecedorId: '',
                                      ),
                                    );
                                    return produto.categoriaId ==
                                        filtroCategoriaId;
                                  },
                                  orElse: () => true,
                                );

                            // Filtro por status do estoque
                            bool matchEstoqueStatus = true;
                            if (filtroEstoqueBaixo.isNotEmpty) {
                              if (filtroEstoqueBaixo == 'sem') {
                                matchEstoqueStatus = e.qtd <= 0;
                              } else if (filtroEstoqueBaixo == 'baixo') {
                                matchEstoqueStatus =
                                    e.qtd > 0 && e.qtd <= e.quantidadeMinima;
                              }
                            }

                            return matchCategoria && matchEstoqueStatus;
                          }).toList();
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 700;
                              if (isWide) {
                                return AppCard(
                                  padding: const EdgeInsets.all(0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Produto')),
                                        DataColumn(
                                          label: Text('Quantidade Atual'),
                                        ),
                                        DataColumn(
                                          label: Text('Estoque Mínimo'),
                                        ),
                                        DataColumn(label: Text('Status')),
                                      ],
                                      rows: filtrados
                                          .map(
                                            (estoque) => DataRow(
                                              cells: [
                                                DataCell(
                                                  produtosAsync.maybeWhen(
                                                    data: (prods) => Text(
                                                      prods
                                                          .firstWhere(
                                                            (p) =>
                                                                p.id ==
                                                                estoque
                                                                    .produtoId,
                                                            orElse: () =>
                                                                ProdutoModel(
                                                                  id: '',
                                                                  nome: '-',
                                                                  sku: '',
                                                                  codigo: '',
                                                                  precoCusto: 0,
                                                                  precoAtacado:
                                                                      0,
                                                                  precoVarejo:
                                                                      0,
                                                                  categoriaId:
                                                                      '',
                                                                  fornecedorId:
                                                                      '',
                                                                ),
                                                          )
                                                          .nome,
                                                    ),
                                                    orElse: () =>
                                                        const Text('-'),
                                                  ),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: estoque.qtd > 0
                                                          ? Colors.green
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                )
                                                          : Colors.red
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: estoque.qtd > 0
                                                            ? Colors.green
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  )
                                                            : Colors.red
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          estoque.qtd > 0
                                                              ? Icons
                                                                    .inventory_2
                                                              : Icons
                                                                    .inventory_2_outlined,
                                                          size: 16,
                                                          color: estoque.qtd > 0
                                                              ? Colors.green
                                                              : Colors.red,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          '${estoque.qtd} unidades',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                estoque.qtd > 0
                                                                ? Colors
                                                                      .green[700]
                                                                : Colors
                                                                      .red[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.orange
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '${estoque.quantidadeMinima} min',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors
                                                                .orange[700],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          size: 16,
                                                        ),
                                                        tooltip:
                                                            'Editar quantidade mínima',
                                                        onPressed: () =>
                                                            _editarQuantidadeMinima(
                                                              estoque,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  _buildStatusChip(estoque),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                              } else {
                                return ListView.builder(
                                  itemCount: filtrados.length,
                                  itemBuilder: (context, index) {
                                    final estoque = filtrados[index];
                                    return AppCard(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      child: InkWell(
                                        onTap: () =>
                                            _editarQuantidadeMinima(estoque),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Informações do produto
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    produtosAsync.maybeWhen(
                                                      data: (prods) => Text(
                                                        prods
                                                            .firstWhere(
                                                              (p) =>
                                                                  p.id ==
                                                                  estoque
                                                                      .produtoId,
                                                              orElse: () =>
                                                                  ProdutoModel(
                                                                    id: '',
                                                                    nome: '-',
                                                                    sku: '',
                                                                    codigo: '',
                                                                    precoCusto:
                                                                        0,
                                                                    precoAtacado:
                                                                        0,
                                                                    precoVarejo:
                                                                        0,
                                                                    categoriaId:
                                                                        '',
                                                                    fornecedorId:
                                                                        '',
                                                                  ),
                                                            )
                                                            .nome,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      orElse: () =>
                                                          const Text('-'),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    _buildStatusChip(estoque),
                                                  ],
                                                ),
                                              ),

                                              // Quantidade atual
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: estoque.qtd > 0
                                                        ? Colors.green
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                        : Colors.red.withValues(
                                                            alpha: 0.1,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: estoque.qtd > 0
                                                          ? Colors.green
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                          : Colors.red
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        estoque.qtd > 0
                                                            ? Icons.inventory_2
                                                            : Icons
                                                                  .inventory_2_outlined,
                                                        size: 14,
                                                        color: estoque.qtd > 0
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${estoque.qtd}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: estoque.qtd > 0
                                                              ? Colors
                                                                    .green[700]
                                                              : Colors.red[700],
                                                        ),
                                                      ),
                                                      Text(
                                                        'Atual',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Estoque mínimo
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.orange
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.settings,
                                                        size: 14,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${estoque.quantidadeMinima}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors
                                                              .orange[700],
                                                        ),
                                                      ),
                                                      Text(
                                                        'Mín',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Botão de editar
                                              IconButton(
                                                onPressed: () =>
                                                    _editarQuantidadeMinima(
                                                      estoque,
                                                    ),
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Colors.orange,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                          );
                        },
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
