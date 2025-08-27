class PagamentoVendaModel {
  final String id;
  final String vendaId;
  final String formaPagamentoId;
  final double valorPago;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  PagamentoVendaModel({
    required this.id,
    required this.vendaId,
    required this.formaPagamentoId,
    required this.valorPago,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory PagamentoVendaModel.fromMap(Map<String, dynamic> map) {
    return PagamentoVendaModel(
      id: map['id'] ?? '',
      vendaId: map['venda_id'] ?? '',
      formaPagamentoId: map['forma_pagamento_id'] ?? '',
      valorPago: (map['valor_pago'] ?? 0.0).toDouble(),
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'])
          : null,
      criadoPor: map['criado_por'],
      atualizadoEm: map['atualizado_em'] != null
          ? DateTime.parse(map['atualizado_em'])
          : null,
      atualizadoPor: map['atualizado_por'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'venda_id': vendaId,
      'forma_pagamento_id': formaPagamentoId,
      'valor_pago': valorPago,
    };

    if (criadoEm != null) {
      map['criado_em'] = criadoEm!.toIso8601String();
    }
    if (criadoPor != null && criadoPor!.isNotEmpty) {
      map['criado_por'] = criadoPor;
    }
    if (atualizadoEm != null) {
      map['atualizado_em'] = atualizadoEm!.toIso8601String();
    }
    if (atualizadoPor != null && atualizadoPor!.isNotEmpty) {
      map['atualizado_por'] = atualizadoPor;
    }

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  factory PagamentoVendaModel.novo({
    required String vendaId,
    required String formaPagamentoId,
    required double valorPago,
    String? criadoPor,
  }) {
    return PagamentoVendaModel(
      id: '',
      vendaId: vendaId,
      formaPagamentoId: formaPagamentoId,
      valorPago: valorPago,
      criadoPor: criadoPor,
    );
  }

  PagamentoVendaModel copyWith({
    String? id,
    String? vendaId,
    String? formaPagamentoId,
    double? valorPago,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return PagamentoVendaModel(
      id: id ?? this.id,
      vendaId: vendaId ?? this.vendaId,
      formaPagamentoId: formaPagamentoId ?? this.formaPagamentoId,
      valorPago: valorPago ?? this.valorPago,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }
}

