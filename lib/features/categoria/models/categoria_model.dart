import 'package:uuid/uuid.dart';

class CategoriaModel {
  final String id;
  final String nome;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  CategoriaModel({
    required this.id,
    required this.nome,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
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
    final map = <String, dynamic>{'nome': nome};
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

  static CategoriaModel nova(String nome) {
    return CategoriaModel(
      id: const Uuid().v4(),
      nome: nome,
      criadoEm: DateTime.now(),
    );
  }

  CategoriaModel copyWith({
    String? id,
    String? nome,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }
}
