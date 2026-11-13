// Dublês em memória dos datasources Firebase.
//
// Implementam as interfaces públicas usadas pelos repositórios reais, de modo
// que AuthRepository e LocationRepository sejam exercitados sem rede.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/datasources/firebase_auth_datasource.dart';
import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/datasources/geolocator_datasource.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/models/user_model.dart';

class FakeUser implements User {
  FakeUser(this.uid, this.email);

  @override
  final String uid;

  @override
  final String? email;

  @override
  String? get displayName => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Firebase Auth em memória: e-mail único, senha conferida, sessão persistida.
class FakeAuthDatasource implements FirebaseAuthDatasource {
  final Map<String, ({String password, String uid})> _accounts = {};
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();
  User? _current;
  int _seq = 0;

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges => _authController.stream;

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw FirebaseAuthFailure(
        message: 'The email address is already in use by another account.',
        code: 'email-already-in-use',
      );
    }
    final uid = 'uid-${++_seq}';
    _accounts[email] = (password: password, uid: uid);
    _current = FakeUser(uid, email);
    _authController.add(_current);
    return FakeUserCredential(_current);
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw FirebaseAuthFailure(
        message: 'Credenciais inválidas',
        code: 'invalid-credential',
      );
    }
    _current = FakeUser(account.uid, email);
    _authController.add(_current);
    return FakeUserCredential(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _authController.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    final atual = _current;
    if (atual == null) return;
    _accounts.removeWhere((_, conta) => conta.uid == atual.uid);
    _current = null;
    _authController.add(null);
  }

  @override
  String? getCurrentUserId() => _current?.uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Firestore em memória com injeção de falhas.
class FakeFirestoreDatasource implements FirestoreDatasource {
  final Map<String, UserModel> users = {};
  final Map<String, List<LocationModel>> tracks = {};
  final Map<String, Map<String, Map<String, dynamic>>> tripMeta = {};
  final List<LocationModel> livePositions = [];

  /// Quando verdadeiro, toda operação lança FirestoreFailure (sem internet).
  bool offline = false;

  /// Timestamps cuja gravação deve falhar (falha parcial de lote).
  final Set<int> failingTimestamps = {};

  bool failTripMeta = false;

  void _checkOnline() {
    if (offline) {
      throw FirestoreFailure(message: 'unavailable', code: 'unavailable');
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    _checkOnline();
    users[user.uid] = user;
  }

  /// Índice cpfs/{cpf} → uid (mesma semântica da transação real).
  final Map<String, String> cpfIndex = {};

  @override
  Future<void> createUserWithUniqueCpf(UserModel user) async {
    _checkOnline();
    final cpf = user.cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.isNotEmpty) {
      final dono = cpfIndex[cpf];
      if (dono != null && dono != user.uid) {
        throw ValidationFailure(
          message: 'Este CPF já está cadastrado em outra conta.',
          code: 'cpf-already-in-use',
        );
      }
      cpfIndex[cpf] = user.uid;
    }
    users[user.uid] = user;
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    _checkOnline();
    return users[uid];
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    _checkOnline();
    if (failingTimestamps.contains(location.timestamp)) {
      throw FirestoreFailure(message: 'write rejected', code: 'aborted');
    }
    tracks.putIfAbsent(location.userId, () => []).add(location);
  }

  @override
  Future<void> updateLivePosition(LocationModel location) async {
    _checkOnline();
    livePositions.add(location);
  }

  @override
  Future<List<LocationModel>> getAllUserLocations(String userId) async {
    _checkOnline();
    final list = [...?tracks[userId]]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getTripMetaForUser(
      String userId) async {
    _checkOnline();
    if (failTripMeta) {
      throw FirestoreFailure(message: 'Erro ao buscar metadados de viagens');
    }
    return tripMeta[userId] ?? {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGeolocatorDatasource implements GeolocatorDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
