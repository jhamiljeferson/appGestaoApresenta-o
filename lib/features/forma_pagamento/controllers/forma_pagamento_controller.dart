import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forma_pagamento_model.dart';
import '../services/forma_pagamento_service.dart';
import '../../lojas/providers/loja_ativa_provider.dart';
import '../../../core/services/user_audit_service.dart';

final formaPagamentoProvider =
    StateNotifierProvider<
      FormaPagamentoController,
      AsyncValue<List<FormaPagamentoModel>>
    >((ref) => FormaPagamentoController(ref));

class FormaPagamentoController
    extends StateNotifier<AsyncValue<List<FormaPagamentoModel>>> {
  final FormaPagamentoService _service = FormaPagamentoService();
  final Ref _ref;

  FormaPagamentoController(this._ref) : super(const AsyncValue.loading()) {
    loadFormasPagamento();
  }

  Future<void> loadFormasPagamento() async {
    try {
      state = const AsyncValue.loading();
      final formasPagamento = await _service.getFormasPagamento();
      state = AsyncValue.data(formasPagamento);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFormaPagamento(FormaPagamentoModel formaPagamento) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }

    // Obtém o ID do usuário logado
    final userId = await UserAuditService().getUsuarioId();
    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Verifique se você está logado corretamente.',
      );
    }

    // Cria uma cópia da forma de pagamento com o usuário que criou
    final formaPagamentoComUsuario = formaPagamento.copyWith(
      criadoPor: userId,
      criadoEm: DateTime.now(),
    );

    await _service.addFormaPagamento(formaPagamentoComUsuario);
    await loadFormasPagamento();
  }

  Future<void> updateFormaPagamento(FormaPagamentoModel formaPagamento) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }

    // Obtém o ID do usuário logado
    final userId = await UserAuditService().getUsuarioId();
    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Verifique se você está logado corretamente.',
      );
    }

    // Cria uma cópia da forma de pagamento com o usuário que atualizou
    final formaPagamentoComUsuario = formaPagamento.copyWith(
      atualizadoPor: userId,
      atualizadoEm: DateTime.now(),
    );

    await _service.updateFormaPagamento(formaPagamentoComUsuario);
    await loadFormasPagamento();
  }

  Future<void> deleteFormaPagamento(String id) async {
    final lojaId = _ref.read(lojaAtivaProvider);
    if (lojaId == null || lojaId.isEmpty) {
      throw Exception('Selecione uma loja ativa para realizar operações.');
    }
    await _service.deleteFormaPagamento(id);
    await loadFormasPagamento();
  }
}
