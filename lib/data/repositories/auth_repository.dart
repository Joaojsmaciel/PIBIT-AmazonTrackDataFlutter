import 'package:flutter/foundation.dart';
import 'package:amazon_track_data/data/datasources/firebase_auth_datasource.dart';
import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuthDatasource _authDatasource;
  final FirestoreDatasource _firestoreDatasource;

  AuthRepository({
    required FirebaseAuthDatasource authDatasource,
    required FirestoreDatasource firestoreDatasource,
  })  : _authDatasource = authDatasource,
        _firestoreDatasource = firestoreDatasource;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required UserType userType,
  }) async {
    final userCredential = await _authDatasource.signUpWithEmail(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      fullName: fullName,
      cpf: cpf,
      userType: userType,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint('[signUp] Auth user criado: ${user.uid}');
    debugPrint('[signUp] Salvando no Firestore: ${user.toMap()}');

    // Retry com backoff progressivo — o Firestore pode estar transitoriamente
    // indisponível logo após a criação do usuário no Firebase Auth.
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        debugPrint('[signUp] Tentativa ${attempt + 1}/3 após falha: $lastError');
        await Future.delayed(Duration(seconds: attempt));
      }
      try {
        await _firestoreDatasource.createUser(user);
        debugPrint('[signUp] Usuário salvo no Firestore com sucesso!');
        return;
      } catch (e) {
        lastError = e;
        debugPrint('[signUp] Erro na tentativa ${attempt + 1}: $e');
      }
    }
    debugPrint('[signUp] Falha após 3 tentativas: $lastError');
    throw lastError!;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authDatasource.signInWithEmail(
        email: email,
        password: password,
      );
      // Usa o mesmo retry robusto de getCurrentUser
      return await getCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authDatasource.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authDatasource.currentUser;
    if (firebaseUser == null) return null;

    // Tenta até 4 vezes com backoff progressivo (0s, 1s, 2s, 3s).
    // Necessário porque logo após o cadastro o documento pode ainda não ter
    // propagado no Firestore (race condition).
    Object? lastError;
    for (int attempt = 0; attempt < 4; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(seconds: attempt));
      try {
        final user = await _firestoreDatasource.getUser(firebaseUser.uid);
        if (user != null) return user;
        // Documento não encontrado — aguarda próxima tentativa
      } catch (e) {
        lastError = e;
        // Erro transitório — tenta novamente
      }
    }

    if (lastError != null) throw lastError;
    return null;
  }

  Stream<bool> get authStateChanges {
    return _authDatasource.authStateChanges.map((user) => user != null);
  }

  String? getCurrentUserId() {
    return _authDatasource.getCurrentUserId();
  }

  Future<UserModel?> signInWithGoogle({UserType userType = UserType.passageiro}) async {
    try {
      final userCredential = await _authDatasource.signInWithGoogle();
      final uid = userCredential.user!.uid;

      UserModel? user = await _firestoreDatasource.getUser(uid);
      if (user == null) {
        final firebaseUser = userCredential.user!;
        final newUser = UserModel(
          uid: uid,
          email: firebaseUser.email ?? '',
          fullName: firebaseUser.displayName ?? '',
          cpf: '',
          userType: userType,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _firestoreDatasource.createUser(newUser);
        user = newUser;
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }
}
