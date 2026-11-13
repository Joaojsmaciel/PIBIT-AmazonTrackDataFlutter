// Casos CT-AUT-01..07 e CT-SEG-05 sobre o AuthRepository real, com Firebase
// Auth e Firestore em memória.

import 'package:flutter_test/flutter_test.dart';

import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/data/repositories/auth_repository.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthDatasource auth;
  late FakeFirestoreDatasource firestore;
  late AuthRepository repo;

  setUp(() {
    auth = FakeAuthDatasource();
    firestore = FakeFirestoreDatasource();
    repo = AuthRepository(authDatasource: auth, firestoreDatasource: firestore);
  });

  Future<void> cadastrar({
    String email = 'maria@teste.example',
    String cpf = '52998224725',
    UserType tipo = UserType.passageiro,
  }) =>
      repo.signUp(
        email: email,
        password: 'senha123',
        fullName: 'Maria da Silva',
        cpf: cpf,
        userType: tipo,
      );

  test('CT-AUT-01 cadastro de passageiro cria credencial e perfil coerentes',
      () async {
    await cadastrar();
    final uid = repo.getCurrentUserId()!;
    final perfil = firestore.users[uid]!;
    expect(perfil.userType, UserType.passageiro);
    expect(perfil.isActive, isTrue);
    expect(perfil.cpf, '52998224725');
    expect(perfil.email, 'maria@teste.example');
  });

  test('CT-AUT-02 cadastro de barqueiro e login carregam perfil barqueiro',
      () async {
    await cadastrar(
        email: 'joao@teste.example',
        cpf: '11144477735',
        tipo: UserType.barqueiro);
    await repo.signOut();
    final u = await repo.signIn(
        email: 'joao@teste.example', password: 'senha123');
    expect(u!.userType, UserType.barqueiro);
  });

  group('CT-AUT-03 unicidade (UC-01)', () {
    test('CT-AUT-03 (b) CPF já cadastrado é recusado', () async {
      await cadastrar(email: 'primeiro@teste.example');
      await repo.signOut();
      await expectLater(
        cadastrar(email: 'segundo@teste.example'),
        throwsA(anything),
      );
      final comMesmoCpf =
          firestore.users.values.where((u) => u.cpf == '52998224725');
      expect(comMesmoCpf, hasLength(1));
    });

    test('CT-AUT-03 (d) CPF recusado não deixa credencial órfã: o e-mail '
        'pode ser reutilizado', () async {
      await cadastrar(email: 'primeiro@teste.example');
      await repo.signOut();
      await expectLater(
        cadastrar(email: 'segundo@teste.example'),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.getCurrentUserId(), isNull);
      await cadastrar(email: 'segundo@teste.example', cpf: '11144477735');
      expect(firestore.users.values.map((u) => u.email),
          contains('segundo@teste.example'));
    });

    test('CT-AUT-03 (c) e-mail repetido é recusado', () async {
      await cadastrar();
      await repo.signOut();
      await expectLater(
        cadastrar(cpf: '11144477735'),
        throwsA(isA<FirebaseAuthFailure>()),
      );
    });
  });

  test('CT-AUT-04 login válido carrega o perfil do UID corrente', () async {
    await cadastrar(tipo: UserType.barqueiro);
    final uid = repo.getCurrentUserId();
    await repo.signOut();
    final u = await repo.signIn(
        email: 'maria@teste.example', password: 'senha123');
    expect(u!.uid, uid);
    expect(repo.getCurrentUserId(), uid);
  });

  test('CT-AUT-05 senha errada não concede acesso', () async {
    await cadastrar();
    await repo.signOut();
    await expectLater(
      repo.signIn(email: 'maria@teste.example', password: 'errada1'),
      throwsA(isA<FirebaseAuthFailure>()),
    );
    expect(repo.getCurrentUserId(), isNull);
  });

  test('CT-AUT-06 logout encerra a sessão', () async {
    await cadastrar();
    await repo.signOut();
    expect(repo.getCurrentUserId(), isNull);
    expect(await repo.getCurrentUser(), isNull);
  });

  test('CT-AUT-07 sessão persistida é recuperada ao reabrir o app', () async {
    await cadastrar(tipo: UserType.barqueiro);
    final reaberto =
        AuthRepository(authDatasource: auth, firestoreDatasource: firestore);
    final u = await reaberto.getCurrentUser();
    expect(u!.userType, UserType.barqueiro);
  });

  test('CT-SEG-05 conta inativa não inicia sessão', () async {
    await cadastrar();
    final uid = repo.getCurrentUserId()!;
    firestore.users[uid] = firestore.users[uid]!.copyWith(isActive: false);
    await repo.signOut();
    UserModel? u;
    Object? erro;
    try {
      u = await repo.signIn(
          email: 'maria@teste.example', password: 'senha123');
    } catch (e) {
      erro = e;
    }
    expect(erro != null || u == null, isTrue,
        reason: 'perfil inativo retornado: ${u?.toMap()}');
  });

  test('CT-SEG-05 (b) sessão restaurada de conta inativa é encerrada',
      () async {
    await cadastrar();
    final uid = repo.getCurrentUserId()!;
    firestore.users[uid] = firestore.users[uid]!.copyWith(isActive: false);
    await expectLater(
      repo.getCurrentUser(),
      throwsA(isA<FirebaseAuthFailure>()
          .having((f) => f.code, 'code', 'user-disabled')),
    );
    expect(repo.getCurrentUserId(), isNull);
  });
}
