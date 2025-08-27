# Documento Técnico - Módulo Caixa

## Visão Geral

O módulo Caixa é responsável por gerenciar o fluxo de caixa das lojas, permitindo abertura, fechamento, registro de movimentações e controle de vendas. O sistema utiliza uma arquitetura baseada em Riverpod para gerenciamento de estado e Supabase como banco de dados.

## Estrutura de Arquivos

```
lib/features/caixa/
├── models/
│   ├── caixa_model.dart
│   ├── caixa_movimentacao_model.dart
│   └── index.dart
├── controllers/
│   ├── caixa_controller.dart
│   └── index.dart
├── services/
│   ├── caixa_service.dart
│   ├── caixa_calculo_service.dart
│   ├── caixa_vendas_service.dart
│   └── index.dart
├── providers/
│   └── caixa_vendas_provider.dart
├── views/
│   ├── caixa_view.dart
│   ├── caixa_movimentacoes_view.dart
│   ├── caixa_historico_view.dart
│   └── index.dart
└── widgets/
    └── index.dart
```

## 1. Models (Modelos de Dados)

### 1.1 CaixaModel (`caixa_model.dart`)

**Propósito**: Define a estrutura de dados para representar um caixa no sistema.

**Enums**:
- `StatusCaixa`: Define os estados possíveis do caixa
  - `aberto`: Caixa ativo e operacional
  - `fechado`: Caixa inativo e fechado

**Propriedades Principais**:
- `id`: Identificador único do caixa
- `lojaId`: ID da loja associada ao caixa
- `usuarioAberturaId`: ID do usuário que abriu o caixa
- `usuarioFechamentoId`: ID do usuário que fechou o caixa (opcional)
- `dataAbertura`: Data e hora de abertura
- `dataFechamento`: Data e hora de fechamento (opcional)
- `saldoInicial`: Valor inicial do caixa
- `saldoFinal`: Valor final do caixa (opcional)
- `status`: Status atual do caixa (aberto/fechado)

**Métodos Principais**:
- `fromMap()`: Converte dados do banco para objeto
- `toMap()`: Converte objeto para formato do banco
- `novo()`: Factory para criar novo caixa
- `copyWith()`: Cria cópia com alterações
- `isAberto`/`isFechado`: Getters para verificar status

### 1.2 CaixaMovimentacaoModel (`caixa_movimentacao_model.dart`)

**Propósito**: Define a estrutura para movimentações financeiras do caixa.

**Enums**:
- `TipoMovimentacaoCaixa`: Define os tipos de movimentação
  - `entrada`: Dinheiro adicionado ao caixa
  - `saida`: Dinheiro retirado do caixa
  - `venda`: Receita de vendas

**Propriedades Principais**:
- `id`: Identificador único da movimentação
- `caixaId`: ID do caixa relacionado
- `tipo`: Tipo da movimentação
- `valor`: Valor da movimentação
- `usuarioId`: ID do usuário que registrou
- `data`: Data e hora da movimentação
- `descricao`: Descrição opcional
- `vendaId`: ID da venda relacionada (para movimentações de venda)

**Métodos Principais**:
- `fromMap()`: Converte dados do banco para objeto
- `toMap()`: Converte objeto para formato do banco
- `novo()`: Factory para criar nova movimentação
- `copyWith()`: Cria cópia com alterações
- `isEntrada`/`isSaida`/`isVenda`: Getters para verificar tipo

## 2. Controllers (Controladores)

### 2.1 CaixaController (`caixa_controller.dart`)

**Propósito**: Gerencia o estado global dos caixas e coordena operações.

**Providers Principais**:
- `caixaProvider`: Lista de caixas com estado assíncrono
- `caixaAtivoProvider`: Caixa atualmente ativo
- `movimentacoesCaixaProvider`: Movimentações de um caixa específico
- `saldoAtualProvider`: Saldo atual de um caixa
- `resumoCaixaProvider`: Resumo financeiro de um caixa

**Métodos Principais**:

