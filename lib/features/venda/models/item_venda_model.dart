class ItemVendaModel {
  final String id;
  final String vendaId;
  final String produtoId;
  final int quantidade;
  final double precoUnitario;
  final double descontoUnitario;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  ItemVendaModel({
    required this.id,
    required this.vendaId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.descontoUnitario,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory ItemVendaModel.fromMap(Map<String, dynamic> map) {
    return ItemVendaModel(
      id: map['id'] ?? '',
      vendaId: map['venda_id'] ?? '',
      produtoId: map['produto_id'] ?? '',
      quantidade: map['quantidade'] ?? 0,
      precoUnitario: (map['preco_unitario'] ?? 0.0).toDouble(),
      descontoUnitario: (map['desconto_unitario'] ?? 0.0).toDouble(),
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
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'desconto_unitario': descontoUnitario,
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

  factory ItemVendaModel.novo({
    required String vendaId,
    required String produtoId,
    required int quantidade,
    required double precoUnitario,
    double descontoUnitario = 0.0,
    String? criadoPor,
  }) {
    return ItemVendaModel(
      id: '',
      vendaId: vendaId,
      produtoId: produtoId,
      quantidade: quantidade,
      precoUnitario: precoUnitario,
      descontoUnitario: descontoUnitario,
      criadoPor: criadoPor,
    );
  }

  ItemVendaModel copyWith({
    String? id,
    String? vendaId,
    String? produtoId,
    int? quantidade,
    double? precoUnitario,
    double? descontoUnitario,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return ItemVendaModel(
      id: id ?? this.id,
      vendaId: vendaId ?? this.vendaId,
      produtoId: produtoId ?? this.produtoId,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      descontoUnitario: descontoUnitario ?? this.descontoUnitario,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }

  double get valorTotal => quantidade * precoUnitario;
  double get valorComDesconto => valorTotal - (quantidade * descontoUnitario);
}

