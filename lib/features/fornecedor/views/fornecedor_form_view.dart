import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/fornecedor_controller.dart';
import '../models/fornecedor_model.dart';
import '../services/fornecedor_service.dart';

class FornecedorFormView extends ConsumerStatefulWidget {
  final FornecedorModel? fornecedor;
  const FornecedorFormView({super.key, this.fornecedor});

  @override
  ConsumerState<FornecedorFormView> createState() => _FornecedorFormViewState();
}

class _FornecedorFormViewState extends ConsumerState<FornecedorFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  String tipoDocumento = 'CPF'; // Usando maiúsculo como no banco
  late final TextEditingController documentoController;
  late final TextEditingController emailController;
  late final TextEditingController telefoneController;
  late final TextEditingController enderecoController;
  bool _loading = false;
  bool _verificandoDocumento = false;
  String? _erroDocumento;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.fornecedor?.nome ?? '');
    tipoDocumento = widget.fornecedor?.tipoDocumento ?? 'CPF';
    documentoController = TextEditingController(
      text: widget.fornecedor?.documento ?? '',
    );
    emailController = TextEditingController(
      text: widget.fornecedor?.email ?? '',
    );
    telefoneController = TextEditingController(
      text: widget.fornecedor?.telefone ?? '',
    );
    enderecoController = TextEditingController(
      text: widget.fornecedor?.endereco ?? '',
    );

    // Adiciona listener para verificar documento em tempo real
    documentoController.addListener(_verificarDocumento);
  }

  @override
  void dispose() {
    nomeController.dispose();
    documentoController.removeListener(_verificarDocumento);
    documentoController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();
    super.dispose();
  }

  Future<void> _verificarDocumento() async {
    final documento = documentoController.text.trim();
    if (documento.isEmpty || documento.length < 11) {
      setState(() {
        _erroDocumento = null;
        _verificandoDocumento = false;
      });
      return;
    }

    // Só verifica se não for edição ou se o documento mudou
    if (widget.fornecedor != null && documento == widget.fornecedor!.documento) {
      setState(() {
        _erroDocumento = null;
        _verificandoDocumento = false;
      });
      return;
    }

    setState(() {
      _verificandoDocumento = true;
      _erroDocumento = null;
    });

    try {
      final service = FornecedorService();
      final existe = await service.documentoExiste(documento);
      
      if (mounted) {
        setState(() {
          _verificandoDocumento = false;
          if (existe) {
            _erroDocumento = 'Este $tipoDocumento já está cadastrado';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificandoDocumento = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fornecedor = widget.fornecedor == null
          ? FornecedorModel.novo(
              nome: nomeController.text.trim(),
              tipoDocumento: tipoDocumento,
              documento: documentoController.text.trim(),
              email: emailController.text.trim().isEmpty
                  ? null
                  : emailController.text.trim(),
              telefone: telefoneController.text.trim().isEmpty
                  ? null
                  : telefoneController.text.trim(),
              endereco: enderecoController.text.trim().isEmpty
                  ? null
                  : enderecoController.text.trim(),
            )
          : FornecedorModel(
              id: widget.fornecedor!.id,
              nome: nomeController.text.trim(),
              tipoDocumento: tipoDocumento,
              documento: documentoController.text.trim(),
              email: emailController.text.trim().isEmpty
                  ? null
                  : emailController.text.trim(),
              telefone: telefoneController.text.trim().isEmpty
                  ? null
                  : telefoneController.text.trim(),
              endereco: enderecoController.text.trim().isEmpty
                  ? null
                  : enderecoController.text.trim(),
              criadoEm: widget.fornecedor!.criadoEm,
              criadoPor: widget.fornecedor!.criadoPor,
            );
      if (widget.fornecedor == null) {
        await ref.read(fornecedorProvider.notifier).addFornecedor(fornecedor);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Fornecedor criado com sucesso!');
          Navigator.of(context).pop();
        }
      } else {
        await ref
            .read(fornecedorProvider.notifier)
            .updateFornecedor(fornecedor);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Fornecedor atualizado com sucesso!');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao salvar fornecedor';
        
        if (e.toString().contains('Já existe um fornecedor cadastrado')) {
          mensagem = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('Já existe outro fornecedor cadastrado')) {
          mensagem = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('Usuário não autenticado')) {
          mensagem = 'Sessão expirada. Faça login novamente.';
        } else if (e.toString().contains('409')) {
          mensagem = 'Já existe um fornecedor cadastrado com este $tipoDocumento';
        }
        
        AppFeedback.showError(context, mensagem);
      }
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
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fornecedor == null
                        ? 'Novo Fornecedor'
                        : 'Editar Fornecedor',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Nome *',
                    controller: nomeController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nome obrigatório' : null,
                    enabled: !_loading,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipoDocumento,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Documento *',
                      prefixIcon: Icon(Icons.description),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                      DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ')),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => tipoDocumento = v ?? 'CPF'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione o tipo de documento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: tipoDocumento == 'CPF' ? 'CPF *' : 'CNPJ *',
                    controller: documentoController,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return tipoDocumento == 'CPF' ? 'CPF obrigatório' : 'CNPJ obrigatório';
                      }
                      // Validação básica de CPF/CNPJ
                      final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                      if (tipoDocumento == 'CPF' && clean.length != 11) {
                        return 'CPF deve ter 11 dígitos';
                      }
                      if (tipoDocumento == 'CNPJ' && clean.length != 14) {
                        return 'CNPJ deve ter 14 dígitos';
                      }
                      // Verifica se há erro de documento duplicado
                      if (_erroDocumento != null) {
                        return _erroDocumento;
                      }
                      return null;
                    },
                    enabled: !_loading,
                    prefixIcon: const Icon(Icons.credit_card),
                    suffixIcon: _verificandoDocumento
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _erroDocumento != null
                            ? const Icon(Icons.error, color: Colors.red)
                            : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Email',
                    controller: emailController,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                    enabled: !_loading,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Telefone',
                    controller: telefoneController,
                    enabled: !_loading,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Endereço',
                    controller: enderecoController,
                    enabled: !_loading,
                    prefixIcon: const Icon(Icons.location_on),
                    maxLines: 3,
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
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _salvar,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: Text(_loading ? 'Salvando...' : 'Salvar'),
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
