import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cargo_model.dart';
import '../models/permissao_model.dart';
import '../../../core/services/supabase_service.dart';

class CargoService {
  final SupabaseClient _client = SupabaseService().client;
  final String _table = 'cargos';

  // ==================================
  // OPERAÇÕES DE CARGOS
  // ==================================

  Future<List<CargoModel>> getCargos() async {
    try {
      print('🔧 [CargoService] Buscando cargos...');

      // Usar select específico em vez de select()
      final data = await _client
          .from(_table)
          .select('id, nome, criado_por, atualizado_por')
          .order('nome')
          .then((value) => value as List);

      final cargos = data.map((e) => CargoModel.fromMap(e)).toList();
      print('✅ [CargoService] ${cargos.length} cargos carregados');
      return cargos;
    } catch (e) {
      print('❌ [CargoService] Erro ao buscar cargos: $e');
      throw Exception('Erro ao buscar cargos: $e');
    }
  }

  Future<CargoModel?> getCargo(String id) async {
    try {
      print('🔧 [CargoService] Buscando cargo com ID: $id');

      // Usar select específico em vez de select=*
      final data = await _client
          .from(_table)
          .select('id, nome, criado_por, atualizado_por')
          .eq('id', id)
          .maybeSingle(); // Usar maybeSingle para evitar erro quando não encontrar

      print('🔧 [CargoService] Resposta da busca: $data');

      if (data == null) {
        print('⚠️ [CargoService] Cargo não encontrado com ID: $id');

        // Tentar buscar todos os cargos para debug
        try {
          final todosCargos = await _client
              .from(_table)
              .select('id, nome')
              .limit(10);
          print(
            '🔍 [CargoService] Cargos disponíveis (primeiros 10): $todosCargos',
          );
        } catch (e) {
          print('❌ [CargoService] Erro ao buscar cargos para debug: $e');
        }

        return null;
      }

      final cargo = CargoModel.fromMap(data);
      print(
        '✅ [CargoService] Cargo encontrado: ${cargo.nome} (ID: ${cargo.id})',
      );
      return cargo;
    } catch (e) {
      print('❌ [CargoService] Erro ao buscar cargo $id: $e');
      if (e.toString().contains('PGRST116')) {
        print('⚠️ [CargoService] Cargo não encontrado (PGRST116)');
        return null;
      }
      throw Exception('Erro ao buscar cargo: $e');
    }
  }

