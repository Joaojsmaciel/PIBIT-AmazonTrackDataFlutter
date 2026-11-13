// Casos CT-AUT-03, 08, 09, 10 — partição de equivalência e valor-limite
// (EAPT-ATD-001, seção 3.2).

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/core/validators/validators.dart';

void main() {
  group('CT-AUT-03 CPF (RN-02)', () {
    test('CT-AUT-03 CPFs válidos com e sem máscara são aceitos', () {
      for (final cpf in [
        '529.982.247-25',
        '52998224725',
        '111.444.777-35',
        '11144477735',
      ]) {
        expect(Validators.validateCPF(cpf), isNull, reason: cpf);
      }
    });

    test('CT-AUT-03 CPF vazio é recusado com mensagem', () {
      expect(Validators.validateCPF(''), 'CPF é obrigatório');
      expect(Validators.validateCPF(null), 'CPF é obrigatório');
    });

    test('CT-AUT-03 CPF com 10 e 12 dígitos é recusado', () {
      expect(Validators.validateCPF('5299822472'), 'CPF deve ter 11 dígitos');
      expect(
          Validators.validateCPF('529982247250'), 'CPF deve ter 11 dígitos');
    });

    test('CT-AUT-03 CPF com 1º dígito verificador errado é recusado', () {
      expect(Validators.validateCPF('529.982.247-15'), 'CPF inválido');
    });

    test('CT-AUT-03 CPF com 2º dígito verificador errado é recusado', () {
      expect(Validators.validateCPF('529.982.247-26'), 'CPF inválido');
    });

    test('CT-AUT-03 CPF com todos os dígitos iguais é recusado', () {
      for (var d = 0; d <= 9; d++) {
        expect(Validators.isValidCPF('$d' * 11), isFalse, reason: '$d' * 11);
      }
    });

    test('CT-AUT-03 CPF 123.456.789-00 é recusado', () {
      expect(Validators.validateCPF('123.456.789-00'), 'CPF inválido');
    });

    test('CT-AUT-03 CPF com letras não é aceito', () {
      expect(Validators.validateCPF('abc.def.ghi-jk'), isNotNull);
    });
  });

  group('CT-AUT-08 senha e confirmação (RN-03)', () {
    test('CT-AUT-08 senha com 5 caracteres é rejeitada', () {
      expect(Validators.validatePassword('abcde'),
          'Senha deve ter no mínimo 6 caracteres');
    });

    test('CT-AUT-08 senha com 6 caracteres é aceita (limite)', () {
      expect(Validators.validatePassword('abcdef'), isNull);
    });

    test('CT-AUT-08 senha com 7 caracteres é aceita', () {
      expect(Validators.validatePassword('abcdefg'), isNull);
    });

    test('CT-AUT-08 senha vazia é rejeitada', () {
      expect(Validators.validatePassword(''), 'Senha é obrigatória');
    });

    test('CT-AUT-08 confirmação divergente é rejeitada', () {
      expect(Validators.validatePasswordConfirmation('abcdeg', 'abcdef'),
          'As senhas não coincidem');
    });

    test('CT-AUT-08 confirmação idêntica é aceita', () {
      expect(Validators.validatePasswordConfirmation('abcdef', 'abcdef'),
          isNull);
    });
  });

  group('CT-AUT-09 nome com dois termos (RN-04)', () {
    test('CT-AUT-09 nome com um termo é rejeitado', () {
      expect(Validators.validateName('Maria'), isNotNull);
    });

    test('CT-AUT-09 nome com dois termos é aceito', () {
      expect(Validators.validateName('Maria Silva'), isNull);
    });

    test('CT-AUT-09 espaços extras entre e ao redor dos termos são aceitos', () {
      expect(Validators.validateName('  Maria    Silva  '), isNull);
    });

    test('CT-AUT-09 nome só com espaços é rejeitado', () {
      expect(Validators.validateName('     '), isNotNull);
    });
  });

  group('CT-AUT-10 formato de e-mail', () {
    test('CT-AUT-10 e-mails válidos são aceitos', () {
      for (final e in [
        'joao.maciel+qa@ufam.edu.br',
        'a@b.co',
        'qa.passageiro@teste.example',
      ]) {
        expect(Validators.validateEmail(e), isNull, reason: e);
      }
    });

    test('CT-AUT-10 e-mails inválidos são recusados com mensagem', () {
      for (final e in [
        'sem-arroba.com',
        'a@b',
        'a@b.c',
        'joao maciel@ufam.edu.br',
      ]) {
        expect(Validators.validateEmail(e), 'Email inválido', reason: e);
      }
      expect(Validators.validateEmail(''), 'Email é obrigatório');
    });
  });
}
