import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/forma_pagamento_model.dart';
import '../../../core/services/supabase_service.dart';

class FormaPagamentoService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'formas_pagamento';

  Future<List<FormaPagamentoModel>> getFormasPagamento() async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .order('nome')
          .then((value) => value as List);
      return data.map((e) => FormaPagamentoModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar formas de pagamento: $e');
    }
  }

  Future<void> addFormaPagamento(FormaPagamentoModel formaPagamento) async {
    try {
      await _client.from(_table).insert(formaPagamento.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar forma de pagamento: $e');
    }
  }

  Future<void> updateFormaPagamento(FormaPagamentoModel formaPagamento) async {
    try {
      await _client
          .from(_table)
          .update(formaPagamento.toMap())
          .eq('id', formaPagamento.id);
    } catch (e) {
      throw Exception('Erro ao atualizar forma de pagamento: $e');
    }
  }

  Future<void> deleteFormaPagamento(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar forma de pagamento: $e');
    }
  }
}
