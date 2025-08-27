import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/views/login_view.dart';
import '../features/dashboard/views/dashboard_view.dart';
import '../features/lojas/views/loja_list_view.dart';
import '../features/categoria/views/categoria_list_view.dart';
import '../features/produto/views/produto_list_view.dart';
import '../features/estoque/views/estoque_list_view.dart';
import '../features/fornecedor/views/fornecedor_list_view.dart';
import '../features/cargo/views/cargo_list_view.dart';
import '../features/usuario/views/usuario_list_view.dart';
import '../features/cargo/services/cargo_service.dart';
import '../features/forma_pagamento/views/forma_pagamento_list_view.dart';
import '../features/movimentacao_estoque/views/movimentacao_list_view.dart';
import '../features/movimentacao_estoque/views/nova_movimentacao_view.dart';
import '../features/movimentacao_estoque/views/entrada_estoque_list_view.dart';
import '../features/movimentacao_estoque/views/nova_entrada_estoque_view.dart';
import '../features/movimentacao_estoque/views/saida_estoque_list_view.dart';
import '../features/movimentacao_estoque/views/nova_saida_estoque_view.dart';
import '../features/movimentacao_estoque/views/troca_estoque_list_view.dart';
import '../features/movimentacao_estoque/views/nova_troca_estoque_view.dart';
import '../features/movimentacao_estoque/views/transferencia_estoque_list_view.dart';
import '../features/movimentacao_estoque/views/nova_transferencia_estoque_view.dart';
import '../features/cliente/views/cliente_list_view.dart';
import '../features/cliente/views/cliente_form_view.dart';
import '../features/cliente/views/cliente_detail_view.dart';
import '../features/venda/views/venda_list_view.dart';
import '../features/venda/views/nova_venda_view.dart';
import '../features/caixa/views/caixa_view.dart';
import '../features/caixa/views/caixa_movimentacoes_view.dart';
import '../features/caixa/views/caixa_historico_view.dart';
import '../features/caixa/views/caixa_fechamento_view.dart';

