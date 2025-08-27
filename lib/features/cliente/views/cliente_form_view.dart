import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cliente_model.dart';
import '../controllers/cliente_controller.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../features/lojas/providers/loja_ativa_provider.dart';
import '../../../features/lojas/controllers/loja_controller.dart';
import '../../../features/lojas/models/loja_model.dart';

class ClienteFormView extends ConsumerStatefulWidget {
  final String? clienteId;

  const ClienteFormView({super.key, this.clienteId});

  @override
  ConsumerState<ClienteFormView> createState() => _ClienteFormViewState();
}

class _ClienteFormViewState extends ConsumerState<ClienteFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _documentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();

  String? _tipoDocumento;
  String? _lojaId;
  bool _loading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.clienteId != null;

    if (_isEditing) {
      _carregarCliente();
    } else {
      // Para novo cliente, usar loja ativa automaticamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final lojaAtiva = ref.read(lojaAtivaProvider);
        if (lojaAtiva != null && lojaAtiva.isNotEmpty) {
          setState(() {
            _lojaId = lojaAtiva;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _carregarCliente() async {
    if (widget.clienteId == null) return;

    setState(() => _loading = true);
    try {
      final cliente = await ref
          .read(clienteProvider.notifier)
          .getCliente(widget.clienteId!);
      if (cliente != null) {
        _nomeController.text = cliente.nome;
        _tipoDocumento = cliente.tipoDocumento;
        _documentoController.text = cliente.documento ?? '';
        _emailController.text = cliente.email ?? '';
        _telefoneController.text = cliente.telefone ?? '';
        _enderecoController.text = cliente.endereco ?? '';
        _lojaId = cliente.lojaId;
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao carregar cliente: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar se há uma loja ativa
    final lojaAtiva = ref.read(lojaAtivaProvider);
    if (lojaAtiva == null || lojaAtiva.isEmpty) {
      AppFeedback.showError(
        context,
        'Nenhuma loja ativa selecionada. Selecione uma loja antes de criar um cliente.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cliente = ClienteModel.novo(
        nome: _nomeController.text.trim(),
        lojaId: lojaAtiva, // Sempre usar a loja ativa
        tipoDocumento: _tipoDocumento,
        documento: _documentoController.text.trim().isEmpty
            ? null
            : _documentoController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim().isEmpty
            ? null
            : _enderecoController.text.trim(),
      );

      if (_isEditing) {
        final clienteExistente = await ref
            .read(clienteProvider.notifier)
            .getCliente(widget.clienteId!);
        if (clienteExistente != null) {
          final clienteAtualizado = cliente.copyWith(
            id: widget.clienteId!,
            lojaId: clienteExistente.lojaId, // Manter a loja original
            criadoEm: clienteExistente.criadoEm,
            criadoPor: clienteExistente.criadoPor,
          );
          await ref
              .read(clienteProvider.notifier)
              .updateCliente(clienteAtualizado);
          if (mounted) {
            AppFeedback.showSuccess(context, 'Cliente atualizado com sucesso!');
          }
        }
      } else {
        await ref.read(clienteProvider.notifier).addCliente(cliente);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Cliente criado com sucesso!');
        }
      }

      if (mounted) {
        context.go('/clientes');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao salvar cliente: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lojasAsync = ref.watch(lojaProvider);

    return MainLayout(
      title: _isEditing ? '✏️ Editar Cliente' : '➕ Novo Cliente',
      breadcrumbs: [
        const BreadcrumbItem('Dashboard'),
        const BreadcrumbItem('Clientes'),
        BreadcrumbItem(_isEditing ? 'Editar' : 'Novo'),
      ],
      currentRoute: '/clientes',
      onSidebarItemSelected: (route) => context.go(route),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/clientes'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar'),
        ),
        ElevatedButton.icon(
          onPressed: (_loading || _lojaId == null || _lojaId!.isEmpty)
              ? null
              : _salvar,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
      child: _loading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações Básicas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nome é obrigatório';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de Documento',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _tipoDocumento,
                                  items: const [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text('Selecione'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'CPF',
                                      child: Text('CPF'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'CNPJ',
                                      child: Text('CNPJ'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoDocumento = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _documentoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Documento',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contato',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Email inválido';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _telefoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _enderecoController,
                            decoration: const InputDecoration(
                              labelText: 'Endereço',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loja',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          lojasAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Text('Erro ao carregar loja: $e'),
                            data: (lojas) {
                              if (_lojaId == null || _lojaId!.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.orange[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Atenção',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Nenhuma loja ativa selecionada. Selecione uma loja no menu superior.',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final lojaAtiva = lojas.firstWhere(
                                (loja) => loja.id == _lojaId,
                                orElse: () => LojaModel(
                                  id: '',
                                  nome: 'Loja não encontrada',
                                  shopping: '',
                                  andar: '',
                                  numero: '',
                                ),
                              );
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.store,
                                      color: Colors.blue[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Loja Ativa',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${lojaAtiva.nome} - ${lojaAtiva.shopping}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
