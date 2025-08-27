enum StatusCaixa {
  aberto('Aberto'),
  fechado('Fechado');

  const StatusCaixa(this.label);
  final String label;
}

class CaixaModel {
  final String id;
  final String lojaId;
  final String usuarioAberturaId;
  final String? usuarioFechamentoId;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final double saldoInicial;
  final double? saldoFinal;
  final StatusCaixa status;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  CaixaModel({
    required this.id,
    required this.lojaId,
    required this.usuarioAberturaId,
    this.usuarioFechamentoId,
    required this.dataAbertura,
    this.dataFechamento,
    required this.saldoInicial,
    this.saldoFinal,
    required this.status,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory CaixaModel.fromMap(Map<String, dynamic> map) {
    return CaixaModel(
      id: map['id'] ?? '',
      lojaId: map['loja_id'] ?? '',
      usuarioAberturaId: map['usuario_abertura_id'] ?? '',
      usuarioFechamentoId: map['usuario_fechamento_id'],
      dataAbertura: DateTime.parse(map['data_abertura']),
      dataFechamento: map['data_fechamento'] != null
          ? DateTime.parse(map['data_fechamento'])
          : null,
      saldoInicial: (map['saldo_inicial'] ?? 0.0).toDouble(),
      saldoFinal: map['saldo_final'] != null
          ? (map['saldo_final'] as num).toDouble()
          : null,
      status: StatusCaixa.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusCaixa.aberto,
      ),
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
      'usuario_abertura_id': usuarioAberturaId,
      'data_abertura': dataAbertura.toIso8601String(),
      'saldo_inicial': saldoInicial,
      'status': status.name,
    };

    if (usuarioFechamentoId != null && usuarioFechamentoId!.isNotEmpty) {
      map['usuario_fechamento_id'] = usuarioFechamentoId;
    }
    if (dataFechamento != null) {
      map['data_fechamento'] = dataFechamento!.toIso8601String();
    }
    if (saldoFinal != null) {
      map['saldo_final'] = saldoFinal;
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

  factory CaixaModel.novo({
    required String lojaId,
    required String usuarioAberturaId,
    required double saldoInicial,
    String? criadoPor,
  }) {
    // IMPORTANTE: Não gerar ID prematuramente, deixar o banco gerar
    return CaixaModel(
      id: '', // ID vazio, banco gera automaticamente
      lojaId: lojaId,
      usuarioAberturaId: usuarioAberturaId,
      saldoInicial: saldoInicial,
      status: StatusCaixa.aberto,
      dataAbertura: DateTime.now(),
      criadoPor: criadoPor,
    );
  }

  CaixaModel copyWith({
    String? id,
    String? lojaId,
    String? usuarioAberturaId,
    String? usuarioFechamentoId,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    double? saldoInicial,
    double? saldoFinal,
    StatusCaixa? status,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return CaixaModel(
      id: id ?? this.id,
      lojaId: lojaId ?? this.lojaId,
      usuarioAberturaId: usuarioAberturaId ?? this.usuarioAberturaId,
      usuarioFechamentoId: usuarioFechamentoId ?? this.usuarioFechamentoId,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      saldoInicial: saldoInicial ?? this.saldoInicial,
      saldoFinal: saldoFinal ?? this.saldoFinal,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }

  bool get isAberto => status == StatusCaixa.aberto;
  bool get isFechado => status == StatusCaixa.fechado;
}
