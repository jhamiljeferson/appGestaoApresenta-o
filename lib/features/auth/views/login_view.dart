import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../controllers/auth_controller.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'jefersonjhamil25@gmail.com',
  );
  final _passwordController = TextEditingController(text: '20Jha@mil03');

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final width = MediaQuery.of(context).size.width;
    final iconSize = width < 400
        ? 20.0
        : width < 700
        ? 24.0
        : 28.0;
    final fontSize = width < 400
        ? 14.0
        : width < 700
        ? 16.0
        : 18.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 340),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: iconSize,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Acessar ERP',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'E-mail',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Informe o e-mail'
                              : null,
                        ),
                        AppTextField(
                          label: 'Senha',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Informe a senha' : null,
                        ),
                        const SizedBox(height: 16),
                        _loading
                            ? const AppLoading()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _loading = true);
                                      try {
                                        await ref
                                            .read(authProvider.notifier)
                                            .login(
                                              _emailController.text.trim(),
                                              _passwordController.text,
                                            );
                                        // Navegação será feita pelo GoRouter após login
                                      } catch (e) {
                                        AppFeedback.showError(
                                          context,
                                          'Erro ao fazer login',
                                        );
                                      } finally {
                                        setState(() => _loading = false);
                                      }
                                    }
                                  },
                                  child: const Text('Entrar'),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
