// Testes de widget sobre as telas reais de login, cadastro e embarcação,
// com AuthRepository ligado a dublês em memória:
// CT-AUT-01, 03, 05, 08; CT-EMB-07; CT-UI-01, CT-UI-03, CT-UI-05.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:amazon_track_data/config/theme.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/data/repositories/auth_repository.dart';
import 'package:amazon_track_data/presentation/providers/service_provider.dart';
import 'package:amazon_track_data/presentation/screens/boat_registration_screen.dart';
import 'package:amazon_track_data/presentation/screens/login_screen.dart';
import 'package:amazon_track_data/presentation/screens/signup_screen.dart';

import '../helpers/fakes.dart';

late FakeAuthDatasource _auth;
late FakeFirestoreDatasource _firestore;

Widget _app(String inicial, {double textScale = 1.0}) {
  final router = GoRouter(
    initialLocation: inicial,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: '/boat-registration',
          builder: (_, __) => const BoatRegistrationScreen()),
      GoRoute(
          path: '/boat-list',
          builder: (_, __) => const Scaffold(body: Text('LISTA'))),
      GoRoute(
          path: '/map', builder: (_, __) => const Scaffold(body: Text('MAPA'))),
      GoRoute(
          path: '/passenger-home',
          builder: (_, __) => const Scaffold(body: Text('PASSAGEIRO'))),
    ],
  );
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        AuthRepository(authDatasource: _auth, firestoreDatasource: _firestore),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

Finder _campo(String hint) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == hint);

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _preencherCadastro(
  WidgetTester tester, {
  String nome = 'Maria da Silva',
  String email = 'maria@teste.example',
  String cpf = '52998224725',
  String senha = 'senha123',
  String confirmacao = 'senha123',
}) async {
  await tester.enterText(_campo('Nome Completo'), nome);
  await tester.enterText(_campo('Email'), email);
  await tester.enterText(_campo('CPF'), cpf);
  await tester.enterText(_campo('Senha'), senha);
  await tester.enterText(_campo('Confirmar Senha'), confirmacao);
  await tester.pump();
}

