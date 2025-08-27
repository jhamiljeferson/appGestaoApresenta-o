import 'package:uuid/uuid.dart';

class PermissaoModel {
  final String id;
  final String recurso;
  final String acao; // 'criar', 'listar', 'atualizar', 'deletar'
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  PermissaoModel({
    required this.id,
    required this.recurso,
    required this.acao,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory PermissaoModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        } else if (value is DateTime) {
          return value;
        }
        return null;
      } catch (e) {
        print(
          '⚠️ [PermissaoModel] Erro ao fazer parse de DateTime: $value, erro: $e',
        );
        return null;
      }
    }

    return PermissaoModel(
      id: map['id']?.toString() ?? '',
      recurso: map['recurso']?.toString() ?? '',
      acao: map['acao']?.toString() ?? '',
      criadoEm: parseDateTime(map['criado_em']),
      criadoPor: map['criado_por']?.toString(),
      atualizadoEm: parseDateTime(map['atualizado_em']),
      atualizadoPor: map['atualizado_por']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'recurso': recurso, 'acao': acao};

    if (id.isNotEmpty) {
      map['id'] = id;
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

    return map;
  }

  factory PermissaoModel.novo({
    required String recurso,
    required String acao,
    String? criadoPor,
  }) {
    return PermissaoModel(
      id: const Uuid().v4(),
      recurso: recurso,
      acao: acao,
      criadoEm: DateTime.now(),
      criadoPor: criadoPor,
    );
  }

  PermissaoModel copyWith({
    String? id,
    String? recurso,
    String? acao,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return PermissaoModel(
      id: id ?? this.id,
      recurso: recurso ?? this.recurso,
      acao: acao ?? this.acao,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }

  // Getters úteis
  bool get isCriar => acao == 'criar';
  bool get isListar => acao == 'listar';
  bool get isAtualizar => acao == 'atualizar';
  bool get isDeletar => acao == 'deletar';

  @override
  String toString() {
    return 'PermissaoModel(id: $id, recurso: $recurso, acao: $acao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissaoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
