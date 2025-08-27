import 'package:uuid/uuid.dart';

enum TipoMovimentacao {
  entrada,
  saida,
  trocaEntrada,
  trocaSaida,
  transferenciaEntrada,
  transferenciaSaida,
}

class MovimentacaoEstoqueModel {
  final String id;
  final String lojaId;
  final String produtoId;
  final TipoMovimentacao tipo;
  final int quantidade;
  final String? observacao;
  final DateTime criadoEm;
  final String? criadoPor;

  MovimentacaoEstoqueModel({
    required this.id,
    required this.lojaId,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    this.observacao,
    required this.criadoEm,
    this.criadoPor,
  });

  factory MovimentacaoEstoqueModel.novo({
    required String lojaId,
    required String produtoId,
    required TipoMovimentacao tipo,
    required int quantidade,
    String? observacao,
    String? criadoPor,
  }) {
    return MovimentacaoEstoqueModel(
      id: const Uuid().v4(),
      lojaId: lojaId,
      produtoId: produtoId,
      tipo: tipo,
      quantidade: quantidade,
      observacao: observacao,
      criadoEm: DateTime.now(),
      criadoPor: criadoPor,
    );
  }

  factory MovimentacaoEstoqueModel.fromMap(Map<String, dynamic> map) {
    return MovimentacaoEstoqueModel(
      id: map['id'] ?? '',
      lojaId: map['loja_id'] ?? '',
      produtoId: map['produto_id'] ?? '',
      tipo: _parseTipoMovimentacao(map['tipo']),
      quantidade: map['quantidade']?.toInt() ?? 0,
      observacao: map['observacao'],
      criadoEm: DateTime.parse(map['criado_em']),
      criadoPor: map['criado_por'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loja_id': lojaId,
      'produto_id': produtoId,
      'tipo': _tipoToString(tipo),
      'quantidade': quantidade,
      'observacao': observacao,
      'criado_em': criadoEm.toIso8601String(),
      'criado_por': criadoPor,
    };
  }

  static TipoMovimentacao _parseTipoMovimentacao(String? tipo) {
    switch (tipo) {
      case 'entrada':
        return TipoMovimentacao.entrada;
      case 'saida':
        return TipoMovimentacao.saida;
      case 'troca_entrada':
        return TipoMovimentacao.trocaEntrada;
      case 'troca_saida':
        return TipoMovimentacao.trocaSaida;
      case 'transferencia_entrada':
        return TipoMovimentacao.transferenciaEntrada;
      case 'transferencia_saida':
        return TipoMovimentacao.transferenciaSaida;
      default:
        return TipoMovimentacao.entrada;
    }
  }

  static String _tipoToString(TipoMovimentacao tipo) {
    switch (tipo) {
      case TipoMovimentacao.entrada:
        return 'entrada';
      case TipoMovimentacao.saida:
        return 'saida';
      case TipoMovimentacao.trocaEntrada:
        return 'troca_entrada';
      case TipoMovimentacao.trocaSaida:
        return 'troca_saida';
      case TipoMovimentacao.transferenciaEntrada:
        return 'transferencia_entrada';
      case TipoMovimentacao.transferenciaSaida:
        return 'transferencia_saida';
    }
  }

  MovimentacaoEstoqueModel copyWith({
    String? id,
    String? lojaId,
    String? produtoId,
    TipoMovimentacao? tipo,
    int? quantidade,
    String? observacao,
    DateTime? criadoEm,
    String? criadoPor,
  }) {
    return MovimentacaoEstoqueModel(
      id: id ?? this.id,
      lojaId: lojaId ?? this.lojaId,
      produtoId: produtoId ?? this.produtoId,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
    );
  }

  @override
  String toString() {
    return 'MovimentacaoEstoqueModel(id: $id, lojaId: $lojaId, produtoId: $produtoId, tipo: $tipo, quantidade: $quantidade, observacao: $observacao, criadoEm: $criadoEm, criadoPor: $criadoPor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimentacaoEstoqueModel &&
        other.id == id &&
        other.lojaId == lojaId &&
        other.produtoId == produtoId &&
        other.tipo == tipo &&
        other.quantidade == quantidade &&
        other.observacao == observacao &&
        other.criadoEm == criadoEm &&
        other.criadoPor == criadoPor;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        lojaId.hashCode ^
        produtoId.hashCode ^
        tipo.hashCode ^
        quantidade.hashCode ^
        observacao.hashCode ^
        criadoEm.hashCode ^
        criadoPor.hashCode;
  }
}
