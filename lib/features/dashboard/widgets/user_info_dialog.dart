import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/controllers/user_info_controller.dart';
import '../../../config/theme.dart';

class UserInfoDialog extends ConsumerWidget {
  const UserInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoState = ref.watch(userInfoProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.blueAccent,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text('Informações do Usuário'),
        ],
      ),
      content: userInfoState.when<Widget>(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('Erro ao carregar informações: $error'),
        data: (state) {
          final usuario = state.usuario;
          if (usuario == null) {
            return const Text('Usuário não encontrado');
          }

          final cargo = state.cargo;
          final lojas = state.lojas;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: AppColors.blueAccent,
                  ),
                  title: const Text('Nome'),
                  subtitle: Text(usuario.nome),
                ),
                ListTile(
                  leading: Icon(Icons.email, color: AppColors.blueAccent),
                  title: const Text('Email'),
                  subtitle: Text(usuario.email),
                ),
                ListTile(
                  leading: Icon(Icons.badge, color: AppColors.blueAccent),
                  title: const Text('Cargo'),
                  subtitle: Text(cargo?.nome ?? 'Não atribuído'),
                ),
                ListTile(
                  leading: Icon(Icons.store, color: AppColors.blueAccent),
                  title: const Text('Lojas'),
                  subtitle: Text(
                    lojas.isNotEmpty
                        ? 'Total: ${lojas.length} loja(s)'
                        : 'Nenhuma loja atribuída',
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: AppColors.blueAccent,
                  ),
                  title: const Text('Criado em'),
                  subtitle: Text(
                    usuario.criadoEm != null
                        ? '${usuario.criadoEm!.day}/${usuario.criadoEm!.month}/${usuario.criadoEm!.year}'
                        : 'Data não disponível',
                  ),
                ),
                ListTile(
                  leading: Icon(
                    usuario.ativo ? Icons.check_circle : Icons.cancel,
                    color: usuario.ativo ? Colors.green : Colors.red,
                  ),
                  title: const Text('Status'),
                  subtitle: Text(usuario.ativo ? 'Ativo' : 'Inativo'),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Fechar', style: TextStyle(color: AppColors.blueAccent)),
        ),
      ],
    );
  }
}
