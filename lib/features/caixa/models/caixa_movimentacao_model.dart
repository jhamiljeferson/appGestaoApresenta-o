enum TipoMovimentacaoCaixa {
  entrada('Entrada'),
  saida('Saída'),
  venda('Venda');

  const TipoMovimentacaoCaixa(this.label);
  final String label;
}

class CaixaMovimentacaoModel {
  final String id;
  final String caixaId;
  final TipoMovimentacaoCaixa tipo;
  final double valor;
  final String usuarioId;
  final DateTime data;
  final String? descricao;
  final String? vendaId;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  CaixaMovimentacaoModel({
    required this.id,
    required this.caixaId,
    required this.tipo,
    required this.valor,
    required this.usuarioId,
    required this.data,
    this.descricao,
    this.vendaId,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory CaixaMovimentacaoModel.fromMap(Map<String, dynamic> map) {
    return CaixaMovimentacaoModel(
      id: map['id'] ?? '',
      caixaId: map['caixa_id'] ?? '',
      tipo: TipoMovimentacaoCaixa.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoMovimentacaoCaixa.entrada,
      ),
      valor: (map['valor'] ?? 0.0).toDouble(),
      usuarioId: map['usuario_id'] ?? '',
      data: DateTime.parse(map['data']),
      descricao: map['descricao'],
      vendaId: map['venda_id'],
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
      'caixa_id': caixaId,
      'tipo': tipo.name,
      'valor': valor,
      'usuario_id': usuarioId,
      'data': data.toIso8601String(),
    };

    if (descricao != null && descricao!.isNotEmpty) {
      map['descricao'] = descricao;
    }
    if (vendaId != null && vendaId!.isNotEmpty) {
      map['venda_id'] = vendaId;
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

  factory CaixaMovimentacaoModel.novo({
    required String caixaId,
    required TipoMovimentacaoCaixa tipo,
    required double valor,
    required String usuarioId,
    String? descricao,
    String? vendaId,
    String? criadoPor,
  }) {
    return CaixaMovimentacaoModel(
      id: '',
      caixaId: caixaId,
      tipo: tipo,
      valor: valor,
      usuarioId: usuarioId,
      data: DateTime.now(),
      descricao: descricao,
      vendaId: vendaId,
      criadoPor: criadoPor,
    );
  }

  CaixaMovimentacaoModel copyWith({
    String? id,
    String? caixaId,
    TipoMovimentacaoCaixa? tipo,
    double? valor,
    String? usuarioId,
    DateTime? data,
    String? descricao,
    String? vendaId,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return CaixaMovimentacaoModel(
      id: id ?? this.id,
      caixaId: caixaId ?? this.caixaId,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      usuarioId: usuarioId ?? this.usuarioId,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
      vendaId: vendaId ?? this.vendaId,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }

  bool get isEntrada => tipo == TipoMovimentacaoCaixa.entrada;
  bool get isSaida => tipo == TipoMovimentacaoCaixa.saida;
  bool get isVenda => tipo == TipoMovimentacaoCaixa.venda;
}

