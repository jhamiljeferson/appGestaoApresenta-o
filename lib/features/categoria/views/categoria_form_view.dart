import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/categoria_controller.dart';
import '../models/categoria_model.dart';

class CategoriaFormView extends ConsumerStatefulWidget {
  final CategoriaModel? categoria;
  const CategoriaFormView({super.key, this.categoria});

  @override
  ConsumerState<CategoriaFormView> createState() => _CategoriaFormViewState();
}

class _CategoriaFormViewState extends ConsumerState<CategoriaFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.categoria?.nome ?? '');
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final nome = nomeController.text.trim();
    final categoria = widget.categoria == null
        ? CategoriaModel.nova(nome)
        : CategoriaModel(id: widget.categoria!.id, nome: nome);
    try {
      if (widget.categoria == null) {
        // Verificar se é a primeira categoria
        final hasCategorias = await ref
            .read(categoriaProvider.notifier)
            .hasCategorias();
        await ref.read(categoriaProvider.notifier).addCategoria(categoria);

        if (!mounted) return;

        if (!hasCategorias) {
          AppFeedback.showSuccess(
            context,
            'Primeira categoria criada com sucesso! Agora você pode começar a organizar seus produtos.',
          );
        } else {
          AppFeedback.showSuccess(context, 'Categoria criada com sucesso!');
        }
      } else {
        await ref.read(categoriaProvider.notifier).updateCategoria(categoria);

        if (!mounted) return;

        AppFeedback.showSuccess(context, 'Categoria atualizada com sucesso!');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Erro ao salvar categoria: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
                  widget.categoria == null
                      ? 'Nova Categoria'
                      : 'Editar Categoria',
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
