import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venda_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../caixa/services/caixa_service.dart';

class VendaService {
  final SupabaseService _supabaseService = SupabaseService();
  final CaixaService _caixaService = CaixaService();

  Future<List<VendaModel>> getVendas() async {
    try {
      final response = await _supabaseService.client
          .from('vendas')
          .select()
          .order('criado_em', ascending: false);

      return (response as List)
          .map((venda) => VendaModel.fromMap(venda))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas: $e');
    }
  }

  Future<List<VendaModel>> getVendasPorLoja(String lojaId) async {
    try {
      final response = await _supabaseService.client
          .from('vendas')
          .select()
          .eq('loja_id', lojaId)
          .order('criado_em', ascending: false);

      return (response as List)
          .map((venda) => VendaModel.fromMap(venda))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas da loja: $e');
    }
  }

  Future<VendaModel> getVenda(String id) async {
    try {
      final response = await _supabaseService.client
          .from('vendas')
          .select()
          .eq('id', id)
          .single();

      return VendaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao buscar venda: $e');
    }
  }

  Future<VendaModel> addVenda(VendaModel venda) async {
    try {
      // IMPORTANTE: Verificar se há caixa aberto ANTES de criar a venda
      final caixaAberto = await _caixaService.getCaixaAbertoPorLoja(
        venda.lojaId,
      );

      if (caixaAberto == null) {
        throw Exception(
          'Não é possível realizar vendas sem caixa aberto. Abra um caixa primeiro.',
        );
      }

      if (caixaAberto.isFechado) {
        throw Exception(
          'Não é possível realizar vendas em caixa fechado. Abra um caixa primeiro.',
        );
      }

      print('🔧 [VendaService] Verificando caixa aberto: ${caixaAberto.id}');

      // Criar a venda
      final response = await _supabaseService.client
          .from('vendas')
          .insert(venda.toMap())
          .select()
          .single();

      final vendaCriada = VendaModel.fromMap(response);
      print('✅ [VendaService] Venda criada: ${vendaCriada.id}');

      // Registrar venda no caixa (OBRIGATÓRIO)
      try {
        print(
          '🔧 [VendaService] Registrando venda no caixa: ${vendaCriada.valorFinal}',
        );

        await _caixaService.registrarVenda(
          caixaAberto.id,
          vendaCriada.id,
          vendaCriada.valorFinal,
          venda.usuarioId ?? '',
        );

        print('✅ [VendaService] Venda registrada no caixa com sucesso');
      } catch (e) {
        print('❌ [VendaService] Erro ao registrar venda no caixa: $e');
        // IMPORTANTE: Se falhar ao registrar no caixa, ROLLBACK da venda
        try {
          await _supabaseService.client
              .from('vendas')
              .delete()
              .eq('id', vendaCriada.id);
          print('🔄 [VendaService] Rollback da venda realizado');
        } catch (rollbackError) {
          print('❌ [VendaService] Erro no rollback: $rollbackError');
        }
        throw Exception(
          'Erro ao registrar venda no caixa: $e. Venda cancelada.',
        );
      }

      return vendaCriada;
    } catch (e) {
      print('❌ [VendaService] Erro ao criar venda: $e');
      throw Exception('Erro ao criar venda: $e');
    }
  }

  Future<VendaModel> updateVenda(VendaModel venda) async {
    try {
      final response = await _supabaseService.client
          .from('vendas')
          .update(venda.toMap())
          .eq('id', venda.id)
          .select()
          .single();

      return VendaModel.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao atualizar venda: $e');
    }
  }

  Future<void> deleteVenda(String id) async {
    try {
      await _supabaseService.client.from('vendas').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar venda: $e');
    }
  }

  Future<List<VendaModel>> searchVendas(String query) async {
    try {
      final response = await _supabaseService.client
          .from('vendas')
          .select()
          .or('status.ilike.%$query%')
          .order('criado_em', ascending: false);

      return (response as List)
          .map((venda) => VendaModel.fromMap(venda))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas: $e');
    }
  }

  Future<List<VendaModel>> getVendasPorCliente(String clienteId) async {
    try {
      final response = await _supabaseService.client
          .from('vendas')
          .select()
          .eq('cliente_id', clienteId)
          .order('criado_em', ascending: false);

      return (response as List)
          .map((venda) => VendaModel.fromMap(venda))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas do cliente: $e');
    }
  }
}
