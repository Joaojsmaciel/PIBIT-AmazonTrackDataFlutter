import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/user_model.dart';

import 'service_provider.dart';

final authStateProvider = StreamProvider<bool>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentUser();
});

// Cache em memória do usuário logado.
// Populado após login bem-sucedido e ao carregar a MapScreen.
// Não depende do Firestore estar disponível.
final userSessionProvider = StateProvider<UserModel?>((ref) => null);

final currentUserIdProvider = Provider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUserId();
});

final signUpProvider = FutureProvider.family<void, ({
  String email,
  String password,
  String fullName,
  String cpf,
  UserType userType,
})>((ref, params) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.signUp(
    email: params.email,
    password: params.password,
    fullName: params.fullName,
    cpf: params.cpf,
    userType: params.userType,
  );
});

final signInProvider = FutureProvider.family<UserModel?, ({
  String email,
  String password,
})>((ref, params) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.signIn(
    email: params.email,
    password: params.password,
  );
});

final signOutProvider = FutureProvider<void>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.signOut();
});

final signInWithGoogleProvider = FutureProvider<UserModel?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.signInWithGoogle();
});