#### `loadCaixas()`
- **Função**: Carrega todos os caixas do sistema
- **Fluxo**: Busca dados via service e atualiza estado

#### `loadCaixasPorLoja(String lojaId)`
- **Função**: Carrega caixas de uma loja específica
- **Parâmetros**: ID da loja
- **Fluxo**: Filtra caixas por loja e atualiza estado

#### `getCaixaAbertoPorLoja(String lojaId)`
- **Função**: Busca caixa aberto de uma loja
- **Retorno**: CaixaModel ou null
- **Uso**: Verificar se já existe caixa aberto

#### `abrirCaixa(String lojaId, String usuarioId, double saldoInicial)`
- **Função**: Abre um novo caixa
- **Validações**:
  - Verifica se lojaId não está vazio
  - Verifica se usuarioId não está vazio
  - Verifica se saldoInicial não é negativo
- **Fluxo**: Cria caixa, salva no banco, recarrega lista

#### `registrarMovimentacao(...)`
- **Função**: Registra movimentação no caixa
- **Parâmetros**: caixaId, tipo, valor, usuarioId, descricao, vendaId
- **Fluxo**: Cria movimentação e salva via service

#### `registrarVenda(...)`
- **Função**: Registra venda no caixa
- **Parâmetros**: caixaId, vendaId, valor, usuarioId
- **Fluxo**: Delega para service específico

#### `registrarEntrada(...)` / `registrarSaida(...)`
- **Função**: Registra entrada/saída de dinheiro
- **Fluxo**: Cria movimentação do tipo correspondente

#### `deleteCaixa(String caixaId)`
- **Função**: Remove caixa do sistema
- **Fluxo**: Deleta via service e atualiza estado local

#### `deleteMovimentacao(String movimentacaoId, String caixaId)`
- **Função**: Remove movimentação específica
- **Fluxo**: Deleta via service e invalida providers

## 3. Services (Serviços)

### 3.1 CaixaService (`caixa_service.dart`)

**Propósito**: Gerencia operações de banco de dados para caixas e movimentações.

**Métodos de Caixa**:

#### `getCaixas()`
- **Função**: Busca todos os caixas
- **Query**: `SELECT * FROM caixa ORDER BY criado_em DESC`
- **Retorno**: Lista de CaixaModel

#### `getCaixasPorLoja(String lojaId)`
- **Função**: Busca caixas de uma loja
- **Query**: `SELECT * FROM caixa WHERE loja_id = ? ORDER BY criado_em DESC`
- **Retorno**: Lista filtrada de CaixaModel

#### `getCaixaAbertoPorLoja(String lojaId)`
- **Função**: Busca caixa aberto de uma loja
- **Query**: `SELECT * FROM caixa WHERE loja_id = ? AND status = 'aberto'`
- **Retorno**: CaixaModel ou null

#### `getCaixa(String id)`
- **Função**: Busca caixa específico por ID
- **Query**: `SELECT * FROM caixa WHERE id = ?`
- **Retorno**: CaixaModel

#### `abrirCaixa(CaixaModel caixa)`
- **Função**: Abre novo caixa
- **Validações**:
  - Verifica se já existe caixa aberto
  - Valida se usuário existe
  - Valida se loja existe
- **Fluxo**: Insere novo registro no banco
- **Tratamento de Erros**: Duplicate key, foreign key constraints

#### `deleteCaixa(String id)`
- **Função**: Remove caixa do banco
- **Query**: `DELETE FROM caixa WHERE id = ?`

**Métodos de Movimentação**:

#### `getMovimentacoesPorCaixa(String caixaId)`
- **Função**: Busca movimentações de um caixa
- **Query**: `SELECT * FROM caixa_movimentacao WHERE caixa_id = ? ORDER BY data DESC`
- **Retorno**: Lista de CaixaMovimentacaoModel

#### `addMovimentacao(CaixaMovimentacaoModel movimentacao)`
- **Função**: Adiciona nova movimentação
- **Query**: `INSERT INTO caixa_movimentacao (...) VALUES (...)`
- **Retorno**: Movimentação criada

