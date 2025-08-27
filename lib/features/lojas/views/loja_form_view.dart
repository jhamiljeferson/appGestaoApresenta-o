import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/loja_controller.dart';
import '../models/loja_model.dart';

class LojaFormView extends ConsumerStatefulWidget {
  final LojaModel? loja;
  const LojaFormView({super.key, this.loja});

  @override
  ConsumerState<LojaFormView> createState() => _LojaFormViewState();
}

class _LojaFormViewState extends ConsumerState<LojaFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  late final TextEditingController shoppingController;
  late final TextEditingController andarController;
  late final TextEditingController numeroController;
  late final TextEditingController quantidadeMinimaAtacadoController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.loja?.nome ?? '');
    shoppingController = TextEditingController(
      text: widget.loja?.shopping ?? '',
    );
    andarController = TextEditingController(text: widget.loja?.andar ?? '');
    numeroController = TextEditingController(text: widget.loja?.numero ?? '');
    quantidadeMinimaAtacadoController = TextEditingController(
      text: (widget.loja?.quantidadeMinimaAtacado ?? 4).toString(),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    shoppingController.dispose();
    andarController.dispose();
    numeroController.dispose();
    quantidadeMinimaAtacadoController.dispose();
    super.dispose();
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
                  widget.loja == null ? 'Nova Loja' : 'Editar Loja',
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
                ),
                AppTextField(
                  label: 'Shopping',
                  controller: shoppingController,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Shopping obrigatório' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Andar',
                        controller: andarController,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Andar obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Número',
                        controller: numeroController,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Número obrigatório'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Quantidade Mínima para Atacado',
                  controller: quantidadeMinimaAtacadoController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Quantidade mínima obrigatória';
                    }
                    final quantidade = int.tryParse(v);
                    if (quantidade == null || quantidade <= 0) {
                      return 'Quantidade deve ser um número maior que zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _loading
                    ? const AppLoading()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _loading = true);
                                final currentContext = context;
                                try {
                                  final loja = LojaModel(
                                    id: widget.loja?.id ?? '',
                                    nome: nomeController.text,
                                    shopping: shoppingController.text,
                                    andar: andarController.text,
                                    numero: numeroController.text,
                                    quantidadeMinimaAtacado: int.parse(
                                      quantidadeMinimaAtacadoController.text,
                                    ),
                                  );
                                  if (widget.loja == null) {
                                    await ref
                                        .read(lojaProvider.notifier)
                                        .addLoja(loja);
                                    if (mounted) {
                                      AppFeedback.showSuccess(
                                        currentContext,
                                        'Loja criada com sucesso!',
                                      );
                                    }
                                  } else {
                                    await ref
                                        .read(lojaProvider.notifier)
                                        .updateLoja(loja);
                                    if (mounted) {
                                      AppFeedback.showSuccess(
                                        currentContext,
                                        'Loja atualizada com sucesso!',
                                      );
                                    }
                                  }
                                  if (mounted) {
                                    Navigator.of(currentContext).pop();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AppFeedback.showError(
                                      currentContext,
                                      'Erro ao salvar loja',
                                    );
                                  }
                                } finally {
                                  setState(() => _loading = false);
                                }
                              }
                            },
                            child: Text(
                              widget.loja == null ? 'Salvar' : 'Atualizar',
                            ),
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
