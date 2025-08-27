# ERP Multi-Lojas

## Estrutura do Projeto

- `lib/features/`: Funcionalidades separadas por domínio (ex: auth, dashboard)
- `lib/core/`: Serviços e utilitários compartilhados
- `lib/config/`: Temas, rotas e variáveis de ambiente
- `lib/shared/`: Componentes reutilizáveis

## Boas Práticas

- Gerenciamento de estado com Riverpod
- Rotas centralizadas com go_router
- Temas centralizados
- Testes unitários e de widget recomendados
- Tratamento de erros e logs nos serviços

## Como rodar

1. Configure o arquivo `.env` com as variáveis do Supabase
2. Execute `flutter pub get`
3. Execute `flutter run`