#### `deleteMovimentacao(String id)`
- **Função**: Remove movimentação
- **Query**: `DELETE FROM caixa_movimentacao WHERE id = ?`

**Métodos Específicos**:

#### `registrarVenda(...)`
- **Função**: Registra venda no caixa
- **Validações**: Caixa existe e está aberto
- **Fluxo**: Cria movimentação do tipo 'venda'

#### `registrarEntrada(...)` / `registrarSaida(...)`
- **Função**: Registra entrada/saída de dinheiro
- **Fluxo**: Cria movimentação do tipo correspondente

**Métodos de Cálculo**:

#### `calcularSaldoAtual(String caixaId)`
- **Função**: Calcula saldo atual do caixa
- **Fórmula**: `saldoInicial + entradas + vendas - saídas`
- **Retorno**: Valor double

#### `calcularResumoCaixa(String caixaId)`
- **Função**: Calcula resumo financeiro
- **Retorno**: Map com totais de entradas, saídas e vendas

### 3.2 CaixaCalculoService (`caixa_calculo_service.dart`)

**Propósito**: Serviço especializado em cálculos complexos e otimizados do caixa.

**Características**:
- Cache interno para evitar consultas repetidas
- Consultas paralelas para máxima performance
- Cálculos detalhados por forma de pagamento

**Métodos Principais**:

#### `calcularSaldoDetalhado(String caixaId)`
- **Função**: Calcula saldo detalhado com cache
- **Otimizações**:
  - Cache interno por caixaId
  - Consultas paralelas (caixa, movimentações, vendas)
  - JOINs otimizados para buscar pagamentos
- **Retorno**: Map com dados completos:
  - Saldo inicial, atual e físico
  - Totais por tipo de movimentação
  - Resumo por forma de pagamento
  - Contadores e estatísticas

#### `limparCache(String caixaId)`
- **Função**: Remove cache de um caixa específico

#### `limparCacheCompleto()`
- **Função**: Limpa todo o cache

**Métodos Auxiliares**:

#### `_getCaixa(String caixaId)`
- **Função**: Busca dados do caixa
- **Query**: `SELECT * FROM caixa WHERE id = ?`

#### `_getMovimentacoes(String caixaId)`
- **Função**: Busca movimentações do caixa
- **Query**: `SELECT * FROM caixa_movimentacao WHERE caixa_id = ? ORDER BY data DESC`

#### `_getVendasComPagamentos(String caixaId)`
- **Função**: Busca vendas com pagamentos em uma única query
- **Query**: JOIN complexo entre caixa_movimentacao, vendas, pagamentos_venda, formas_pagamento e itens_venda
- **Otimização**: Query única com múltiplos JOINs

### 3.3 CaixaVendasService (`caixa_vendas_service.dart`)

**Propósito**: Serviço especializado em operações relacionadas a vendas do caixa.

**Métodos Principais**:

#### `getVendasPorCaixa(String caixaId)`
- **Função**: Busca todas as vendas de um caixa
- **Fluxo**:
  1. Busca movimentações de venda do caixa
  2. Extrai IDs das vendas
  3. Busca detalhes das vendas
- **Retorno**: Lista de VendaModel

#### `getPagamentosVendasPorCaixa(String caixaId)`
- **Função**: Busca pagamentos de todas as vendas do caixa
- **Fluxo**:
  1. Busca vendas do caixa
  2. Para cada venda, busca seus pagamentos
  3. Agrupa por venda
- **Retorno**: Map<String, List<PagamentoVendaModel>>

#### `getResumoPagamentosPorForma(String caixaId)`
- **Função**: Calcula resumo de pagamentos por forma de pagamento
- **Fluxo**:
  1. Busca pagamentos das vendas
  2. Agrupa por forma de pagamento
  3. Soma valores
- **Retorno**: Map<String, double> (forma_pagamento_id -> valor_total)

## 4. Providers (Provedores de Estado)