// Provider para o router que reage às mudanças de autenticação
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = authState;
      final isLoggingIn = state.uri.toString() == '/login';
      
      print('[Router] Redirect - isLoggedIn: $isLoggedIn, isLoggingIn: $isLoggingIn');
      
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      
      // Controle de permissão por rota
      if (isLoggedIn) {
        final cargoId = await AuthController.getCargoIdUsuarioLogado();
        final permissoes = await CargoService().getPermissoesDoUsuario(cargoId);
        final rota = state.uri.toString();
        // Mapeamento simples rota -> recurso
        final rotaRecurso = {
          '/produtos': 'produtos',
          '/categorias': 'categorias',
          '/lojas': 'lojas',
          '/fornecedores': 'fornecedores',
          '/estoque': 'estoque',
          '/movimentacoes': 'estoque',
          '/nova-movimentacao': 'estoque',
          '/entradas-estoque': 'estoque',
          '/nova-entrada-estoque': 'estoque',
          '/saidas-estoque': 'estoque',
          '/nova-saida-estoque': 'estoque',
          '/trocas-estoque': 'estoque',
          '/nova-troca-estoque': 'estoque',
          '/transferencias-estoque': 'estoque',
          '/nova-transferencia-estoque': 'estoque',
          '/cargos': 'cargos',
          '/usuarios': 'usuarios',
          '/formas-pagamento': 'formas_pagamento',
          '/clientes': 'clientes',
          '/clientes/novo': 'clientes',
          '/clientes/:id': 'clientes',
          '/clientes/:id/editar': 'clientes',
          '/vendas': 'vendas',
          '/vendas/nova': 'vendas',
          '/caixa': 'caixa',
          '/caixa/movimentacoes': 'caixa',
          '/caixa/historico': 'caixa',
          '/caixa/fechamento/:id': 'caixa',
          '/formas-pagamento': 'formas_pagamento',
          '/cargos': 'cargos',
          '/usuarios': 'usuarios',
          '/configuracoes': null, // configurações sempre visível
        };
        final recurso = rotaRecurso[rota];
        if (recurso != null) {
          final temPermissao = permissoes.any(
            (p) => p['recurso'] == recurso && p['acao'] == 'listar',
          );
          if (!temPermissao) return '/acesso-negado';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(path: '/lojas', builder: (context, state) => const LojaListView()),
      GoRoute(
        path: '/categorias',
        builder: (context, state) => const CategoriaListView(),
      ),
      GoRoute(
        path: '/produtos',
        builder: (context, state) => const ProdutoListView(),
      ),
      GoRoute(
        path: '/fornecedores',
        builder: (context, state) => const FornecedorListView(),
      ),
      GoRoute(
        path: '/estoque',
        builder: (context, state) => const EstoqueListView(),
      ),
      GoRoute(
        path: '/movimentacoes',
        builder: (context, state) => const MovimentacaoListView(),
      ),
      GoRoute(
        path: '/nova-movimentacao',
        builder: (context, state) => const NovaMovimentacaoView(),
      ),
      GoRoute(
        path: '/entradas-estoque',
        builder: (context, state) => const EntradaEstoqueListView(),
      ),
      GoRoute(
        path: '/nova-entrada-estoque',
        builder: (context, state) => const NovaEntradaEstoqueView(),
      ),
      GoRoute(
        path: '/saidas-estoque',
        builder: (context, state) => const SaidaEstoqueListView(),
      ),
      GoRoute(
        path: '/nova-saida-estoque',
        builder: (context, state) => const NovaSaidaEstoqueView(),
      ),
      GoRoute(
        path: '/trocas-estoque',
        builder: (context, state) => const TrocaEstoqueListView(),
      ),
      GoRoute(
        path: '/nova-troca-estoque',
        builder: (context, state) => const NovaTrocaEstoqueView(),
      ),
      GoRoute(
        path: '/transferencias-estoque',
        builder: (context, state) => const TransferenciaEstoqueListView(),
      ),
      GoRoute(
        path: '/nova-transferencia-estoque',
        builder: (context, state) => const NovaTransferenciaEstoqueView(),
      ),
      GoRoute(
        path: '/cargos',
        builder: (context, state) => const CargoListView(),
      ),
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const UsuarioListView(),
      ),
      GoRoute(
        path: '/formas-pagamento',
        builder: (context, state) => const FormaPagamentoListView(),
      ),
      GoRoute(
        path: '/clientes',
        builder: (context, state) => const ClienteListView(),
      ),
      GoRoute(
        path: '/clientes/novo',
        builder: (context, state) => const ClienteFormView(),
      ),
      GoRoute(
        path: '/clientes/:id',
        builder: (context, state) =>
            ClienteDetailView(clienteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clientes/:id/editar',
        builder: (context, state) =>
            ClienteFormView(clienteId: state.pathParameters['id']),
      ),
      // Rotas de Vendas
      GoRoute(
        path: '/vendas',
        builder: (context, state) => const VendaListView(),
      ),
      GoRoute(
        path: '/vendas/nova',
        builder: (context, state) => const NovaVendaView(),
      ),
      // Rotas do Caixa
      GoRoute(path: '/caixa', builder: (context, state) => const CaixaView()),
      GoRoute(
        path: '/caixa/movimentacoes',
        builder: (context, state) => const CaixaMovimentacoesView(),
      ),
      GoRoute(
        path: '/caixa/historico',
        builder: (context, state) => const CaixaHistoricoView(),
      ),
      GoRoute(
        path: '/caixa/fechamento/:id',
        builder: (context, state) => CaixaFechamentoView(
          caixaId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/acesso-negado',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Acesso negado'))),
      ),
    ],
  );
});

// Para compatibilidade com código existente
final appRouter = routerProvider;
