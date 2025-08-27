class FornecedorModel {
  final String id;
  final String nome;
  final String tipoDocumento; // 'CPF' ou 'CNPJ' (maiúsculo como no banco)
  final String documento;
  final String? email;
  final String? telefone;
  final String? endereco;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  FornecedorModel({
    required this.id,
    required this.nome,
    required this.tipoDocumento,
    required this.documento,
    this.email,
    this.telefone,
    this.endereco,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory FornecedorModel.fromMap(Map<String, dynamic> map) {
    return FornecedorModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      tipoDocumento: map['tipo_documento'] as String,
      documento: map['documento'] as String,
      email: map['email'] as String?,
      telefone: map['telefone'] as String?,
      endereco: map['endereco'] as String?,
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
      'nome': nome,
      'tipo_documento': tipoDocumento,
      'documento': documento,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
    };

    // Só inclui o ID se não estiver vazio (para updates)
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

  // Método específico para inserção (sem ID)
  Map<String, dynamic> toMapForInsert() {
    final map = <String, dynamic>{
      'nome': nome,
      'tipo_documento': tipoDocumento,
      'documento': documento,
    };

    // Adiciona campos opcionais apenas se não forem nulos
    if (email != null && email!.isNotEmpty) {
      map['email'] = email;
    }

    if (telefone != null && telefone!.isNotEmpty) {
      map['telefone'] = telefone;
    }

    if (endereco != null && endereco!.isNotEmpty) {
      map['endereco'] = endereco;
    }

    if (criadoPor != null && criadoPor!.isNotEmpty) {
      map['criado_por'] = criadoPor;
    }

    // Não inclui criado_em pois o banco tem DEFAULT now()

    return map;
  }

  static FornecedorModel novo({
    required String nome,
    required String tipoDocumento,
    required String documento,
    String? email,
    String? telefone,
    String? endereco,
    String? criadoPor,
  }) {
    return FornecedorModel(
      id: '', // Deixa vazio para o banco gerar automaticamente
      nome: nome,
      tipoDocumento: tipoDocumento.toUpperCase(), // Garante maiúsculo
      documento: documento,
      email: email,
      telefone: telefone,
      endereco: endereco,
      criadoEm: DateTime.now(),
      criadoPor: criadoPor,
    );
  }

  // Método para obter o tipo de documento em minúsculo para exibição
  String get tipoDocumentoDisplay => tipoDocumento.toLowerCase();

  // Método para obter o documento formatado
  String get documentoFormatado {
    if (tipoDocumento == 'CPF') {
      // Formata CPF: 123.456.789-00
      final clean = documento.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.length == 11) {
        return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9)}';
      }
    } else if (tipoDocumento == 'CNPJ') {
      // Formata CNPJ: 12.345.678/0001-90
      final clean = documento.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.length == 14) {
        return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12)}';
      }
    }
    return documento;
  }
}
