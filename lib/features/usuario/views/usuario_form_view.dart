import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/usuario_controller.dart';
import '../models/usuario_model.dart';
import '../../cargo/controllers/cargo_controller.dart';
import '../../cargo/models/cargo_model.dart';

class UsuarioFormView extends ConsumerStatefulWidget {
  final UsuarioModel? usuario;
  const UsuarioFormView({super.key, this.usuario});

  @override
  ConsumerState<UsuarioFormView> createState() => _UsuarioFormViewState();
}

class _UsuarioFormViewState extends ConsumerState<UsuarioFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  late final TextEditingController emailController;
  bool ativo = true;
  String? cargoId;
  bool _loading = false;
  List<String> lojasSelecionadas = [];

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    emailController = TextEditingController(text: widget.usuario?.email ?? '');
    ativo = widget.usuario?.ativo ?? true;
    cargoId = widget.usuario?.cargoId;

    // Se estiver editando, carrega as lojas já selecionadas
    if (widget.usuario != null) {
      _carregarLojasDoUsuario();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _carregarLojasDoUsuario() async {
    if (widget.usuario != null) {
      try {
        final lojasDoUsuario = await ref.read(
          lojasDoUsuarioProvider(widget.usuario!.id).future,
        );
        setState(() {
          lojasSelecionadas = lojasDoUsuario
              .map((l) => l['loja_id'] as String)
              .toList();
        });
      } catch (e) {
        // Ignora erro se não conseguir carregar as lojas
        print('Erro ao carregar lojas do usuário: $e');
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Valida se um cargo foi selecionado
    if (cargoId == null || cargoId!.isEmpty) {
      AppFeedback.showError(context, 'Selecione um cargo');
      return;
    }

    // Valida se pelo menos uma loja foi selecionada
    if (lojasSelecionadas.isEmpty) {
      AppFeedback.showError(context, 'Selecione pelo menos uma loja');
      return;
    }
    print('lojasSelecionadas: $lojasSelecionadas');
    setState(() => _loading = true);
    try {
      final usuario = widget.usuario == null
          ? UsuarioModel.novo(
              nome: nomeController.text.trim(),
              email: emailController.text.trim(),
              ativo: ativo,
              cargoId: cargoId,
              lojasIds: lojasSelecionadas,
            )
          : UsuarioModel(
              id: widget.usuario!.id,
              nome: nomeController.text.trim(),
              email: emailController.text.trim(),
              ativo: ativo,
              cargoId: cargoId,
              userId: widget.usuario!.userId,
              lojasIds: lojasSelecionadas,
              criadoEm: widget.usuario!.criadoEm,
            );
      print('usuario: $usuario');
      if (widget.usuario == null) {
        final senhaTemporaria = await ref
            .read(usuarioProvider.notifier)
            .addUsuario(usuario);
        print('senhaTemporaria: $senhaTemporaria');
        if (senhaTemporaria != null) {
          print('senhaTemporaria: $senhaTemporaria');
          await _mostrarDialogoSucesso(usuario, senhaTemporaria);
        }
      } else {
        await ref.read(usuarioProvider.notifier).updateUsuario(usuario);
        AppFeedback.showSuccess(context, 'Usuário atualizado com sucesso!');
      }
      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, 'Erro ao salvar usuário: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _mostrarDialogoSucesso(
    UsuarioModel usuario,
    String senhaTemporaria,
  ) async {
    final nomeUsuario = usuario.nome;
    final nomeEmpresa = 'Nome da Empresa';
    final dataAtual = DateTime.now();
    final email = usuario.email;

    final isSmallScreen = MediaQuery.of(context).size.height < 600;
    final mensagem = _gerarMensagemBoasVindas(
      nomeUsuario,
      nomeEmpresa,
      dataAtual,
      email,
      senhaTemporaria,
      isSmallScreen,
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Text('Usuário criado com sucesso!'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: isSmallScreen
              ? MediaQuery.of(context).size.height * 0.5
              : MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mensagem de boas-vindas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      mensagem,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: mensagem));
              AppFeedback.showSuccess(context, 'Mensagem copiada!');
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _gerarMensagemBoasVindas(
    String nomeUsuario,
    String nomeEmpresa,
    DateTime dataAtual,
    String email,
    String senhaTemporaria,
    bool isSmallScreen,
  ) {
    if (isSmallScreen) {
      return '''👋 Olá${nomeUsuario.isNotEmpty ? ' $nomeUsuario' : ''}!

Você foi adicionado ao sistema de Gestão de Estoque da empresa "$nomeEmpresa" no dia ${dataAtual.day.toString().padLeft(2, '0')}/${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}.

🔐 **Sua senha temporária:** $senhaTemporaria

⚠️ **Atenção:**
• Senha provisória para primeiro acesso
• Crie uma nova senha ao entrar no sistema
• Escolha uma senha segura (8+ caracteres)
• Não compartilhe a senha

🚀 **Como acessar:**
1. Abra o aplicativo
2. Email: $email
3. Senha: $senhaTemporaria
4. Siga as instruções para nova senha

❓ **Dúvidas?** Fale com o responsável ou suporte.

Bem-vindo(a) ao time! 💼''';
    } else {
      return '''\n👋 Olá${nomeUsuario.isNotEmpty ? ' $nomeUsuario' : ''}!\n\nVocê foi adicionado ao sistema de Gestão de Estoque da empresa **"$nomeEmpresa"** no dia ${dataAtual.day.toString().padLeft(2, '0')}/${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}. Estamos felizes em ter você com a gente!\n\n🔐 **Sua senha temporária:** $senhaTemporaria\n\n⚠️ Atenção:\n• Essa senha é provisória e válida para o primeiro acesso apenas  \n• Assim que entrar no sistema, você vai precisar criar uma nova senha  \n• Escolha uma senha segura (com pelo menos 8 caracteres, letras, números e símbolos)  \n• Não compartilhe essa senha com ninguém, beleza?\n\n🚀 **Como acessar:**\n1. Abra o aplicativo\n2. Digite seu e-mail: $email\n3. Use a senha temporária acima\n4. Siga as instruções para definir sua nova senha\n\n❓ Está com dúvidas?\n• Verifique se o e-mail e a senha estão corretos  \n• Caso algo não funcione, fale com o responsável pela empresa ou com o nosso suporte  \n• Estamos aqui pra ajudar no que precisar!\n\nBem-vindo(a) ao time! 💼\n\nAbraços!''';
    }
  }

  Widget _buildInformacoesBasicas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações Básicas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nome Completo *',
          controller: nomeController,
          validator: (v) => v == null || v.isEmpty ? 'Nome obrigatório' : null,
          enabled: !_loading,
          prefixIcon: const Icon(Icons.person),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Email *',
          controller: emailController,
          validator: (v) => v == null || v.isEmpty
              ? 'Email obrigatório'
              : !v.contains('@')
              ? 'Email inválido'
              : null,
          enabled: !_loading,
          prefixIcon: const Icon(Icons.email),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Checkbox(
                value: ativo,
                onChanged: _loading
                    ? null
                    : (v) => setState(() => ativo = v ?? true),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuário Ativo',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Usuários inativos não podem acessar o sistema',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelecaoCargo() {
    final cargosAsync = ref.watch(cargoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cargo e Permissões',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        cargosAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Erro ao carregar cargos'),
              ],
            ),
          ),
          data: (cargos) => DropdownButtonFormField<String>(
            value: cargoId?.isNotEmpty == true ? cargoId : null,
            decoration: const InputDecoration(
              labelText: 'Cargo *',
              prefixIcon: Icon(Icons.work),
              border: OutlineInputBorder(),
            ),
            items: cargos
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.nome),
                  ),
                )
                .toList(),
            onChanged: _loading ? null : (v) => setState(() => cargoId = v),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecione um cargo';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelecaoLojas() {
    final lojasAsync = ref.watch(lojasDisponiveisProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lojas de Acesso',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione as lojas que o usuário poderá acessar:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        lojasAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Erro ao carregar lojas'),
              ],
            ),
          ),
          data: (lojas) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botões de ação rápida
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_box, size: 16),
                      label: const Text('Marcar todas'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                lojasSelecionadas = lojas
                                    .map((l) => l['id'] as String)
                                    .toList();
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_box_outline_blank, size: 16),
                      label: const Text('Desmarcar todas'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                lojasSelecionadas.clear();
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contador de lojas selecionadas
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${lojasSelecionadas.length} de ${lojas.length} lojas selecionadas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Lista de lojas
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: lojas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma loja disponível',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: lojas.map((loja) {
                            final lojaId = loja['id'] as String;
                            final nome = loja['nome'] as String;
                            final shopping = loja['shopping'] as String;
                            final andar = loja['andar'] as String;
                            final numero = loja['numero'] as String;

                            return CheckboxListTile(
                              title: Text(
                                nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '$shopping - $andarº andar - Loja $numero',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: lojasSelecionadas.contains(lojaId),
                              onChanged: _loading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          lojasSelecionadas.add(lojaId);
                                        } else {
                                          lojasSelecionadas.remove(lojaId);
                                        }
                                      });
                                    },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              dense: true,
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Icon(
                      widget.usuario == null ? Icons.person_add : Icons.edit,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.usuario == null
                          ? 'Novo Usuário'
                          : 'Editar Usuário',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Conteúdo do formulário
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInformacoesBasicas(),
                        const SizedBox(height: 24),
                        _buildSelecaoCargo(),
                        const SizedBox(height: 24),
                        _buildSelecaoLojas(),
                      ],
                    ),
                  ),
                ),

                // Botões de ação
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _salvar,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 16),
                      label: Text(_loading ? 'Salvando...' : 'Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