  /// Busca cargo com retry e delay progressivo (útil após criação)
  Future<CargoModel?> getCargoComRetry(
    String id, {
    int maxTentativas = 3,
  }) async {
    try {
      print('🔧 [CargoService] Buscando cargo com retry, ID: $id');

      for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
        print('🔧 [CargoService] Tentativa $tentativa de $maxTentativas');

        final cargo = await getCargo(id);
        if (cargo != null) {
          print('✅ [CargoService] Cargo encontrado na tentativa $tentativa');
          return cargo;
        }

        if (tentativa < maxTentativas) {
          final delay = Duration(
            milliseconds: 200 * tentativa,
          ); // Delay progressivo: 200ms, 400ms, 600ms
          print(
            '⏳ [CargoService] Aguardando ${delay.inMilliseconds}ms antes da próxima tentativa...',
          );
          await Future.delayed(delay);
        }
      }

      print(
        '❌ [CargoService] Cargo não encontrado após $maxTentativas tentativas',
      );
      return null;
    } catch (e) {
      print('❌ [CargoService] Erro no getCargoComRetry: $e');
      return null;
    }
  }

  Future<CargoModel> addCargo(CargoModel cargo) async {
    try {
      print('🔧 [CargoService] Adicionando cargo com campos: ${cargo.toMap()}');

      // Preparar dados para inserção (SEM ID - deixar o banco gerar)
      final dados = {
        'nome': cargo.nome,
        'criado_por': cargo.criadoPor,
        'atualizado_por': cargo.atualizadoPor,
      };

      print('🔧 [CargoService] Dados para inserção: $dados');
      print('🔧 [CargoService] ID será gerado pelo banco de dados');

      // Inserir cargo
      final response = await _client
          .from(_table)
          .insert(dados)
          .select('id, nome, criado_por, atualizado_por')
          .single();

      print('🔧 [CargoService] Resposta da inserção: $response');

      // Criar objeto CargoModel com o ID retornado pelo banco
      final cargoCriado = CargoModel(
        id: response['id'],
        nome: response['nome'],
        criadoPor: response['criado_por'],
        atualizadoPor: response['atualizado_por'],
      );

      print(
        '✅ [CargoService] Cargo criado com sucesso: ${cargoCriado.toMap()}',
      );

      // Aguardar um pouco para garantir que a transação foi commitada
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar se o cargo realmente existe usando retry
      final cargoVerificado = await getCargoComRetry(cargoCriado.id);
      if (cargoVerificado == null) {
        print(
          '⚠️ [CargoService] Cargo criado mas não encontrado na verificação',
        );
        throw Exception(
          'Cargo foi criado mas não pode ser verificado após múltiplas tentativas',
        );
      }

      print('✅ [CargoService] Cargo verificado com sucesso após criação');
      return cargoCriado;
    } catch (e) {
      print('❌ [CargoService] Erro ao adicionar cargo: $e');
      print('❌ [CargoService] Dados tentados: ${cargo.toMap()}');
      throw Exception('Erro ao adicionar cargo: $e');
    }
  }

  Future<void> updateCargo(CargoModel cargo) async {
    try {
      // A tabela cargos só tem: id, nome, criado_por, atualizado_por
      // NÃO TEM: criado_em, atualizado_em
      final map = <String, dynamic>{};

      // Campos obrigatórios que sempre existem
      map['nome'] = cargo.nome;

      // Campos opcionais - só incluir se não forem nulos
      if (cargo.atualizadoPor != null && cargo.atualizadoPor!.isNotEmpty) {
        map['atualizado_por'] = cargo.atualizadoPor;
      }

      print('🔧 [CargoService] Atualizando cargo com campos: $map');

      await _client.from(_table).update(map).eq('id', cargo.id);
    } catch (e) {
      print('❌ [CargoService] Erro ao atualizar cargo: $e');
      print('❌ [CargoService] Dados tentados: ${cargo.toMap()}');
      throw Exception('Erro ao atualizar cargo: $e');
    }
  }

  Future<void> deleteCargo(String id) async {
    try {
      // Primeiro remove as permissões do cargo
      await _client.from('cargos_permissoes').delete().eq('cargo_id', id);
      // Depois remove o cargo
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar cargo: $e');
    }
  }

  // ==================================
  // OPERAÇÕES DE PERMISSÕES
  // ==================================

  Future<List<PermissaoModel>> getPermissoes() async {
    try {
      final data = await _client
          .from('permissoes')
          .select()
          .order('recurso')
          .order('acao');

      // Validação adicional para evitar erros de tipo
      if (data == null || data.isEmpty) {
        return [];
      }

      return data
          .map((e) {
            if (e is Map<String, dynamic>) {
              return PermissaoModel.fromMap(e);
            } else {
              print('⚠️ [CargoService] Dados inválidos recebidos: $e');
              return null;
            }
          })
          .whereType<PermissaoModel>()
          .toList();
    } catch (e) {
      print('❌ [CargoService] Erro ao buscar permissões: $e');
      throw Exception('Erro ao buscar permissões: $e');
    }
  }

  Future<List<PermissaoModel>> getPermissoesDoCargo(String cargoId) async {
    try {
      final data = await _client
          .from('cargos_permissoes')
          .select('permissao_id, permissoes(*)')
          .eq('cargo_id', cargoId);

      // Validação adicional para evitar erros de tipo
      if (data == null || data.isEmpty) {
        return [];
      }

      // Corrigindo o tipo de retorno e tratamento de dados
      return data
          .map((e) {
            try {
              final permissaoData = e['permissoes'] as Map<String, dynamic>?;
              if (permissaoData != null) {
                return PermissaoModel.fromMap(permissaoData);
              } else {
                print('⚠️ [CargoService] Dados de permissão inválidos: $e');
                return null;
              }
            } catch (e) {
              print('⚠️ [CargoService] Erro ao processar permissão: $e');
              return null;
            }
          })
          .whereType<PermissaoModel>()
          .toList();
    } catch (e) {
      print('❌ [CargoService] Erro ao buscar permissões do cargo: $e');
      throw Exception('Erro ao buscar permissões do cargo: $e');
    }
  }

  Future<List<String>> getPermissoesIdsDoCargo(String cargoId) async {
    try {
      final data = await _client
          .from('cargos_permissoes')
          .select('permissao_id')
          .eq('cargo_id', cargoId);

      // Validação adicional para evitar erros de tipo
      if (data == null || data.isEmpty) {
        return [];
      }

      return data
          .map((e) {
            try {
              final permissaoId = e['permissao_id'];
              if (permissaoId is String && permissaoId.isNotEmpty) {
                return permissaoId;
              } else {
                print(
                  '⚠️ [CargoService] ID de permissão inválido: $permissaoId',
                );
                return null;
              }
            } catch (e) {
              print('⚠️ [CargoService] Erro ao processar ID de permissão: $e');
              return null;
            }
          })
          .whereType<String>()
          .toList();
    } catch (e) {
      print('❌ [CargoService] Erro ao buscar IDs das permissões do cargo: $e');
      throw Exception('Erro ao buscar IDs das permissões do cargo: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPermissoesDoUsuario(
    String? cargoId,
  ) async {
    if (cargoId == null) return [];

    try {
      final data = await _client
          .from('cargos_permissoes')
          .select('permissao_id, permissoes(recurso, acao)')
          .eq('cargo_id', cargoId);

      // Validação adicional para evitar erros de tipo
      if (data == null || data.isEmpty) {
        return [];
      }

      // Corrigindo o tipo de retorno
      return data
          .map((e) {
            try {
              final permissao = e['permissoes'] as Map<String, dynamic>?;
              if (permissao != null &&
                  permissao['recurso'] is String &&
                  permissao['acao'] is String) {
                return {
                  'recurso': permissao['recurso'] as String,
                  'acao': permissao['acao'] as String,
                };
              } else {
                print(
                  '⚠️ [CargoService] Dados de permissão inválidos: $permissao',
                );
                return null;
              }
            } catch (e) {
              print(
                '⚠️ [CargoService] Erro ao processar permissão do usuário: $e',
              );
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('❌ [CargoService] Erro ao buscar permissões do usuário: $e');
      throw Exception('Erro ao buscar permissões do usuário: $e');
    }
  }

  // ==================================
  // GESTÃO DE PERMISSÕES
  // ==================================

  Future<void> salvarPermissoesDoCargo(
    String cargoId,
    List<String> permissaoIds,
  ) async {
    try {
      print('🔧 [CargoService] Salvando permissões para cargo $cargoId');
      print('🔧 [CargoService] Permissões a salvar: $permissaoIds');

      // Primeiro, remover todas as permissões existentes do cargo
      await _client.from('cargos_permissoes').delete().eq('cargo_id', cargoId);

      print('🔧 [CargoService] Permissões existentes removidas');

      // Se não há permissões para salvar, apenas retorna
      if (permissaoIds.isEmpty) {
        print('🔧 [CargoService] Nenhuma permissão para salvar');
        return;
      }

      // Preparar dados para inserção
      final dadosParaInserir = permissaoIds
          .map(
            (permissaoId) => {'cargo_id': cargoId, 'permissao_id': permissaoId},
          )
          .toList();

      print('🔧 [CargoService] Dados para inserir: $dadosParaInserir');

      // Inserir novas permissões
      await _client.from('cargos_permissoes').insert(dadosParaInserir);

      print('✅ [CargoService] Permissões salvas com sucesso');
    } catch (e) {
      print('❌ [CargoService] Erro ao salvar permissões do cargo: $e');
      print('❌ [CargoService] Cargo ID: $cargoId');
      print('❌ [CargoService] Permissões IDs: $permissaoIds');
      throw Exception('Erro ao salvar permissões do cargo: $e');
    }
  }

  Future<void> adicionarPermissaoAoCargo(
    String cargoId,
    String permissaoId,
  ) async {
    try {
      await _client.from('cargos_permissoes').insert({
        'cargo_id': cargoId,
        'permissao_id': permissaoId,
      });
    } catch (e) {
      throw Exception('Erro ao adicionar permissão ao cargo: $e');
    }
  }

  Future<void> removerPermissaoDoCargo(
    String cargoId,
    String permissaoId,
  ) async {
    try {
      await _client
          .from('cargos_permissoes')
          .delete()
          .eq('cargo_id', cargoId)
          .eq('permissao_id', permissaoId);
    } catch (e) {
      throw Exception('Erro ao remover permissão do cargo: $e');
    }
  }

  // ==================================
  // VERIFICAÇÕES
  // ==================================

  Future<bool> cargoTemPermissao(
    String cargoId,
    String recurso,
    String acao,
  ) async {
    try {
      final data = await _client
          .from('cargos_permissoes')
          .select('permissao_id, permissoes(recurso, acao)')
          .eq('cargo_id', cargoId)
          .eq('permissoes.recurso', recurso)
          .eq('permissoes.acao', acao);

      return data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cargoExiste(String nome) async {
    try {
      final data = await _client
          .from(_table)
          .select('id')
          .eq('nome', nome)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  // ==================================
  // MÉTODOS EM LOTE PARA CARGOS_PERMISSOES
  // ==================================

  /// Adiciona múltiplas permissões a um cargo em uma única operação
  Future<void> adicionarPermissoesEmLote(
    String cargoId,
    List<String> permissaoIds,
  ) async {
    try {
      print(
        '🔧 [CargoService] Adicionando ${permissaoIds.length} permissões em lote para cargo $cargoId',
      );

      if (permissaoIds.isEmpty) {
        print('🔧 [CargoService] Nenhuma permissão para adicionar');
        return;
      }

      // Preparar dados para inserção em lote
      final dadosParaInserir = permissaoIds
          .map(
            (permissaoId) => {'cargo_id': cargoId, 'permissao_id': permissaoId},
          )
          .toList();

      print(
        '🔧 [CargoService] Inserindo ${dadosParaInserir.length} permissões em lote',
      );

      // Inserir todas as permissões de uma vez
      await _client.from('cargos_permissoes').insert(dadosParaInserir);

      print(
        '✅ [CargoService] ${permissaoIds.length} permissões adicionadas em lote com sucesso',
      );
    } catch (e) {
      print('❌ [CargoService] Erro ao adicionar permissões em lote: $e');
      print('❌ [CargoService] Cargo ID: $cargoId');
      print('❌ [CargoService] Permissões IDs: $permissaoIds');
      throw Exception('Erro ao adicionar permissões em lote: $e');
    }
  }

  /// Remove múltiplas permissões de um cargo em uma única operação
  Future<void> removerPermissoesEmLote(
    String cargoId,
    List<String> permissaoIds,
  ) async {
    try {
      print(
        '🔧 [CargoService] Removendo ${permissaoIds.length} permissões em lote do cargo $cargoId',
      );

      if (permissaoIds.isEmpty) {
        print('🔧 [CargoService] Nenhuma permissão para remover');
        return;
      }

      // Remover múltiplas permissões de uma vez usando IN
      await _client
          .from('cargos_permissoes')
          .delete()
          .eq('cargo_id', cargoId)
          .in_('permissao_id', permissaoIds);

      print(
        '✅ [CargoService] ${permissaoIds.length} permissões removidas em lote com sucesso',
      );
    } catch (e) {
      print('❌ [CargoService] Erro ao remover permissões em lote: $e');
      print('❌ [CargoService] Cargo ID: $cargoId');
      print('❌ [CargoService] Permissões IDs: $permissaoIds');
      throw Exception('Erro ao remover permissões em lote: $e');
    }
  }

  /// Sincroniza permissões de um cargo (remove todas e adiciona as novas)
  Future<void> sincronizarPermissoesEmLote(
    String cargoId,
    List<String> novasPermissaoIds,
  ) async {
    try {
      print(
        '🔧 [CargoService] Sincronizando permissões em lote para cargo $cargoId',
      );
      print('🔧 [CargoService] Novas permissões: $novasPermissaoIds');

      // Primeiro, remover todas as permissões existentes
      await _client.from('cargos_permissoes').delete().eq('cargo_id', cargoId);

      print('🔧 [CargoService] Permissões existentes removidas');

      // Se não há novas permissões, apenas retorna
      if (novasPermissaoIds.isEmpty) {
        print(
          '🔧 [CargoService] Nenhuma permissão para adicionar após sincronização',
        );
        return;
      }

      // Adicionar todas as novas permissões em lote
      await adicionarPermissoesEmLote(cargoId, novasPermissaoIds);

      print('✅ [CargoService] Sincronização em lote concluída com sucesso');
    } catch (e) {
      print('❌ [CargoService] Erro na sincronização em lote: $e');
      print('❌ [CargoService] Cargo ID: $cargoId');
      print('❌ [CargoService] Novas permissões: $novasPermissaoIds');
      throw Exception('Erro na sincronização em lote: $e');
    }
  }

  /// Busca permissões de múltiplos cargos em uma única operação
  Future<Map<String, List<PermissaoModel>>> getPermissoesDeMultiplosCargos(
    List<String> cargoIds,
  ) async {
    try {
      print(
        '🔧 [CargoService] Buscando permissões para ${cargoIds.length} cargos em lote',
      );

      if (cargoIds.isEmpty) {
        return {};
      }

      // Buscar permissões de múltiplos cargos usando IN
      final data = await _client
          .from('cargos_permissoes')
          .select('''
            cargo_id,
            permissao_id,
            permissoes!inner(
              id,
              recurso,
              acao,
              criado_em,
              criado_por,
              atualizado_em,
              atualizado_por
            )
          ''')
          .in_('cargo_id', cargoIds);

      // Agrupar permissões por cargo
      final Map<String, List<PermissaoModel>> permissoesPorCargo = {};

      for (final item in data) {
        final cargoId = item['cargo_id'] as String;
        final permissaoData = item['permissoes'] as Map<String, dynamic>;

        final permissao = PermissaoModel.fromMap(permissaoData);

        permissoesPorCargo.putIfAbsent(cargoId, () => []).add(permissao);
      }

      print(
        '✅ [CargoService] Permissões de ${cargoIds.length} cargos carregadas em lote',
      );
      return permissoesPorCargo;
    } catch (e) {
      print(
        '❌ [CargoService] Erro ao buscar permissões de múltiplos cargos: $e',
      );
      throw Exception('Erro ao buscar permissões de múltiplos cargos: $e');
    }
  }

  /// Busca cargos com suas permissões em uma única operação
  Future<List<Map<String, dynamic>>> getCargosComPermissoesEmLote() async {
    try {
      print('🔧 [CargoService] Buscando cargos com permissões em lote');

      // Buscar cargos com suas permissões usando JOIN com select específico
      final data = await _client
          .from(_table)
          .select('''
            id,
            nome,
            criado_por,
            atualizado_por,
            cargos_permissoes(
              permissao_id,
              permissoes!inner(
                id,
                recurso,
                acao
              )
            )
          ''')
          .order('nome');

      final cargosComPermissoes = (data as List).map((cargoData) {
        final cargo = CargoModel.fromMap(cargoData);
        final permissoesData = cargoData['cargos_permissoes'] as List? ?? [];

        final permissoes = permissoesData.map((p) {
          final permissaoData = p['permissoes'] as Map<String, dynamic>;
          return PermissaoModel.fromMap(permissaoData);
        }).toList();

        return <String, dynamic>{
          'cargo': cargo,
          'permissoes': permissoes,
          'quantidadePermissoes': permissoes.length,
        };
      }).toList();

      print(
        '✅ [CargoService] ${cargosComPermissoes.length} cargos com permissões carregados em lote',
      );
      return cargosComPermissoes;
    } catch (e) {
      print(
        '❌ [CargoService] Erro ao buscar cargos com permissões em lote: $e',
      );
      throw Exception('Erro ao buscar cargos com permissões em lote: $e');
    }
  }

  // ==================================
  // MÉTODOS EXISTENTES (mantidos para compatibilidade)
  // ==================================
}