### 4.1 CaixaVendasProvider (`caixa_vendas_provider.dart`)

**Propósito**: Provedores Riverpod para dados de vendas do caixa.

**Providers**:

#### `caixaVendasServiceProvider`
- **Tipo**: Provider<CaixaVendasService>
- **Função**: Instância do serviço de vendas

#### `vendasPorCaixaProvider`
- **Tipo**: FutureProvider.family<List<VendaModel>, String>
- **Função**: Lista de vendas de um caixa específico
- **Parâmetro**: caixaId

#### `pagamentosVendasPorCaixaProvider`
- **Tipo**: FutureProvider.family<Map<String, List<PagamentoVendaModel>>, String>
- **Função**: Pagamentos agrupados por venda
- **Parâmetro**: caixaId

#### `resumoPagamentosPorFormaProvider`
- **Tipo**: FutureProvider.family<Map<String, double>, String>
- **Função**: Resumo de pagamentos por forma
- **Parâmetro**: caixaId

## 5. Views (Interface do Usuário)

### 5.1 CaixaView (`caixa_view.dart`)

**Propósito**: Tela principal de gerenciamento do caixa.

**Funcionalidades**:
- Visualização do caixa ativo
- Abertura de novo caixa
- Navegação para movimentações e histórico
- Exibição de informações da loja ativa

**Métodos Principais**:

#### `_carregarCaixaAtivo()`
- **Função**: Carrega caixa aberto da loja ativa
- **Fluxo**: Busca via controller e atualiza estado

#### `_abrirCaixa()`
- **Função**: Abre novo caixa
- **Validações**:
  - Verifica se loja está selecionada
  - Verifica se usuário está autenticado
- **Fluxo**:
  1. Solicita saldo inicial via dialog
  2. Chama controller para abrir caixa
  3. Recarrega dados
  4. Exibe feedback

#### `_solicitarSaldoInicial()`
- **Função**: Dialog para inserir saldo inicial
- **Validações**: Valor não negativo
- **Retorno**: double ou null

### 5.2 CaixaMovimentacoesView (`caixa_movimentacoes_view.dart`)

**Propósito**: Tela de gerenciamento de movimentações do caixa.

**Funcionalidades**:
- Visualização de movimentações
- Registro de entradas e saídas
- Exibição de saldo atual
- Resumo financeiro
- Filtros e busca

**Métodos Principais**:

#### `_recarregarDadosTela()`
- **Função**: Recarrega todos os dados após alterações
- **Fluxo**:
  1. Invalida providers relacionados
  2. Recarrega dados do caixa
  3. Atualiza interface

#### `_registrarEntrada()` / `_registrarSaida()`
- **Função**: Registra entrada/saída de dinheiro
- **Fluxo**:
  1. Valida caixa aberto
  2. Valida usuário autenticado
  3. Mostra dialog para dados
  4. Registra via controller
  5. Recarrega dados

#### `_mostrarDialogMovimentacao()`
- **Função**: Dialog para inserir dados da movimentação
- **Campos**: Valor e descrição
- **Validações**: Valor positivo

### 5.3 CaixaHistoricoView (`caixa_historico_view.dart`)

**Propósito**: Tela de histórico de caixas.

**Funcionalidades**:
- Lista de caixas históricos
- Filtros por status e período
- Visualização de detalhes
- Navegação para movimentações

**Métodos Principais**:

#### `_carregarCaixas()`
- **Função**: Carrega caixas da loja ativa
- **Fluxo**: Chama controller e atualiza estado

#### `_filtrarCaixas(List<CaixaModel> caixas)`
- **Função**: Aplica filtros na lista
- **Filtros**:
  - Por status (aberto/fechado)
  - Por período (hoje/semana/mês)

#### `_getStatusColor()` / `_getStatusIcon()`
- **Função**: Retorna cor e ícone baseado no status
- **Mapeamento**: Verde para aberto, cinza para fechado

## 6. Fluxo de Operações

### 6.1 Abertura de Caixa

