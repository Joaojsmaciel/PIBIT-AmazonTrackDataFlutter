import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amazon_track_data/core/validators/validators.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/presentation/providers/service_provider.dart';

final _obscurePasswordProvider = StateProvider<bool>((ref) => true);
final _obscureConfirmPasswordProvider = StateProvider<bool>((ref) => true);

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController passwordConfirmController;
  late final TextEditingController nameController;
  late final TextEditingController cpfController;
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  UserType? _selectedUserType;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    passwordConfirmController = TextEditingController();
    nameController = TextEditingController();
    cpfController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nameController.dispose();
    cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!formKey.currentState!.validate()) return;

    if (_selectedUserType == null) {
      context.showErrorSnackBar('Selecione um tipo de usuário');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // CPF: envia apenas os dígitos limpos
      final cleanCpf = cpfController.text.replaceAll(RegExp(r'\D'), '');
      // Chama o repositório diretamente para evitar o cache do FutureProvider.
      await ref.read(authRepositoryProvider).signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
        cpf: cleanCpf,
        userType: _selectedUserType!,
      );
      
      if (mounted) {
        context.showSuccessSnackBar('Cadastro realizado com sucesso!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nome Completo',
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cpfController,
                decoration: const InputDecoration(
                  hintText: 'CPF',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: Validators.validateCPF,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      ref.watch(_obscurePasswordProvider)
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      ref.read(_obscurePasswordProvider.notifier).state =
                          !ref.read(_obscurePasswordProvider);
                    },
                  ),
                ),
                obscureText: ref.watch(_obscurePasswordProvider),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordConfirmController,
                decoration: InputDecoration(
                  hintText: 'Confirmar Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      ref.watch(_obscureConfirmPasswordProvider)
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      ref.read(_obscureConfirmPasswordProvider.notifier).state =
                          !ref.read(_obscureConfirmPasswordProvider);
                    },
                  ),
                ),
                obscureText: ref.watch(_obscureConfirmPasswordProvider),
                validator: (value) => Validators.validatePasswordConfirmation(
                  value,
                  passwordController.text,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserType>(
                value: _selectedUserType,
                decoration: const InputDecoration(
                  hintText: 'Tipo de Usuário',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: UserType.values.map((type) {
                  String label = '';
                  switch (type) {
                    case UserType.passageiro:
                      label = 'Passageiro';
                      break;
                    case UserType.mototaxi:
                      label = 'Mototáxi';
                      break;
                    case UserType.barqueiro:
                      label = 'Barqueiro';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUserType = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione um tipo de usuário';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cadastrar'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Já tem conta? Faça login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
