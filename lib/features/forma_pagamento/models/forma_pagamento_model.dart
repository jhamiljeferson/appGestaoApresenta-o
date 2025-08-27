import 'package:uuid/uuid.dart';

enum TipoTaxa { acrescimo, desconto }

class FormaPagamentoModel {
  final String id;
  final String nome;
  final TipoTaxa tipoTaxa;
  final double percentualTaxa;
  final DateTime? criadoEm;
  final String? criadoPor;
  final DateTime? atualizadoEm;
  final String? atualizadoPor;

  FormaPagamentoModel({
    required this.id,
    required this.nome,
    required this.tipoTaxa,
    required this.percentualTaxa,
    this.criadoEm,
    this.criadoPor,
    this.atualizadoEm,
    this.atualizadoPor,
  });

  factory FormaPagamentoModel.fromMap(Map<String, dynamic> map) {
    return FormaPagamentoModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      tipoTaxa: TipoTaxa.values.firstWhere(
        (e) => e.name == (map['tipo_taxa'] as String? ?? 'acrescimo'),
        orElse: () => TipoTaxa.acrescimo,
      ),
      percentualTaxa: (map['percentual_taxa'] as num).toDouble(),
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
      'tipo_taxa': tipoTaxa.name,
      'percentual_taxa': percentualTaxa,
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

  static FormaPagamentoModel nova({
    required String nome,
    required TipoTaxa tipoTaxa,
    required double percentualTaxa,
  }) {
    return FormaPagamentoModel(
      id: const Uuid().v4(),
      nome: nome,
      tipoTaxa: tipoTaxa,
      percentualTaxa: percentualTaxa,
      criadoEm: DateTime.now(),
    );
  }

  // Método para calcular o valor final com a taxa
  double calcularValorComTaxa(double valorBase) {
    if (tipoTaxa == TipoTaxa.acrescimo) {
      return valorBase * (1 + percentualTaxa / 100);
    } else {
      return valorBase * (1 - percentualTaxa / 100);
    }
  }

  // Método para obter o valor da taxa
  double obterValorTaxa(double valorBase) {
    return valorBase * (percentualTaxa / 100);
  }

  // Método para obter descrição da taxa
  String get descricaoTaxa {
    if (tipoTaxa == TipoTaxa.acrescimo) {
      return 'Adiciona ${percentualTaxa.toStringAsFixed(2)}% ao valor';
    } else {
      return 'Desconta ${percentualTaxa.toStringAsFixed(2)}% do valor';
    }
  }

  FormaPagamentoModel copyWith({
    String? id,
    String? nome,
    TipoTaxa? tipoTaxa,
    double? percentualTaxa,
    DateTime? criadoEm,
    String? criadoPor,
    DateTime? atualizadoEm,
    String? atualizadoPor,
  }) {
    return FormaPagamentoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipoTaxa: tipoTaxa ?? this.tipoTaxa,
      percentualTaxa: percentualTaxa ?? this.percentualTaxa,
      criadoEm: criadoEm ?? this.criadoEm,
      criadoPor: criadoPor ?? this.criadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
    );
  }
}