Future<void> _selecionarPerfil(WidgetTester tester, String perfil) async {
  await _tocar(tester, find.byType(DropdownButtonFormField<UserType>));
  await tester.tap(find.text(perfil).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _auth = FakeAuthDatasource();
    _firestore = FakeFirestoreDatasource();
  });

  testWidgets('CT-UI-01 cadastro vazio mostra mensagem sob cada um dos 6 '
      'campos e não envia', (tester) async {
    await tester.pumpWidget(_app('/signup'));
    await tester.pumpAndSettle();
    await _tocar(tester, find.text('Cadastrar'));
    for (final msg in [
      'Nome completo é obrigatório',
      'Email é obrigatório',
      'CPF é obrigatório',
      'Senha é obrigatória',
      'Confirmação de senha é obrigatória',
      'Selecione um tipo de usuário',
    ]) {
      expect(find.text(msg), findsOneWidget, reason: msg);
    }
    expect(_firestore.users, isEmpty);
  });

  testWidgets('CT-AUT-03 (a) CPF 123.456.789-00 → "CPF inválido" sem envio',
      (tester) async {
    await tester.pumpWidget(_app('/signup'));
    await tester.pumpAndSettle();
    await _preencherCadastro(tester, cpf: '12345678900');
    await _selecionarPerfil(tester, 'Passageiro');
    await _tocar(tester, find.text('Cadastrar'));
    expect(find.text('CPF inválido'), findsOneWidget);
    expect(_firestore.users, isEmpty);
  });

  testWidgets('CT-AUT-08 senha de 5 caracteres e confirmação divergente',
      (tester) async {
    await tester.pumpWidget(_app('/signup'));
    await tester.pumpAndSettle();
    await _preencherCadastro(tester, senha: 'abcde', confirmacao: 'abcdeg');
    await _tocar(tester, find.text('Cadastrar'));
    expect(find.text('Senha deve ter no mínimo 6 caracteres'), findsOneWidget);
    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });

  testWidgets('CT-AUT-01 cadastro válido grava perfil passageiro e volta ao '
      'login', (tester) async {
    await tester.pumpWidget(_app('/signup'));
    await tester.pumpAndSettle();
    await _preencherCadastro(tester);
    await _selecionarPerfil(tester, 'Passageiro');
    await _tocar(tester, find.text('Cadastrar'));
    expect(find.text('Cadastro realizado com sucesso!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    final perfil = _firestore.users.values.single;
    expect(perfil.userType, UserType.passageiro);
    expect(perfil.cpf, '52998224725');
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('CT-AUT-05 login inválido: mensagem em português sem estrutura '
      'interna', (tester) async {
    await _auth.signUpWithEmail(
        email: 'maria@teste.example', password: 'senha123');
    await _auth.signOut();
    await tester.pumpWidget(_app('/login'));
    await tester.pumpAndSettle();
    await tester.enterText(_campo('Email'), 'maria@teste.example');
    await tester.enterText(_campo('Senha'), 'errada1');
    await _tocar(tester, find.text('Entrar'));
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    final texto = (snack.content as Text).data!;
    // ignore: avoid_print
    print('CT-AUT-05 mensagem exibida: "$texto"');
    expect(find.text('MAPA'), findsNothing);
    expect(texto, isNot(contains('Failure(')));
    expect(texto, isNot(contains('code:')));
  });

  group('CT-EMB-07 formulário de embarcação', () {
    Future<void> salvar(WidgetTester tester,
        {String nome = '', String tipo = '', String cap = ''}) async {
      await tester.pumpWidget(_app('/boat-registration'));
      await tester.pumpAndSettle();
      await tester.enterText(_campo('Nome da Embarcação'), nome);
      await tester.enterText(_campo('Tipo (ex: Barco, Lancha, Canoa)'), tipo);
      await tester.enterText(_campo('Capacidade de Passageiros'), cap);
      await _tocar(tester, find.text('Salvar Embarcação'));
    }

    // Sem usuário logado, um salvamento iniciado exibe este aviso; vê-lo
    // significa que o formulário passou na validação.
    const iniciouSalvamento = 'Erro: usuário não autenticado';

    testWidgets('CT-EMB-07 (a) campos vazios são bloqueados', (tester) async {
      await salvar(tester);
      expect(find.text('Nome é obrigatório'), findsOneWidget);
      expect(find.text('Tipo é obrigatório'), findsOneWidget);
      expect(find.text('Capacidade é obrigatória'), findsOneWidget);
      expect(find.text(iniciouSalvamento), findsNothing);
    });

    testWidgets('CT-EMB-07 (b) capacidade "abc" é rejeitada', (tester) async {
      await salvar(tester, nome: 'Comandante Silva', tipo: 'Lancha', cap: 'abc');
      expect(find.text(iniciouSalvamento), findsNothing);
    });

    testWidgets('CT-EMB-07 (c) capacidade "-5" é rejeitada', (tester) async {
      await salvar(tester, nome: 'Comandante Silva', tipo: 'Lancha', cap: '-5');
      expect(find.text(iniciouSalvamento), findsNothing);
    });
  });

  group('CT-UI-03 diretrizes de acessibilidade (WCAG 2.1 AA)', () {
    for (final rota in ['/login', '/signup']) {
      testWidgets('CT-UI-03 $rota: alvo de toque ≥ 48 dp', (tester) async {
        final h = tester.ensureSemantics();
        await tester.pumpWidget(_app(rota));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        h.dispose();
      });

      testWidgets('CT-UI-03 $rota: tocáveis com rótulo semântico',
          (tester) async {
        final h = tester.ensureSemantics();
        await tester.pumpWidget(_app(rota));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        h.dispose();
      });

      testWidgets('CT-UI-03 $rota: contraste de texto ≥ 4,5:1',
          (tester) async {
        final h = tester.ensureSemantics();
        await tester.pumpWidget(_app(rota));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        h.dispose();
      });
    }
  });

  group('CT-UI-05 tela 320 × 568 dp com fonte 1,5×', () {
    for (final rota in ['/login', '/signup']) {
      testWidgets('CT-UI-05 $rota sem overflow', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final erros = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (d) => erros.add(d.exceptionAsString());
        try {
          await tester.pumpWidget(_app(rota, textScale: 1.5));
          await tester.pumpAndSettle();
        } finally {
          FlutterError.onError = original;
        }
        // ignore: avoid_print
        if (erros.isNotEmpty) print('CT-UI-05 $rota: ${erros.first}');
        expect(erros.where((e) => e.contains('overflowed')), isEmpty);
      });
    }
  });
}