1. **Validação**: Verifica se loja está selecionada e usuário autenticado
2. **Dialog**: Solicita saldo inicial
3. **Controller**: Chama `abrirCaixa()` com validações
4. **Service**: Valida dados e insere no banco
5. **Feedback**: Exibe sucesso/erro
6. **Atualização**: Recarrega dados da tela

### 6.2 Registro de Movimentação

1. **Validação**: Verifica caixa aberto e usuário autenticado
2. **Dialog**: Solicita valor e descrição
3. **Controller**: Chama método específico (entrada/saída)
4. **Service**: Cria movimentação no banco
5. **Atualização**: Invalida providers e recarrega dados

### 6.3 Registro de Venda

1. **Integração**: Venda é registrada no módulo de vendas
2. **Callback**: Sistema chama `registrarVenda()` no caixa
3. **Service**: Cria movimentação do tipo 'venda'
4. **Atualização**: Saldo é recalculado automaticamente

### 6.4 Cálculo de Saldo

1. **Cache**: Verifica cache primeiro
2. **Paralelo**: Executa consultas em paralelo
3. **Cálculo**: Aplica fórmula: `saldoInicial + entradas + vendas - saídas`
4. **Cache**: Armazena resultado
5. **Retorno**: Dados completos do caixa

## 7. Considerações Técnicas

### 7.1 Performance
- Cache interno no CaixaCalculoService
- Consultas paralelas para dados relacionados
- JOINs otimizados para reduzir queries
- Invalidação seletiva de providers

### 7.2 Segurança
- Validação de usuário autenticado
- Verificação de permissões
- Validação de dados de entrada
- Tratamento de erros robusto

### 7.3 Integração
- Integração com módulo de vendas
- Integração com módulo de usuários
- Integração com módulo de lojas
- Integração com módulo de formas de pagamento

### 7.4 Estado
- Gerenciamento via Riverpod
- Providers familiares para dados específicos
- Invalidação automática após operações
- Estado assíncrono para operações de banco

## 8. Banco de Dados

### 8.1 Tabela `caixa`
```sql
CREATE TABLE caixa (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loja_id UUID REFERENCES lojas(id),
  usuario_abertura_id UUID REFERENCES usuarios(id),
  usuario_fechamento_id UUID REFERENCES usuarios(id),
  data_abertura TIMESTAMP NOT NULL,
  data_fechamento TIMESTAMP,
  saldo_inicial DECIMAL(10,2) NOT NULL,
  saldo_final DECIMAL(10,2),
  status VARCHAR(20) NOT NULL DEFAULT 'aberto',
  criado_em TIMESTAMP DEFAULT NOW(),
  criado_por UUID REFERENCES usuarios(id),
  atualizado_em TIMESTAMP,
  atualizado_por UUID REFERENCES usuarios(id)
);
```

### 8.2 Tabela `caixa_movimentacao`
```sql
CREATE TABLE caixa_movimentacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caixa_id UUID REFERENCES caixa(id),
  tipo VARCHAR(20) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  usuario_id UUID REFERENCES usuarios(id),
  data TIMESTAMP NOT NULL,
  descricao TEXT,
  venda_id UUID REFERENCES vendas(id),
  criado_em TIMESTAMP DEFAULT NOW(),
  criado_por UUID REFERENCES usuarios(id),
  atualizado_em TIMESTAMP,
  atualizado_por UUID REFERENCES usuarios(id)
);
```

## 9. Conclusão

O módulo Caixa é uma solução completa e robusta para gerenciamento de fluxo de caixa, oferecendo:

- **Controle Total**: Abertura, fechamento e movimentações
- **Integração Completa**: Com vendas, usuários e lojas
- **Performance Otimizada**: Cache e consultas paralelas
- **Interface Intuitiva**: Telas organizadas e responsivas
- **Segurança**: Validações e controle de acesso
- **Escalabilidade**: Arquitetura modular e extensível

O sistema garante rastreabilidade completa de todas as operações financeiras, fornecendo relatórios detalhados e controles necessários para gestão eficiente do caixa.
