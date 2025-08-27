import 'package:uuid/uuid.dart';

class LojaModel {
  final String id;
  final String nome;
  final String shopping;
  final String andar;
  final String numero;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;
  final int? quantidadeMinimaAtacado;

  LojaModel({
    required this.id,
    required this.nome,
    required this.shopping,
    required this.andar,
    required this.numero,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
    this.quantidadeMinimaAtacado,
  });

  factory LojaModel.fromMap(Map<String, dynamic> map) {
    return LojaModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      shopping: map['shopping'] as String,
      andar: map['andar'] as String,
      numero: map['numero'] as String,
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'])
          : null,
      criadoPor: map['criado_por'] as String?,
      atualizadoEm: map['atualizado_em'] != null
          ? DateTime.parse(map['atualizado_em'])
          : null,
      atualizadoPor: map['atualizado_por'] as String?,
      quantidadeMinimaAtacado: map['quantidade_minima_atacado'] as int? ?? 4,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'shopping': shopping,
      'andar': andar,
      'numero': numero,
      'quantidade_minima_atacado': quantidadeMinimaAtacado,
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

  static LojaModel nova({
    required String nome,
    required String shopping,
    required String andar,
    required String numero,
    int quantidadeMinimaAtacado = 4,
  }) {
    return LojaModel(
      id: const Uuid().v4(),
      nome: nome,
      shopping: shopping,
      andar: andar,
      numero: numero,
      quantidadeMinimaAtacado: quantidadeMinimaAtacado,
      criadoEm: DateTime.now(),
    );
  }

  LojaModel copyWith({
    String? id,
    String? nome,
    String? shopping,
    String? andar,
    String? numero,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
    int? quantidadeMinimaAtacado,
  }) {
    return LojaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      shopping: shopping ?? this.shopping,
      andar: andar ?? this.andar,
      numero: numero ?? this.numero,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
      quantidadeMinimaAtacado:
          quantidadeMinimaAtacado ?? this.quantidadeMinimaAtacado,
    );
  }
}
