import 'package:uuid/uuid.dart';

class CargoModel {
  final String id;
  final String nome;
  final String? criadoPor;
  final String? atualizadoPor;

  const CargoModel({
    required this.id,
    required this.nome,
    this.criadoPor,
    this.atualizadoPor,
  });

  factory CargoModel.fromMap(Map<String, dynamic> map) {
    return CargoModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      criadoPor: map['criado_por']?.toString(),
      atualizadoPor: map['atualizado_por']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'nome': nome};

    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (criadoPor != null && criadoPor!.isNotEmpty) {
      map['criado_por'] = criadoPor;
    }
    if (atualizadoPor != null && atualizadoPor!.isNotEmpty) {
      map['atualizado_por'] = atualizadoPor;
    }

    return map;
  }

  factory CargoModel.novo(String nome) {
    // IMPORTANTE: Não gerar ID prematuramente, deixar o banco gerar
    return CargoModel(id: '', nome: nome);
  }

  CargoModel copyWith({
    String? id,
    String? nome,
    String? criadoPor,
    String? atualizadoPor,
  }) {
    return CargoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }

  @override
  String toString() {
    return 'CargoModel(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CargoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
