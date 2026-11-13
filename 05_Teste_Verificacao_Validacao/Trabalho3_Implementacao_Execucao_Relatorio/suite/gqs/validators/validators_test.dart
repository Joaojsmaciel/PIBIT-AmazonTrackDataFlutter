// Testes Unitários — Validators
//
// Cobre todos os métodos estáticos da classe Validators:
//   - isValidCPF / validateCPF / formatCPF
//   - validateEmail
//   - validatePassword / validatePasswordConfirmation
//   - validateName
//   - validateNotEmpty
//   - validateNumber
//
// Para executar:
//   flutter test testes/unit_test/validators/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/core/validators/validators.dart';

void main() {
  // ──────────────────────────────────────────────────────────────
  // CPF
  // ──────────────────────────────────────────────────────────────
  group('isValidCPF', () {
    test('CPF válido retorna true', () {
      expect(Validators.isValidCPF('12345678909'), isTrue);
    });

    test('CPF com todos os dígitos iguais retorna false', () {
      expect(Validators.isValidCPF('11111111111'), isFalse);
      expect(Validators.isValidCPF('00000000000'), isFalse);
    });

    test('CPF com comprimento diferente de 11 dígitos retorna false', () {
      expect(Validators.isValidCPF('123456789'), isFalse);
      expect(Validators.isValidCPF('123456789012'), isFalse);
    });

    test('CPF vazio retorna false', () {
      expect(Validators.isValidCPF(''), isFalse);
    });

    test('CPF com dígito verificador errado retorna false', () {
      expect(Validators.isValidCPF('12345678900'), isFalse);
    });

    test('CPF com pontuação é aceito (dígitos extraídos)', () {
      expect(Validators.isValidCPF('123.456.789-09'), isTrue);
    });
  });

  group('validateCPF', () {
    test('CPF nulo retorna mensagem de erro', () {
      expect(Validators.validateCPF(null), isNotNull);
    });

    test('CPF vazio retorna mensagem de erro', () {
      expect(Validators.validateCPF(''), isNotNull);
    });

    test('CPF com menos de 11 dígitos retorna mensagem de erro', () {
      expect(Validators.validateCPF('12345678'), isNotNull);
    });

    test('CPF inválido retorna mensagem de erro', () {
      expect(Validators.validateCPF('12345678900'), isNotNull);
    });

    test('CPF válido retorna null', () {
      expect(Validators.validateCPF('12345678909'), isNull);
    });
  });

  group('formatCPF', () {
    test('Formata CPF sem pontuação corretamente', () {
      expect(Validators.formatCPF('12345678909'), '123.456.789-09');
    });

    test('Formata CPF com pontuação mantendo o mesmo resultado', () {
      expect(Validators.formatCPF('123.456.789-09'), '123.456.789-09');
    });

    test('CPF com menos de 11 dígitos retorna o valor original', () {
      const cpf = '12345';
      expect(Validators.formatCPF(cpf), cpf);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Email
  // ──────────────────────────────────────────────────────────────
  group('validateEmail', () {
    test('Email válido retorna null', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('first.last@domain.org'), isNull);
    });

    test('Email sem @ retorna mensagem de erro', () {
      expect(Validators.validateEmail('invalidemail'), isNotNull);
    });

    test('Email sem domínio retorna mensagem de erro', () {
      expect(Validators.validateEmail('user@'), isNotNull);
    });

    test('Email nulo retorna mensagem de erro', () {
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('Email vazio retorna mensagem de erro', () {
      expect(Validators.validateEmail(''), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Password
  // ──────────────────────────────────────────────────────────────
  group('validatePassword', () {
    test('Senha com 6 ou mais caracteres retorna null', () {
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword('123456'), isNull);
    });

    test('Senha com menos de 6 caracteres retorna mensagem de erro', () {
      expect(Validators.validatePassword('123'), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
    });

    test('Senha nula retorna mensagem de erro', () {
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('Senha vazia retorna mensagem de erro', () {
      expect(Validators.validatePassword(''), isNotNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('Confirmação igual à senha retorna null', () {
      expect(Validators.validatePasswordConfirmation('abc123', 'abc123'), isNull);
    });

    test('Confirmação diferente da senha retorna mensagem de erro', () {
      expect(
        Validators.validatePasswordConfirmation('abc123', 'xyz789'),
        isNotNull,
      );
    });

    test('Confirmação nula retorna mensagem de erro', () {
      expect(Validators.validatePasswordConfirmation(null, 'abc123'), isNotNull);
    });

    test('Confirmação vazia retorna mensagem de erro', () {
      expect(Validators.validatePasswordConfirmation('', 'abc123'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Name
  // ──────────────────────────────────────────────────────────────
  group('validateName', () {
    test('Nome com duas palavras retorna null', () {
      expect(Validators.validateName('João Silva'), isNull);
    });

    test('Nome com mais de duas palavras retorna null', () {
      expect(Validators.validateName('João da Silva'), isNull);
    });

    test('Nome com apenas uma palavra retorna mensagem de erro', () {
      expect(Validators.validateName('João'), isNotNull);
    });

    test('Nome nulo retorna mensagem de erro', () {
      expect(Validators.validateName(null), isNotNull);
    });

    test('Nome vazio retorna mensagem de erro', () {
      expect(Validators.validateName(''), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // NotEmpty / Number
  // ──────────────────────────────────────────────────────────────
  group('validateNotEmpty', () {
    test('Valor preenchido retorna null', () {
      expect(Validators.validateNotEmpty('qualquer valor', 'Campo'), isNull);
    });

    test('Valor vazio retorna mensagem com o nome do campo', () {
      final result = Validators.validateNotEmpty('', 'Nome');
      expect(result, isNotNull);
      expect(result, contains('Nome'));
    });

    test('Valor nulo retorna mensagem de erro', () {
      expect(Validators.validateNotEmpty(null, 'Campo'), isNotNull);
    });
  });

  group('validateNumber', () {
    test('String numérica válida retorna null', () {
      expect(Validators.validateNumber('42', 'Capacidade'), isNull);
      expect(Validators.validateNumber('0', 'Valor'), isNull);
    });

    test('String não numérica retorna mensagem de erro', () {
      expect(Validators.validateNumber('abc', 'Capacidade'), isNotNull);
      expect(Validators.validateNumber('12.5', 'Capacidade'), isNotNull);
    });

    test('String vazia retorna mensagem de erro', () {
      expect(Validators.validateNumber('', 'Campo'), isNotNull);
    });

    test('Valor nulo retorna mensagem de erro', () {
      expect(Validators.validateNumber(null, 'Campo'), isNotNull);
    });
  });
}
