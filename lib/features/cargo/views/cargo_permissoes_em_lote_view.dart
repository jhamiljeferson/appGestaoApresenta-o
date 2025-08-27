import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_loading.dart';
import '../controllers/cargo_controller.dart';
import '../models/cargo_model.dart';
import '../models/permissao_model.dart';

class CargoPermissoesEmLoteView extends ConsumerStatefulWidget {
  const CargoPermissoesEmLoteView({Key? key}) : super(key: key);

  @override
  ConsumerState<CargoPermissoesEmLoteView> createState() =>
      _CargoPermissoesEmLoteViewState();
}

class _CargoPermissoesEmLoteViewState
    extends ConsumerState<CargoPermissoesEmLoteView> {
  final Map<String, List<String>> _permissoesPorCargo = {};
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Permissões em Lote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarTodasPermissoes,
            tooltip: 'Salvar todas as alterações',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com estatísticas
          _buildHeader(),

          // Lista de cargos com permissões
          Expanded(child: _buildCargosList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerenciamento de Permissões em Lote',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie as permissões de todos os cargos de uma vez. '
              'As alterações serão aplicadas em lote para melhor performance.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recarregar'),
                  onPressed: _loading ? null : _recarregarDados,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_box),
                  label: const Text('Selecionar Todos'),
                  onPressed: _loading ? null : _selecionarTodasPermissoes,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_box_outline_blank),
                  label: const Text('Desmarcar Todos'),
                  onPressed: _loading ? null : _desmarcarTodasPermissoes,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargosList() {
    return Consumer(
      builder: (context, ref, child) {
        final cargosAsync = ref.watch(cargosComPermissoesEmLoteProvider);

        return cargosAsync.when(
          loading: () => const AppLoading(),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar cargos: $error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _recarregarDados,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (cargosComPermissoes) {
            // Inicializar o mapa de permissões se estiver vazio
            if (_permissoesPorCargo.isEmpty) {
              for (final item in cargosComPermissoes) {
                final cargo = item['cargo'] as CargoModel;
                final permissoes = item['permissoes'] as List<PermissaoModel>;
                _permissoesPorCargo[cargo.id] = permissoes
                    .map((p) => p.id)
                    .toList();
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cargosComPermissoes.length,
              itemBuilder: (context, index) {
                final item = cargosComPermissoes[index];
                final cargo = item['cargo'] as CargoModel;
                final permissoes = item['permissoes'] as List<PermissaoModel>;
                final quantidadePermissoes =
                    item['quantidadePermissoes'] as int;

                return _buildCargoCard(cargo, permissoes, quantidadePermissoes);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCargoCard(
    CargoModel cargo,
    List<PermissaoModel> permissoes,
    int quantidadePermissoes,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do cargo
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cargo.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$quantidadePermissoes permissões',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Botões de ação rápida
                PopupMenuButton<String>(
                  onSelected: (action) => _executarAcaoRapida(action, cargo.id),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select_all',
                      child: Row(
                        children: [
                          Icon(Icons.check_box),
                          SizedBox(width: 8),
                          Text('Selecionar Todas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'deselect_all',
                      child: Row(
                        children: [
                          Icon(Icons.check_box_outline_blank),
                          SizedBox(width: 8),
                          Text('Desmarcar Todas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'select_common',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text('Permissões Comuns'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grid de permissões
            _buildPermissoesGrid(cargo.id, permissoes),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissoesGrid(String cargoId, List<PermissaoModel> permissoes) {
    // Agrupar permissões por recurso
    final Map<String, List<PermissaoModel>> agrupadas = {};
    for (final p in permissoes) {
      final recurso = p.recurso;
      agrupadas.putIfAbsent(recurso, () => []).add(p);
    }

    final List<String> recursos = agrupadas.keys.toList()..sort();

    return Column(
      children: recursos.map((recurso) {
        final perms = agrupadas[recurso]!;

        // Ordenar ações na ordem padrão
        const ordemAcoes = ['criar', 'listar', 'atualizar', 'deletar'];
        perms.sort(
          (a, b) =>
              ordemAcoes.indexOf(a.acao).compareTo(ordemAcoes.indexOf(b.acao)),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do recurso
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recurso[0].toUpperCase() + recurso.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Switch para marcar/desmarcar todas as permissões do recurso
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: perms.every(
                        (p) =>
                            _permissoesPorCargo[cargoId]?.contains(p.id) ??
                            false,
                      ),
                      onChanged: _loading
                          ? null
                          : (value) {
                              setState(() {
                                if (value) {
                                  // Marcar todas as permissões do recurso
                                  for (final p in perms) {
                                    _permissoesPorCargo[cargoId]?.add(p.id);
                                  }
                                } else {
                                  // Desmarcar todas as permissões do recurso
                                  for (final p in perms) {
                                    _permissoesPorCargo[cargoId]?.remove(p.id);
                                  }
                                }
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Grid de permissões
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: perms.map((permissao) {
                  final isSelected =
                      _permissoesPorCargo[cargoId]?.contains(permissao.id) ??
                      false;

                  return FilterChip(
                    label: Text(permissao.acao),
                    selected: isSelected,
                    onSelected: _loading
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _permissoesPorCargo[cargoId]?.add(permissao.id);
                              } else {
                                _permissoesPorCargo[cargoId]?.remove(
                                  permissao.id,
                                );
                              }
                            });
                          },
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==================================
  // MÉTODOS DE AÇÃO
  // ==================================

  Future<void> _recarregarDados() async {
    setState(() => _loading = true);
    try {
      ref.invalidate(cargosComPermissoesEmLoteProvider);
      _permissoesPorCargo.clear();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selecionarTodasPermissoes() {
    setState(() {
      for (final cargoId in _permissoesPorCargo.keys) {
        // Buscar todas as permissões disponíveis para este cargo
        final cargosAsync = ref.read(cargosComPermissoesEmLoteProvider);
        cargosAsync.whenData((cargosComPermissoes) {
          final cargoItem = cargosComPermissoes.firstWhere(
            (item) => (item['cargo'] as CargoModel).id == cargoId,
          );
          final permissoes = cargoItem['permissoes'] as List<PermissaoModel>;
          _permissoesPorCargo[cargoId] = permissoes.map((p) => p.id).toList();
        });
      }
    });
  }

  void _desmarcarTodasPermissoes() {
    setState(() {
      for (final cargoId in _permissoesPorCargo.keys) {
        _permissoesPorCargo[cargoId]?.clear();
      }
    });
  }

  void _executarAcaoRapida(String action, String cargoId) {
    setState(() {
      switch (action) {
        case 'select_all':
          // Buscar todas as permissões disponíveis para este cargo
          final cargosAsync = ref.read(cargosComPermissoesEmLoteProvider);
          cargosAsync.whenData((cargosComPermissoes) {
            final cargoItem = cargosComPermissoes.firstWhere(
              (item) => (item['cargo'] as CargoModel).id == cargoId,
            );
            final permissoes = cargoItem['permissoes'] as List<PermissaoModel>;
            _permissoesPorCargo[cargoId] = permissoes.map((p) => p.id).toList();
          });
          break;
        case 'deselect_all':
          _permissoesPorCargo[cargoId]?.clear();
          break;
        case 'select_common':
          // Selecionar apenas permissões comuns (criar, listar)
          final cargosAsync = ref.read(cargosComPermissoesEmLoteProvider);
          cargosAsync.whenData((cargosComPermissoes) {
            final cargoItem = cargosComPermissoes.firstWhere(
              (item) => (item['cargo'] as CargoModel).id == cargoId,
            );
            final permissoes = cargoItem['permissoes'] as List<PermissaoModel>;
            final permissoesComuns = permissoes
                .where((p) => ['criar', 'listar'].contains(p.acao))
                .map((p) => p.id)
                .toList();
            _permissoesPorCargo[cargoId] = permissoesComuns;
          });
          break;
      }
    });
  }

  Future<void> _salvarTodasPermissoes() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final controller = ref.read(cargoProvider.notifier);
      int sucessos = 0;
      int erros = 0;
      List<String> errosDetalhados = [];

      for (final entry in _permissoesPorCargo.entries) {
        try {
          print('🔧 [View] Salvando permissões para cargo: ${entry.key}');
          print('🔧 [View] Quantidade de permissões: ${entry.value.length}');

          await controller.sincronizarPermissoesEmLote(entry.key, entry.value);
          sucessos++;

          print('✅ [View] Cargo ${entry.key} salvo com sucesso');
        } catch (e) {
          print('❌ [View] Erro ao salvar permissões do cargo ${entry.key}: $e');
          erros++;

          // Adicionar detalhes do erro para debug
          String erroDetalhado = 'Cargo ${entry.key}: ${e.toString()}';
          if (e.toString().contains('Cargo não encontrado')) {
            erroDetalhado += ' - Verifique se o cargo ainda existe no banco';
          } else if (e.toString().contains('Permissões inválidas')) {
            erroDetalhado += ' - Verifique se as permissões são válidas';
          }
          errosDetalhados.add(erroDetalhado);
        }
      }

      // Recarregar dados
      await _recarregarDados();

      // Mostrar feedback detalhado
      if (erros == 0) {
        AppFeedback.showSuccess(
          context,
          'Todas as permissões foram salvas com sucesso! ($sucessos cargos)',
        );
      } else {
        // Mostrar erro com detalhes
        String mensagemErro = 'Permissões salvas com alguns erros:\n';
        mensagemErro += '✅ $sucessos sucessos\n';
        mensagemErro += '❌ $erros erros\n\n';
        mensagemErro += 'Detalhes dos erros:\n';
        mensagemErro += errosDetalhados.take(3).join('\n');

        if (errosDetalhados.length > 3) {
          mensagemErro += '\n... e mais ${errosDetalhados.length - 3} erros';
        }

        AppFeedback.showError(context, mensagemErro);
      }
    } catch (e) {
      print('❌ [View] Erro geral ao salvar permissões: $e');
      AppFeedback.showError(context, 'Erro geral ao salvar permissões: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}
