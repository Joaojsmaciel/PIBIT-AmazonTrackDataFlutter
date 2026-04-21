import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/core/validators/validators.dart';

void main() {
  group('CPF Validator Tests', () {
    test('Valid CPF should pass validation', () {
      const validCpf = '12345678909';
      expect(Validators.isValidCPF(validCpf), true);
    });

    test('Invalid CPF with all same digits should fail', () {
      const invalidCpf = '11111111111';
      expect(Validators.isValidCPF(invalidCpf), false);
    });

    test('Invalid CPF with wrong length should fail', () {
      const invalidCpf = '123456789';
      expect(Validators.isValidCPF(invalidCpf), false);
    });

    test('Valid CPF formatting should add dots and dash', () {
      const cpf = '12345678909';
      const formatted = '123.456.789-09';
      expect(Validators.formatCPF(cpf), formatted);
    });

    test('Email validation should accept valid email', () {
      const validEmail = 'user@example.com';
      expect(Validators.validateEmail(validEmail), null);
    });

    test('Email validation should reject invalid email', () {
      const invalidEmail = 'invalid.email';
      expect(Validators.validateEmail(invalidEmail), isNotNull);
    });

    test('Password validation should accept valid password', () {
      const validPassword = 'password123';
      expect(Validators.validatePassword(validPassword), null);
    });

    test('Password validation should reject short password', () {
      const shortPassword = '123';
      expect(Validators.validatePassword(shortPassword), isNotNull);
    });

    test('Name validation should accept full name', () {
      const validName = 'John Doe';
      expect(Validators.validateName(validName), null);
    });

    test('Name validation should reject single word name', () {
      const invalidName = 'John';
      expect(Validators.validateName(invalidName), isNotNull);
    });
  });
}
