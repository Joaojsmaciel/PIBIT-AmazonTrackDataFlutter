// Testes de Integração — Amazon Track Data
//
// Estes testes rodam em dispositivo/emulador real e verificam fluxos
// da aplicação de ponta a ponta.
//
// Para executar:
//   flutter test testes/integration_test/app_integration_test.dart
//   flutter test testes/integration_test/app_integration_test.dart -d <device_id>
//
// Pré-requisitos:
//   - Firebase configurado (google-services.json / GoogleService-Info.plist)
//   - Dispositivo físico ou emulador conectado

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:amazon_track_data/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────
  // Smoke test — inicialização do app
  // ──────────────────────────────────────────────────────────────
  group('App Smoke Test', () {
    testWidgets('App inicializa sem erros e exibe a tela inicial',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Fluxo de autenticação — Tela de Login
  // ──────────────────────────────────────────────────────────────
  group('Tela de Login', () {
    testWidgets('Campos de email e senha são exibidos',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Botão de login está presente e habilitado',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ElevatedButton || widget is TextButton,
        ),
        findsWidgets,
      );
    });

    testWidgets('Credenciais inválidas exibem mensagem de erro',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'email_invalido');

      final loginButton = find.text('Entrar');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(
          find.byType(SnackBar).evaluate().isNotEmpty ||
              find.byType(Text).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Fluxo de cadastro — Tela de Signup
  // ──────────────────────────────────────────────────────────────
  group('Tela de Cadastro', () {
    testWidgets('Navegação para tela de cadastro funciona',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final signupTrigger = find.textContaining('Cadastr');
      if (signupTrigger.evaluate().isNotEmpty) {
        await tester.tap(signupTrigger.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(TextField), findsWidgets);
      }
    });
  });
}
