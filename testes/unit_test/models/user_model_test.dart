// Testes Unitários — UserModel
//
// Cobre:
//   - toMap() / fromMap() (serialização e desserialização)
//   - Valores padrão (isActive = true)
//   - copyWith()
//   - Igualdade via Equatable (props)
//   - Enum UserType (passageiro / barqueiro)
//
// Para executar:
//   flutter test testes/unit_test/models/user_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/user_model.dart';

void main() {
  final user = UserModel(
    uid: 'uid-001',
    email: 'joao@example.com',
    fullName: 'João Silva',
    cpf: '12345678909',
    userType: UserType.passageiro,
    createdAt: 1700000000000,
  );

  group('UserModel.toMap', () {
    test('Serializa todos os campos corretamente', () {
      final map = user.toMap();

      expect(map['uid'], 'uid-001');
      expect(map['email'], 'joao@example.com');
      expect(map['fullName'], 'João Silva');
      expect(map['cpf'], '12345678909');
      expect(map['userType'], 'passageiro');
      expect(map['createdAt'], 1700000000000);
      expect(map['isActive'], isTrue);
    });

    test('Serializa userType barqueiro como "barqueiro"', () {
      final barqueiro = user.copyWith(userType: UserType.barqueiro);
      expect(barqueiro.toMap()['userType'], 'barqueiro');
    });
  });

  group('UserModel.fromMap', () {
    test('Desserializa todos os campos corretamente', () {
      final restored = UserModel.fromMap(user.toMap());

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.fullName, user.fullName);
      expect(restored.cpf, user.cpf);
      expect(restored.userType, user.userType);
      expect(restored.createdAt, user.createdAt);
      expect(restored.isActive, user.isActive);
    });

    test('Usa valores padrão quando campos estão ausentes no mapa', () {
      final restored = UserModel.fromMap({});

      expect(restored.uid, isEmpty);
      expect(restored.email, isEmpty);
      expect(restored.userType, UserType.passageiro);
      expect(restored.isActive, isTrue);
    });

    test('Interpreta userType desconhecido como passageiro', () {
      final restored = UserModel.fromMap({'userType': 'desconhecido'});
      expect(restored.userType, UserType.passageiro);
    });
  });

  group('UserModel round-trip (toMap → fromMap)', () {
    test('Mantém igualdade após serialização e desserialização', () {
      expect(UserModel.fromMap(user.toMap()), equals(user));
    });
  });

  group('UserModel.copyWith', () {
    test('Cria nova instância com campo alterado', () {
      final updated = user.copyWith(fullName: 'Maria Souza');
      expect(updated.fullName, 'Maria Souza');
      expect(updated.uid, user.uid);
    });

    test('Instância original não é modificada', () {
      user.copyWith(email: 'outro@example.com');
      expect(user.email, 'joao@example.com');
    });

    test('isActive pode ser alterado para false', () {
      final inactive = user.copyWith(isActive: false);
      expect(inactive.isActive, isFalse);
    });
  });

  group('UserModel Equatable', () {
    test('Dois modelos com mesmos dados são iguais', () {
      final user2 = UserModel(
        uid: 'uid-001',
        email: 'joao@example.com',
        fullName: 'João Silva',
        cpf: '12345678909',
        userType: UserType.passageiro,
        createdAt: 1700000000000,
      );
      expect(user, equals(user2));
    });

    test('Modelos com uid diferente não são iguais', () {
      expect(user, isNot(equals(user.copyWith(uid: 'uid-002'))));
    });
  });
}
