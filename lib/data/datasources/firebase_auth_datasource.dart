import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:amazon_track_data/core/errors/failures.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure(
        message: e.message ?? 'Erro ao criar conta',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseAuthFailure(
        message: 'Erro desconhecido ao criar conta',
      );
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'channel-error') {
        throw FirebaseAuthFailure(
          message: 'Falha de comunicação com o Firebase. Verifique sua conexão e tente novamente.',
          code: e.code,
        );
      }
      throw FirebaseAuthFailure(
        message: e.message ?? 'Erro ao entrar',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseAuthFailure(
        message: 'Erro desconhecido ao entrar: verifique sua conexão.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure(
        message: e.message ?? 'Erro ao sair',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseAuthFailure(
        message: 'Erro desconhecido ao sair',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure(
        message: e.message ?? 'Erro ao resetar senha',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseAuthFailure(
        message: 'Erro desconhecido ao resetar senha',
      );
    }
  }

  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthFailure(message: 'Login com Google cancelado');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure(
        message: e.message ?? 'Erro ao entrar com Google',
        code: e.code,
      );
    } on FirebaseAuthFailure {
      rethrow;
    } catch (e) {
      throw FirebaseAuthFailure(
        message: 'Erro ao entrar com Google: $e',
      );
    }
  }
}
