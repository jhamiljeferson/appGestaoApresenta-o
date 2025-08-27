import 'package:uuid/uuid.dart';

class ProdutoModel {
  final String id;
  final String nome;
  final String sku;
  final String codigo;
  final double precoCusto;
  final double precoAtacado;
  final double? precoPromocional;
  final double precoVarejo;
  final String? categoriaId;
  final String? fornecedorId;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  ProdutoModel({
    required this.id,
    required this.nome,
    required this.sku,
    required this.codigo,
    required this.precoCusto,
    required this.precoAtacado,
    this.precoPromocional,
    required this.precoVarejo,
    this.categoriaId,
    this.fornecedorId,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory ProdutoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      sku: map['sku'] as String,
      codigo: map['codigo'] as String,
      precoCusto: (map['preco_custo'] as num).toDouble(),
      precoAtacado: (map['preco_atacado'] as num?)?.toDouble() ?? 0,
      precoPromocional: map['preco_promocional'] != null
          ? (map['preco_promocional'] as num).toDouble()
          : null,
      precoVarejo: (map['preco_varejo'] as num).toDouble(),
      categoriaId: map['categoria_id'] as String?,
      fornecedorId: map['fornecedor_id'] as String?,
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
      'sku': sku,
      'codigo': codigo,
      'preco_custo': precoCusto,
      'preco_atacado': precoAtacado,
      'preco_promocional': precoPromocional,
      'preco_varejo': precoVarejo,
      'categoria_id': categoriaId?.isNotEmpty == true ? categoriaId : null,
      'fornecedor_id': fornecedorId?.isNotEmpty == true ? fornecedorId : null,
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

  static ProdutoModel novo({
    required String nome,
    required String sku,
    required String codigo,
    required double precoCusto,
    required double precoAtacado,
    double? precoPromocional,
    required double precoVarejo,
    String? categoriaId,
    String? fornecedorId,
  }) {
    return ProdutoModel(
      id: const Uuid().v4(),
      nome: nome,
      sku: sku,
      codigo: codigo,
      precoCusto: precoCusto,
      precoAtacado: precoAtacado,
      precoPromocional: precoPromocional,
      precoVarejo: precoVarejo,
      categoriaId: categoriaId,
      fornecedorId: fornecedorId,
      criadoEm: DateTime.now(),
    );
  }

  ProdutoModel copyWith({
    String? id,
    String? nome,
    String? sku,
    String? codigo,
    double? precoCusto,
    double? precoAtacado,
    double? precoPromocional,
    double? precoVarejo,
    String? categoriaId,
    String? fornecedorId,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sku: sku ?? this.sku,
      codigo: codigo ?? this.codigo,
      precoCusto: precoCusto ?? this.precoCusto,
      precoAtacado: precoAtacado ?? this.precoAtacado,
      precoPromocional: precoPromocional ?? this.precoPromocional,
      precoVarejo: precoVarejo ?? this.precoVarejo,
      categoriaId: categoriaId ?? this.categoriaId,
      fornecedorId: fornecedorId ?? this.fornecedorId,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }
}
