import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/forma_pagamento_service.dart';
import '../models/forma_pagamento_model.dart';

final formaPagamentoServiceProvider = Provider<FormaPagamentoService>((ref) {
  return FormaPagamentoService();
});

final formasPagamentoProvider = FutureProvider<List<FormaPagamentoModel>>((ref) async {
  final service = ref.read(formaPagamentoServiceProvider);
  return await service.getFormasPagamento();
});
