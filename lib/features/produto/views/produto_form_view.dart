import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/produto_controller.dart';
import '../models/produto_model.dart';
import '../../categoria/controllers/categoria_controller.dart';
import '../../fornecedor/controllers/fornecedor_controller.dart';

class ProdutoFormView extends ConsumerStatefulWidget {
  final ProdutoModel? produto;
  const ProdutoFormView({Key? key, this.produto}) : super(key: key);

  @override
  ConsumerState<ProdutoFormView> createState() => _ProdutoFormViewState();
}

class _ProdutoFormViewState extends ConsumerState<ProdutoFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  late final TextEditingController skuController;
  late final TextEditingController codigoController;
  late final TextEditingController precoCustoController;
  late final TextEditingController precoAtacadoController;
  late final TextEditingController precoPromocionalController;
  late final TextEditingController precoVarejoController;
  String? categoriaId;
  String? fornecedorId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.produto?.nome ?? '');
    skuController = TextEditingController(text: widget.produto?.sku ?? '');
    codigoController = TextEditingController(
      text: widget.produto?.codigo ?? '',
    );
    precoCustoController = TextEditingController(
      text: widget.produto?.precoCusto.toString() ?? '',
    );
    precoAtacadoController = TextEditingController(
      text: widget.produto?.precoAtacado.toString() ?? '',
    );
    precoPromocionalController = TextEditingController(
      text: widget.produto?.precoPromocional?.toString() ?? '',
    );
    precoVarejoController = TextEditingController(
      text: widget.produto?.precoVarejo.toString() ?? '',
    );
    categoriaId = widget.produto?.categoriaId;
    fornecedorId = widget.produto?.fornecedorId;
  }

  @override
  void dispose() {
    nomeController.dispose();
    skuController.dispose();
    codigoController.dispose();
    precoCustoController.dispose();
    precoAtacadoController.dispose();
    precoPromocionalController.dispose();
    precoVarejoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final produto = widget.produto == null
          ? ProdutoModel.novo(
              nome: nomeController.text.trim(),
              sku: skuController.text.trim(),
              codigo: codigoController.text.trim(),
              precoCusto: double.parse(precoCustoController.text),
              precoAtacado: double.parse(precoAtacadoController.text),
              precoPromocional: precoPromocionalController.text.isNotEmpty
                  ? double.parse(precoPromocionalController.text)
                  : null,
              precoVarejo: double.parse(precoVarejoController.text),
              categoriaId: categoriaId!,
              fornecedorId: fornecedorId ?? '',
            )
          : ProdutoModel(
              id: widget.produto!.id,
              nome: nomeController.text.trim(),
              sku: skuController.text.trim(),
              codigo: codigoController.text.trim(),
              precoCusto: double.parse(precoCustoController.text),
              precoAtacado: double.parse(precoAtacadoController.text),
              precoPromocional: precoPromocionalController.text.isNotEmpty
                  ? double.parse(precoPromocionalController.text)
                  : null,
              precoVarejo: double.parse(precoVarejoController.text),
              categoriaId: categoriaId!,
              fornecedorId: fornecedorId ?? '',
            );
      if (widget.produto == null) {
        await ref.read(produtoProvider.notifier).addProduto(produto);
        AppFeedback.showSuccess(context, 'Produto criado com sucesso!');
      } else {
        await ref.read(produtoProvider.notifier).updateProduto(produto);
        AppFeedback.showSuccess(context, 'Produto atualizado com sucesso!');
      }
      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, 'Erro ao salvar produto');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriaProvider);
    final fornecedoresAsync = ref.watch(fornecedorProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.produto == null ? 'Novo Produto' : 'Editar Produto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Nome',
                    controller: nomeController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nome obrigatório' : null,
                    enabled: !_loading,
                  ),
                  AppTextField(
                    label: 'SKU',
                    controller: skuController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'SKU obrigatório' : null,
                    enabled: !_loading,
                  ),
                  AppTextField(
                    label: 'Código',
                    controller: codigoController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Código obrigatório' : null,
                    enabled: !_loading,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Preço Custo',
                          controller: precoCustoController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Obrigatório'
                              : double.tryParse(v) == null
                              ? 'Inválido'
                              : null,
                          enabled: !_loading,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Preço Atacado',
                          controller: precoAtacadoController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Obrigatório'
                              : double.tryParse(v) == null
                              ? 'Inválido'
                              : null,
                          enabled: !_loading,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Preço Promocional',
                          controller: precoPromocionalController,
                          validator: (v) =>
                              v != null &&
                                  v.isNotEmpty &&
                                  double.tryParse(v) == null
                              ? 'Inválido'
                              : null,
                          enabled: !_loading,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Preço Varejo',
                          controller: precoVarejoController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Obrigatório'
                              : double.tryParse(v) == null
                              ? 'Inválido'
                              : null,
                          enabled: !_loading,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  categoriasAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => const Text('Erro ao carregar categorias'),
                    data: (categorias) => DropdownButtonFormField<String>(
                      value: categoriaId,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: categorias
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.nome),
                            ),
                          )
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => categoriaId = v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Selecione uma categoria'
                          : null,
                    ),
                  ),
                  fornecedoresAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) =>
                        const Text('Erro ao carregar fornecedores'),
                    data: (fornecedores) => DropdownButtonFormField<String>(
                      value: fornecedorId?.isNotEmpty == true
                          ? fornecedorId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Nenhum'),
                        ),
                        ...fornecedores.map(
                          (f) => DropdownMenuItem<String>(
                            value: f.id,
                            child: Text(f.nome),
                          ),
                        ),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => fornecedorId = v),
                    ),
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
