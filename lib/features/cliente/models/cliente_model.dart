class ClienteModel {
  final String id;
  final String nome;
  final String? lojaId;
  final String? tipoDocumento;
  final String? documento;
  final String? email;
  final String? telefone;
  final String? endereco;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  ClienteModel({
    required this.id,
    required this.nome,
    this.lojaId,
    this.tipoDocumento,
    this.documento,
    this.email,
    this.telefone,
    this.endereco,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      lojaId: map['loja_id'],
      tipoDocumento: map['tipo_documento'],
      documento: map['documento'],
      email: map['email'],
      telefone: map['telefone'],
      endereco: map['endereco'],
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
    final map = <String, dynamic>{'nome': nome};

    // Adicionar campos opcionais apenas se não forem nulos/vazios
    if (lojaId != null && lojaId!.isNotEmpty) {
      map['loja_id'] = lojaId;
    }
    if (tipoDocumento != null && tipoDocumento!.isNotEmpty) {
      map['tipo_documento'] = tipoDocumento;
    }
    if (documento != null && documento!.isNotEmpty) {
      map['documento'] = documento;
    }
    if (email != null && email!.isNotEmpty) {
      map['email'] = email;
    }
    if (telefone != null && telefone!.isNotEmpty) {
      map['telefone'] = telefone;
    }
    if (endereco != null && endereco!.isNotEmpty) {
      map['endereco'] = endereco;
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

    // Adicionar ID apenas se não estiver vazio (para updates)
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  factory ClienteModel.novo({
    required String nome,
    String? lojaId,
    String? tipoDocumento,
    String? documento,
    String? email,
    String? telefone,
    String? endereco,
    String? criadoPor,
  }) {
    return ClienteModel(
      id: '',
      nome: nome,
      lojaId: lojaId,
      tipoDocumento: tipoDocumento,
      documento: documento,
      email: email,
      telefone: telefone,
      endereco: endereco,
      criadoPor: criadoPor,
    );
  }

  ClienteModel copyWith({
    String? id,
    String? nome,
    String? lojaId,
    String? tipoDocumento,
    String? documento,
    String? email,
    String? telefone,
    String? endereco,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      lojaId: lojaId ?? this.lojaId,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }
}
