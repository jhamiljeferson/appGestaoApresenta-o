import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/estoque_controller.dart';
import '../models/estoque_model.dart';
import '../../produto/controllers/produto_controller.dart';
import '../../lojas/controllers/loja_controller.dart';

class EstoqueFormView extends ConsumerStatefulWidget {
  final EstoqueModel? estoque;
  const EstoqueFormView({Key? key, this.estoque}) : super(key: key);

  @override
  ConsumerState<EstoqueFormView> createState() => _EstoqueFormViewState();
}

class _EstoqueFormViewState extends ConsumerState<EstoqueFormView> {
  final _formKey = GlobalKey<FormState>();
  String? produtoId;
  String? lojaId;
  late final TextEditingController qtdController;
  late final TextEditingController quantidadeMinimaController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    produtoId = widget.estoque?.produtoId;
    lojaId = widget.estoque?.lojaId;
    qtdController = TextEditingController(
      text: widget.estoque?.qtd.toString() ?? '',
    );
    quantidadeMinimaController = TextEditingController(
      text: widget.estoque?.quantidadeMinima.toString() ?? '',
    );
  }

  @override
  void dispose() {
    qtdController.dispose();
    quantidadeMinimaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final estoque = widget.estoque == null
          ? EstoqueModel.novo(
              produtoId: produtoId!,
              lojaId: lojaId!,
              qtd: int.parse(qtdController.text),
              quantidadeMinima: int.parse(quantidadeMinimaController.text),
            )
          : EstoqueModel(
              id: widget.estoque!.id,
              produtoId: produtoId!,
              lojaId: lojaId!,
              qtd: int.parse(qtdController.text),
              quantidadeMinima: int.parse(quantidadeMinimaController.text),
            );
      if (widget.estoque == null) {
        await ref.read(estoqueProvider.notifier).addEstoque(estoque);
        AppFeedback.showSuccess(context, 'Estoque criado com sucesso!');
      } else {
        await ref.read(estoqueProvider.notifier).updateEstoque(estoque);
        AppFeedback.showSuccess(context, 'Estoque atualizado com sucesso!');
      }
      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, 'Erro ao salvar estoque');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtosAsync = ref.watch(produtoProvider);
    final lojasAsync = ref.watch(lojaProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.estoque == null ? 'Novo Estoque' : 'Editar Estoque',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  produtosAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('Erro ao carregar produtos'),
                    data: (produtos) => DropdownButtonFormField<String>(
                      value: produtoId,
                      decoration: const InputDecoration(labelText: 'Produto'),
                      items: produtos
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(p.nome),
                            ),
                          )
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => produtoId = v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Selecione um produto'
                          : null,
                    ),
                  ),
                  lojasAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('Erro ao carregar lojas'),
                    data: (lojas) => DropdownButtonFormField<String>(
                      value: lojaId,
                      decoration: const InputDecoration(labelText: 'Loja'),
                      items: lojas
                          .map(
                            (l) => DropdownMenuItem<String>(
                              value: l.id,
                              child: Text(l.nome),
                            ),
                          )
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => lojaId = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Selecione uma loja' : null,
                    ),
                  ),
                  TextFormField(
                    controller: qtdController,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Obrigatório'
                        : int.tryParse(v) == null
                        ? 'Inválido'
                        : null,
                    enabled: !_loading,
                  ),
                  TextFormField(
                    controller: quantidadeMinimaController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade Mínima',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Obrigatório'
                        : int.tryParse(v) == null
                        ? 'Inválido'
                        : null,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
      ),
    );
  }
}
