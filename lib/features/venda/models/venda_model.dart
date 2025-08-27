enum StatusVenda {
  aberta('Aberta'),
  fechada('Fechada'),
  cancelada('Cancelada');

  const StatusVenda(this.label);
  final String label;
}

class VendaModel {
  final String id;
  final String lojaId;
  final String? clienteId;
  final String? usuarioId;
  final StatusVenda status;
  final double valorTotal;
  final double descontoTotal;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  VendaModel({
    required this.id,
    required this.lojaId,
    this.clienteId,
    this.usuarioId,
    required this.status,
    required this.valorTotal,
    required this.descontoTotal,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory VendaModel.fromMap(Map<String, dynamic> map) {
    return VendaModel(
      id: map['id'] ?? '',
      lojaId: map['loja_id'] ?? '',
      clienteId: map['cliente_id'],
      usuarioId: map['usuario_id'],
      status: StatusVenda.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusVenda.aberta,
      ),
      valorTotal: (map['valor_total'] ?? 0.0).toDouble(),
      descontoTotal: (map['desconto_total'] ?? 0.0).toDouble(),
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
      'loja_id': lojaId,
      'status': status.name,
      'valor_total': valorTotal,
      'desconto_total': descontoTotal,
    };

    if (clienteId != null && clienteId!.isNotEmpty) {
      map['cliente_id'] = clienteId;
    }
    if (usuarioId != null && usuarioId!.isNotEmpty) {
      map['usuario_id'] = usuarioId;
    }
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

  factory VendaModel.novo({
    required String lojaId,
    String? clienteId,
    String? usuarioId,
    StatusVenda status = StatusVenda.aberta,
    double valorTotal = 0.0,
    double descontoTotal = 0.0,
    String? criadoPor,
  }) {
    return VendaModel(
      id: '',
      lojaId: lojaId,
      clienteId: clienteId,
      usuarioId: usuarioId,
      status: status,
      valorTotal: valorTotal,
      descontoTotal: descontoTotal,
      criadoPor: criadoPor,
    );
  }

  VendaModel copyWith({
    String? id,
    String? lojaId,
    String? clienteId,
    String? usuarioId,
    StatusVenda? status,
    double? valorTotal,
    double? descontoTotal,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return VendaModel(
      id: id ?? this.id,
      lojaId: lojaId ?? this.lojaId,
      clienteId: clienteId ?? this.clienteId,
      usuarioId: usuarioId ?? this.usuarioId,
      status: status ?? this.status,
      valorTotal: valorTotal ?? this.valorTotal,
      descontoTotal: descontoTotal ?? this.descontoTotal,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }

  double get valorFinal => valorTotal - descontoTotal;
}
