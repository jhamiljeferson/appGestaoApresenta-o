import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../controllers/movimentacao_estoque_controller.dart';
import '../models/movimentacao_estoque_model.dart';
import '../../produto/controllers/produto_controller.dart';
import '../../produto/models/produto_model.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../lojas/controllers/loja_controller.dart';
import '../../lojas/models/loja_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../usuario/controllers/usuario_controller.dart';
import '../../usuario/services/usuario_service.dart';

class TransferenciaEstoqueListView extends ConsumerStatefulWidget {
  const TransferenciaEstoqueListView({super.key});

  @override
  ConsumerState<TransferenciaEstoqueListView> createState() =>
      _TransferenciaEstoqueListViewState();
}

class _TransferenciaEstoqueListViewState
    extends ConsumerState<TransferenciaEstoqueListView> {
  final TextEditingController filtroController = TextEditingController();
  String filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movimentacaoEstoqueProvider.notifier).loadMovimentacoes();
    });
  }

  @override
  void dispose() {
    filtroController.dispose();
    super.dispose();
  }

  Future<String> _getNomeUsuario(String? usuarioId) async {
    if (usuarioId == null) return 'Usuário não informado';

    try {
      final usuarioService = UsuarioService();
      final usuarios = await usuarioService.getUsuarios();
      final usuario = usuarios.firstWhere(
        (u) => u.id == usuarioId,
        orElse: () => throw Exception('Usuário não encontrado'),
      );
      return usuario.nome;
    } catch (e) {
      return 'Usuário não encontrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimentacoesAsync = ref.watch(movimentacaoEstoqueProvider);
    final produtosAsync = ref.watch(produtoProvider);
    final lojaAtiva = ref.watch(lojaAtivaProvider);
    final lojasAsync = ref.watch(lojaProvider);

    // Filtra apenas as transferências
    final transferenciasAsync = movimentacoesAsync.when(
      data: (movimentacoes) {
        final transferencias = movimentacoes
            .where(
              (m) =>
                  m.tipo == TipoMovimentacao.transferenciaEntrada ||
                  m.tipo == TipoMovimentacao.transferenciaSaida,
            )
            .toList();
        return AsyncValue.data(transferencias);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );

    return FutureBuilder<String?>(
      future: AuthController.getCargoIdUsuarioLogado(),
      builder: (context, snapshot) {
        final cargoId = snapshot.data;
        final permissoesAsync = ref.watch(permissoesUsuarioProvider(cargoId));

        return permissoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MainLayout(
            title: 'Transferências',
            breadcrumbs: const [
              BreadcrumbItem('Dashboard'),
              BreadcrumbItem('Transferências'),
            ],
            currentRoute: '/transferencias-estoque',
            child: Center(child: Text('Erro ao carregar permissões')),
          ),
          data: (permissoes) {
            final podeListar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'listar',
            );
            final podeCriar = permissoes.any(
              (p) => p['recurso'] == 'estoque' && p['acao'] == 'criar',
            );

            if (!podeListar) {
              return MainLayout(
                title: 'Transferências',
                breadcrumbs: const [
                  BreadcrumbItem('Dashboard'),
                  BreadcrumbItem('Transferências'),
                ],
                currentRoute: '/transferencias-estoque',
                child: const Center(child: Text('Acesso negado')),
              );
            }

            return MainLayout(
              title: '🔄 Transferências de Estoque',
              breadcrumbs: const [
                BreadcrumbItem('Dashboard'),
                BreadcrumbItem('Transferências'),
              ],
              currentRoute: '/transferencias-estoque',
              onSidebarItemSelected: (route) => context.go(route),
              actions: [
                if (podeCriar)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/nova-transferencia-estoque'),
                    icon: const Icon(Icons.swap_vert),
                    label: const Text('Nova Transferência'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
              ],
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;

                  // Header para loja ativa com nome
                  Widget? headerWidget;
                  if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
                    headerWidget = lojasAsync.when(
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 16 : 12,
                            vertical: isWide ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: Colors.purple,
                                size: isWide ? 16 : 14,
                              ),
                              SizedBox(width: isWide ? 6 : 4),
                              Expanded(
                                child: Text(
                                  'Loja Ativa: ${loja.nome}',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.w500,
                                    fontSize: isWide ? 14 : 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (headerWidget != null) ...[
                          headerWidget,
                          const SizedBox(height: 8),
                        ],
                        // Campo de filtro por produto
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: filtroController,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar por produto',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (v) => setState(() => filtro = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        transferenciasAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) =>
                              Center(child: Text('Erro: $error')),
                          data: (transferencias) {
                            // Aplicar filtro por produto
                            final filtradas = filtro.isEmpty
                                ? transferencias
                                : transferencias.where((transferencia) {
                                    return produtosAsync.maybeWhen(
                                      data: (produtos) {
                                        final produto = produtos.firstWhere(
                                          (p) =>
                                              p.id == transferencia.produtoId,
                                          orElse: () => ProdutoModel(
                                            id: '',
                                            nome: '',
                                            sku: '',
                                            codigo: '',
                                            precoCusto: 0,
                                            precoAtacado: 0,
                                            precoVarejo: 0,
                                          ),
                                        );
                                        return produto.nome
                                            .toLowerCase()
                                            .contains(filtro.toLowerCase());
                                      },
                                      orElse: () => false,
                                    );
                                  }).toList();

                            if (transferencias.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.swap_vert,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nenhuma transferência encontrada',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (filtradas.isEmpty && filtro.isNotEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nenhuma transferência encontrada',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (isWide) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Data')),
                                    DataColumn(label: Text('Tipo')),
                                    DataColumn(label: Text('Produto')),
                                    DataColumn(label: Text('Quantidade')),
                                    DataColumn(label: Text('Observação')),
                                    DataColumn(label: Text('Usuário')),
                                  ],
                                  rows: filtradas.map<DataRow>((transferencia) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            '${transferencia.criadoEm.day.toString().padLeft(2, '0')}/${transferencia.criadoEm.month.toString().padLeft(2, '0')}/${transferencia.criadoEm.year}',
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  transferencia.tipo ==
                                                      TipoMovimentacao
                                                          .transferenciaEntrada
                                                  ? Colors.green.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.red.withValues(
                                                      alpha: 0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color:
                                                    transferencia.tipo ==
                                                        TipoMovimentacao
                                                            .transferenciaEntrada
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            child: Text(
                                              transferencia.tipo ==
                                                      TipoMovimentacao
                                                          .transferenciaEntrada
                                                  ? 'Entrada'
                                                  : 'Saída',
                                              style: TextStyle(
                                                color:
                                                    transferencia.tipo ==
                                                        TipoMovimentacao
                                                            .transferenciaEntrada
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          produtosAsync.when(
                                            data: (produtos) {
                                              final produto = produtos.firstWhere(
                                                (p) =>
                                                    p.id ==
                                                    transferencia.produtoId,
                                                orElse: () => ProdutoModel(
                                                  id: '',
                                                  nome:
                                                      'Produto não encontrado',
                                                  sku: '',
                                                  codigo: '',
                                                  precoCusto: 0,
                                                  precoAtacado: 0,
                                                  precoVarejo: 0,
                                                ),
                                              );
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    produto.nome,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'SKU: ${produto.sku}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                            loading: () =>
                                                const Text('Carregando...'),
                                            error: (e, _) => const Text('Erro'),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${transferencia.quantidade} unidades',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            transferencia.observacao ?? '-',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        DataCell(
                                          FutureBuilder<String>(
                                            future: _getNomeUsuario(
                                              transferencia.criadoPor,
                                            ),
                                            builder: (context, snapshot) {
                                              return Text(
                                                snapshot.data ??
                                                    'Usuário não encontrado',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtradas.length,
                              itemBuilder: (context, index) {
                                final transferencia = filtradas[index];
                                return AppCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              transferencia.tipo ==
                                                      TipoMovimentacao
                                                          .transferenciaEntrada
                                                  ? Icons.add_circle
                                                  : Icons.remove_circle,
                                              color:
                                                  transferencia.tipo ==
                                                      TipoMovimentacao
                                                          .transferenciaEntrada
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    transferencia.tipo ==
                                                        TipoMovimentacao
                                                            .transferenciaEntrada
                                                    ? Colors.green.withValues(
                                                        alpha: 0.1,
                                                      )
                                                    : Colors.red.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color:
                                                      transferencia.tipo ==
                                                          TipoMovimentacao
                                                              .transferenciaEntrada
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                              child: Text(
                                                transferencia.tipo ==
                                                        TipoMovimentacao
                                                            .transferenciaEntrada
                                                    ? 'Entrada'
                                                    : 'Saída',
                                                style: TextStyle(
                                                  color:
                                                      transferencia.tipo ==
                                                          TipoMovimentacao
                                                              .transferenciaEntrada
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: produtosAsync.when(
                                                data: (produtos) {
                                                  final produto = produtos.firstWhere(
                                                    (p) =>
                                                        p.id ==
                                                        transferencia.produtoId,
                                                    orElse: () => ProdutoModel(
                                                      id: '',
                                                      nome:
                                                          'Produto não encontrado',
                                                      sku: '',
                                                      codigo: '',
                                                      precoCusto: 0,
                                                      precoAtacado: 0,
                                                      precoVarejo: 0,
                                                    ),
                                                  );
                                                  return Text(
                                                    produto.nome,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                },
                                                loading: () =>
                                                    const Text('Carregando...'),
                                                error: (e, _) =>
                                                    const Text('Erro'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${transferencia.criadoEm.day.toString().padLeft(2, '0')}/${transferencia.criadoEm.month.toString().padLeft(2, '0')}/${transferencia.criadoEm.year}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.inventory,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Qtd: ${transferencia.quantidade}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (transferencia.observacao != null &&
                                            transferencia
                                                .observacao!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Obs: ${transferencia.observacao}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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
