import 'package:uuid/uuid.dart';

class EstoqueModel {
  final String id;
  final String produtoId;
  final String lojaId;
  final int qtd;
  final int quantidadeMinima;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  EstoqueModel({
    required this.id,
    required this.produtoId,
    required this.lojaId,
    required this.qtd,
    required this.quantidadeMinima,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory EstoqueModel.fromMap(Map<String, dynamic> map) {
    return EstoqueModel(
      id: map['id'] as String,
      produtoId: map['produto_id'] as String,
      lojaId: map['loja_id'] as String,
      qtd: map['quantidade'] as int,
      quantidadeMinima: map['estoque_minimo'] as int,
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'])
          : null,
      criadoPor: map['criado_por'] as String?,
      atualizadoEm: map['atualizado_em'] != null
          ? DateTime.parse(map['atualizado_em'])
          : null,
      atualizadoPor: map['atualizado_por'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'produto_id': produtoId,
      'loja_id': lojaId,
      'quantidade': qtd,
      'estoque_minimo': quantidadeMinima,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (criadoEm != null) {
      map['criado_em'] = criadoEm!.toIso8601String();
    }
    if (criadoPor != null) {
      map['criado_por'] = criadoPor;
    }
    if (atualizadoEm != null) {
      map['atualizado_em'] = atualizadoEm!.toIso8601String();
    }
    if (atualizadoPor != null) {
      map['atualizado_por'] = atualizadoPor;
    }
    return map;
  }

  static EstoqueModel novo({
    required String produtoId,
    required String lojaId,
    required int qtd,
    required int quantidadeMinima,
  }) {
    return EstoqueModel(
      id: const Uuid().v4(),
      produtoId: produtoId,
      lojaId: lojaId,
      qtd: qtd,
      quantidadeMinima: quantidadeMinima,
      criadoEm: DateTime.now(),
    );
  }

  EstoqueModel copyWith({
    String? id,
    String? produtoId,
    String? lojaId,
    int? qtd,
    int? quantidadeMinima,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return EstoqueModel(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      lojaId: lojaId ?? this.lojaId,
      qtd: qtd ?? this.qtd,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }
}
