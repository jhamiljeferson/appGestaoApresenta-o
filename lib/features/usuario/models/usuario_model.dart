import 'package:uuid/uuid.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final bool ativo;
  final String? cargoId;
  final String? userId;
  final DateTime? criadoEm;
  final List<String> lojasIds;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.ativo,
    this.cargoId,
    this.userId,
    this.criadoEm,
    this.lojasIds = const [],
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      ativo: map['ativo'] as bool,
      cargoId: map['cargo_id'] as String?,
      userId: map['user_id'] as String?,
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'email': email,
      'ativo': ativo,
      'cargo_id': cargoId?.isNotEmpty == true ? cargoId : null,
      'user_id': userId?.isNotEmpty == true ? userId : null,
      'criado_em': criadoEm?.toIso8601String(),
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  static UsuarioModel novo({
    required String nome,
    required String email,
    required bool ativo,
    String? cargoId,
    String? userId,
    List<String> lojasIds = const [],
  }) {
    return UsuarioModel(
      id: const Uuid().v4(),
      nome: nome,
      email: email,
      ativo: ativo,
      cargoId: cargoId,
      userId: userId,
      lojasIds: lojasIds,
      criadoEm: DateTime.now(),
    );
  }
}
