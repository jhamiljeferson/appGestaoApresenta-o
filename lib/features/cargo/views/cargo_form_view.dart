import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/cargo_controller.dart';
import '../models/cargo_model.dart';
import '../models/permissao_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cargo_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../usuario/controllers/usuario_controller.dart';

class CargoFormView extends ConsumerStatefulWidget {
  final CargoModel? cargo;
  const CargoFormView({Key? key, this.cargo}) : super(key: key);

  @override
  ConsumerState<CargoFormView> createState() => _CargoFormViewState();
}

class _CargoFormViewState extends ConsumerState<CargoFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  bool _loading = false;
  List<PermissaoModel> permissoes = [];
  List<String> permissoesSelecionadas = [];

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.cargo?.nome ?? '');
    if (widget.cargo != null) {
      // Ao editar, buscar permissões vinculadas
      Future.microtask(() async {
        final permissoesIds = await ref.read(
          permissoesIdsDoCargoProvider(widget.cargo!.id).future,
        );
        setState(() {
          permissoesSelecionadas = List<String>.from(permissoesIds);
        });
      });
    } else {
      permissoesSelecionadas = [];
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final nome = nomeController.text.trim();

      if (widget.cargo == null) {
        // Criar novo cargo
        final cargo = CargoModel.novo(nome);

        // IMPORTANTE: Usar o cargo retornado com o ID correto
        final cargoCriado = await ref
            .read(cargoProvider.notifier)
            .addCargo(cargo);

        print('🔧 [CargoFormView] Cargo criado com ID: ${cargoCriado.id}');
        print('🔧 [CargoFormView] Cargo original tinha ID: ${cargo.id}');

        // Salvar permissões do cargo usando o ID correto
        if (permissoesSelecionadas.isNotEmpty) {
          await ref
              .read(cargoProvider.notifier)
              .salvarPermissoesDoCargo(cargoCriado.id, permissoesSelecionadas);
        }

        AppFeedback.showSuccess(context, 'Cargo criado com sucesso!');
      } else {
        // Atualizar cargo existente
        final cargo = CargoModel(
          id: widget.cargo!.id,
          nome: nome,
          criadoPor: widget.cargo!.criadoPor,
          atualizadoPor: widget.cargo!.atualizadoPor,
        );

        await ref.read(cargoProvider.notifier).updateCargo(cargo);

        // Salvar permissões do cargo
        await ref
            .read(cargoProvider.notifier)
            .salvarPermissoesDoCargo(cargo.id, permissoesSelecionadas);

        AppFeedback.showSuccess(context, 'Cargo atualizado com sucesso!');
      }

      // Invalida o provider de permissões do cargo editado
      ref.invalidate(permissoesDoCargoProvider(widget.cargo?.id ?? ''));
      ref.invalidate(permissoesIdsDoCargoProvider(widget.cargo?.id ?? ''));

      // Invalida o provider de permissões do usuário logado se for o mesmo cargo
      final loggedCargoId = await AuthController.getCargoIdUsuarioLogado();
      if (loggedCargoId == widget.cargo?.id) {
        ref.invalidate(permissoesUsuarioProvider(loggedCargoId));
      }

      Navigator.of(context).pop();
    } catch (e) {
      print('❌ [CargoFormView] Erro ao salvar cargo: $e');
      AppFeedback.showError(context, 'Erro ao salvar cargo: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Widget> _buildPermissoesAgrupadas() {
    // Agrupa permissões por recurso
    final Map<String, List<PermissaoModel>> agrupadas = {};
    for (final p in permissoes) {
      final recurso = p.recurso;
      agrupadas.putIfAbsent(recurso, () => []).add(p);
    }

    final List<String> recursos = agrupadas.keys.toList()..sort();

    return recursos.map((recurso) {
      final perms = agrupadas[recurso]!;

      // Ordena as ações na ordem padrão
      const ordemAcoes = ['criar', 'listar', 'atualizar', 'deletar'];
      perms.sort(
        (a, b) =>
            ordemAcoes.indexOf(a.acao).compareTo(ordemAcoes.indexOf(b.acao)),
      );

      // Verifica se todas as permissões desse recurso estão selecionadas
      final allSelected = perms.every(
        (p) => permissoesSelecionadas.contains(p.id),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recurso[0].toUpperCase() + recurso.substring(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.scale(
                    scale: 0.7, // reduz o tamanho do switch
                    child: Switch(
                      value: allSelected,
                      onChanged: _loading
                          ? null
                          : (v) {
                              setState(() {
                                if (v) {
                                  // Marca todas as permissões desse recurso
                                  for (final p in perms) {
                                    if (!permissoesSelecionadas.contains(
                                      p.id,
                                    )) {
                                      permissoesSelecionadas.add(p.id);
                                    }
                                  }
                                } else {
                                  // Desmarca todas as permissões desse recurso
                                  for (final p in perms) {
                                    permissoesSelecionadas.remove(p.id);
                                  }
                                }
                              });
                            },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8, // espaçamento vertical entre linhas
              children: perms.map((p) {
                return FilterChip(
                  label: Text(p.acao),
                  selected: permissoesSelecionadas.contains(p.id),
                  onSelected: _loading
                      ? null
                      : (v) {
                          setState(() {
                            if (v) {
                              permissoesSelecionadas.add(p.id);
                            } else {
                              permissoesSelecionadas.remove(p.id);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.cargo == null ? 'Novo Cargo' : 'Editar Cargo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nome',
                  controller: nomeController,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nome obrigatório' : null,
                  enabled: !_loading,
                ),
                const SizedBox(height: 16),

                // Carrega permissões usando o provider
                Consumer(
                  builder: (context, ref, child) {
                    final permissoesAsync = ref.watch(permissoesProvider);

                    return permissoesAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Erro ao carregar permissões: $e'),
                      data: (permissoesData) {
                        permissoes = permissoesData;

                        if (permissoes.isEmpty) {
                          return const Text('Nenhuma permissão encontrada');
                        }

                        return SizedBox(
                          height: 300, // altura máxima para rolagem
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Permissões do Cargo',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.check_box,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Marcar todos',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 32),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              setState(() {
                                                permissoesSelecionadas =
                                                    permissoes
                                                        .map((p) => p.id)
                                                        .toList();
                                              });
                                            },
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.check_box_outline_blank,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Desmarcar todos',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 32),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              setState(() {
                                                permissoesSelecionadas.clear();
                                              });
                                            },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ..._buildPermissoesAgrupadas(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _salvar,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
