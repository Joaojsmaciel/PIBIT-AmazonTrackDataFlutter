import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';
import 'package:amazon_track_data/core/validators/validators.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usa o cache em memória primeiro; se estiver vazio, ouve o FutureProvider
    final cachedUser = ref.watch(userSessionProvider);
    final userAsync = cachedUser != null
        ? AsyncValue.data(cachedUser)
        : ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Usuário não encontrado'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(currentUserProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?'),
                  ),
                ),
                const SizedBox(height: 24),
                // Informações do usuário
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nome Completo',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          user.fullName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'CPF',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          user.cpf.length == 11
                              ? Validators.formatCPF(user.cpf)
                              : user.cpf.isEmpty ? 'Não informado' : user.cpf,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tipo de Usuário',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          user.userType.toString().split('.').last,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Botão de logout
                ElevatedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Desconectar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro: $error'),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desconectar'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(signOutProvider.future);
                // Limpa o cache do usuário para que o próximo login não
                // mostre dados do usuário anterior.
                ref.read(userSessionProvider.notifier).state = null;
                ref.invalidate(currentUserProvider);
                
                await Future.delayed(const Duration(milliseconds: 500));
                
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Erro ao desconectar: $e');
                }
              }
            },
            child: const Text('Desconectar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
