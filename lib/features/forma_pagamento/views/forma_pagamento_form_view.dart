import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/forma_pagamento_controller.dart';
import '../models/forma_pagamento_model.dart';

class FormaPagamentoFormView extends ConsumerStatefulWidget {
  final FormaPagamentoModel? formaPagamento;
  const FormaPagamentoFormView({super.key, this.formaPagamento});

  @override
  ConsumerState<FormaPagamentoFormView> createState() =>
      _FormaPagamentoFormViewState();
}

class _FormaPagamentoFormViewState
    extends ConsumerState<FormaPagamentoFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  late final TextEditingController percentualTaxaController;
  TipoTaxa _tipoTaxa = TipoTaxa.acrescimo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(
      text: widget.formaPagamento?.nome ?? '',
    );
    percentualTaxaController = TextEditingController(
      text: _formatarPercentual(widget.formaPagamento?.percentualTaxa ?? 0.0),
    );
    _tipoTaxa = widget.formaPagamento?.tipoTaxa ?? TipoTaxa.acrescimo;
  }

  @override
  void dispose() {
    nomeController.dispose();
    percentualTaxaController.dispose();
    super.dispose();
  }

  // Função para formatar o percentual com máscara
  String _formatarPercentual(double valor) {
    if (valor == 0) return '0%';
    return '${valor.toStringAsFixed(0)}%';
  }

  // Função para remover a máscara e converter para double
  double _removerMascaraPercentual(String texto) {
    final textoLimpo = texto.replaceAll('%', '');
    return double.tryParse(textoLimpo) ?? 0.0;
  }

  // Função para aplicar máscara enquanto digita
  void _aplicarMascaraPercentual(String valor) {
    if (valor.isEmpty) {
      percentualTaxaController.text = '0%';
      percentualTaxaController.selection = TextSelection.fromPosition(
        TextPosition(offset: percentualTaxaController.text.length - 1),
      );
      return;
    }

    // Remove tudo que não é número
    final apenasNumeros = valor.replaceAll(RegExp(r'[^\d]'), '');

    if (apenasNumeros.isEmpty) {
      percentualTaxaController.text = '0%';
      percentualTaxaController.selection = TextSelection.fromPosition(
        TextPosition(offset: percentualTaxaController.text.length - 1),
      );
      return;
    }

    // Adiciona o símbolo %
    percentualTaxaController.text = '$apenasNumeros%';

    // Posiciona o cursor antes do %
    percentualTaxaController.selection = TextSelection.fromPosition(
      TextPosition(offset: percentualTaxaController.text.length - 1),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final percentualTaxa = _removerMascaraPercentual(
        percentualTaxaController.text,
      );
      final formaPagamento = widget.formaPagamento == null
          ? FormaPagamentoModel.nova(
              nome: nomeController.text.trim(),
              tipoTaxa: _tipoTaxa,
              percentualTaxa: percentualTaxa,
            )
          : FormaPagamentoModel(
              id: widget.formaPagamento!.id,
              nome: nomeController.text.trim(),
              tipoTaxa: _tipoTaxa,
              percentualTaxa: percentualTaxa,
              criadoEm: widget.formaPagamento!.criadoEm,
            );

      if (widget.formaPagamento == null) {
        await ref
            .read(formaPagamentoProvider.notifier)
            .addFormaPagamento(formaPagamento);
        AppFeedback.showSuccess(
          context,
          'Forma de pagamento criada com sucesso!',
        );
      } else {
        await ref
            .read(formaPagamentoProvider.notifier)
            .updateFormaPagamento(formaPagamento);
        AppFeedback.showSuccess(
          context,
          'Forma de pagamento atualizada com sucesso!',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Erro ao salvar forma de pagamento: ${e.toString()}',
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
                  widget.formaPagamento == null
                      ? 'Nova Forma de Pagamento'
                      : 'Editar Forma de Pagamento',
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
                DropdownButtonFormField<TipoTaxa>(
                  value: _tipoTaxa,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Taxa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: TipoTaxa.values.map((tipo) {
                    return DropdownMenuItem<TipoTaxa>(
                      value: tipo,
                      child: Row(
                        children: [
                          Icon(
                            tipo == TipoTaxa.acrescimo
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            color: tipo == TipoTaxa.acrescimo
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tipo == TipoTaxa.acrescimo
                                ? 'Taxa acrescimo (Adiciona ao valor)'
                                : 'Taxa Desconto (Subtrai do valor)',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _loading
                      ? null
                      : (TipoTaxa? value) {
                          if (value != null) {
                            setState(() {
                              _tipoTaxa = value;
                            });
                          }
                        },
                ),
                TextFormField(
                  controller: percentualTaxaController,
                  decoration: InputDecoration(
                    labelText: 'Percentual Taxa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: '%',
                    hintText: '0%',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Percentual obrigatório';
                    }
                    final percentual = _removerMascaraPercentual(v);
                    if (percentual < 0) {
                      return 'Valor deve ser maior ou igual a 0';
                    }
                    if (percentual > 100) {
                      return 'Valor deve ser menor ou igual a 100';
                    }
                    return null;
                  },
                  enabled: !_loading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
                  ],
                  onChanged: _aplicarMascaraPercentual,
                  onTap: () {
                    // Posiciona o cursor antes do %
                    if (percentualTaxaController.text.isNotEmpty) {
                      percentualTaxaController.selection =
                          TextSelection.fromPosition(
                            TextPosition(
                              offset: percentualTaxaController.text.length - 1,
                            ),
                          );
                    }
                  },
                ),
                // Exemplo visual de como a taxa será aplicada
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _tipoTaxa == TipoTaxa.acrescimo
                                ? Icons.info_outline
                                : Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Exemplo de Aplicação',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Para um valor de R\$ 100,00:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tipoTaxa == TipoTaxa.acrescimo
                            ? '• Valor base: R\$ 100,00\n• Taxa (${_removerMascaraPercentual(percentualTaxaController.text).toStringAsFixed(0)}%): +R\$ ${(_removerMascaraPercentual(percentualTaxaController.text) * 100 / 100).toStringAsFixed(2)}\n• Valor final: R\$ ${(100 * (1 + _removerMascaraPercentual(percentualTaxaController.text) / 100)).toStringAsFixed(2)}'
                            : '• Valor base: R\$ 100,00\n• Taxa (${_removerMascaraPercentual(percentualTaxaController.text).toStringAsFixed(0)}%): -R\$ ${(_removerMascaraPercentual(percentualTaxaController.text) * 100 / 100).toStringAsFixed(2)}\n• Valor final: R\$ ${(100 * (1 - _removerMascaraPercentual(percentualTaxaController.text) / 100)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
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
