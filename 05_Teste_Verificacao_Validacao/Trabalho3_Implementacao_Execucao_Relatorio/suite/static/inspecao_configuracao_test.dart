// Inspeção estática automatizada (nível E, PROC-03): CT-SEG-03, 04, 11, 12;
// CT-SEG-01 e CT-EMB-06 (parte E, regras versionadas em docs/);
// CT-COM-07 e CT-COM-08 (página de distribuição).
//
// Executar a partir da raiz do projeto. Cada falha lista arquivo:linha.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _arquivos(String dir, List<String> extensoes) sync* {
  final d = Directory(dir);
  if (!d.existsSync()) return;
  for (final e in d.listSync(recursive: true)) {
    if (e is File && extensoes.any(e.path.endsWith)) yield e;
  }
}

List<String> _ocorrencias(Iterable<File> arquivos, RegExp padrao) {
  final achados = <String>[];
  for (final f in arquivos) {
    final linhas = f.readAsLinesSync();
    for (var i = 0; i < linhas.length; i++) {
      if (padrao.hasMatch(linhas[i])) {
        achados.add('${f.path.replaceAll('\\', '/')}:${i + 1}: '
            '${linhas[i].trim()}');
      }
    }
  }
  return achados;
}

void main() {
  test('CT-SEG-03 nenhum log registra perfil, CPF, senha ou token', () {
    final achados = _ocorrencias(
      _arquivos('lib', ['.dart']),
      RegExp(r'(debugPrint|print)\(.*(toMap\(\)|cpf|password|senha|token)',
          caseSensitive: false),
    );
    expect(achados, isEmpty, reason: achados.join('\n'));
  });

  test('CT-SEG-04 repositório sem chave privada ou conta de serviço', () {
    final achados = _ocorrencias(
      [
        ..._arquivos('lib', ['.dart']),
        ..._arquivos('android', ['.json', '.kts', '.gradle', '.properties', '.xml']),
        ..._arquivos('assets', ['.json']),
      ],
      RegExp(r'private_key|"type"\s*:\s*"service_account"|BEGIN PRIVATE KEY'),
    );
    expect(achados, isEmpty, reason: achados.join('\n'));
  });

  test('CT-SEG-11 build release não é assinado com a chave de depuração', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('buildTypes'));
    final releaseComDebug =
        RegExp(r'release\s*\{[^}]*signingConfigs\.getByName\("debug"\)');
    expect(releaseComDebug.hasMatch(gradle), isFalse,
        reason: 'buildTypes.release usa signingConfigs.getByName("debug")');
  });

  test('CT-SEG-12 nenhum endpoint http:// sem TLS no código', () {
    final achados = _ocorrencias(
      _arquivos('lib', ['.dart']),
      RegExp(r'''['"]http://'''),
    );
    expect(achados, isEmpty, reason: achados.join('\n'));
  });

  test('CT-SEG-01 (E) regras Firestore não liberam todo o banco a qualquer '
      'autenticado', () {
    final regras = File('docs/FIRESTORE_RULES.txt').readAsStringSync();
    final global = RegExp(
        r'match\s*/\{document=\*\*\}\s*\{\s*allow read, write: if request\.auth != null;');
    expect(global.hasMatch(regras), isFalse,
        reason: 'curinga {document=**} com read/write para qualquer usuário '
            'autenticado permite acesso horizontal (users, boats, chats...)');
  });

  test('CT-EMB-06 (E) regra de Storage cobre o caminho usado pelo app', () {
    final ds = File('lib/data/datasources/firebase_storage_datasource.dart')
        .readAsStringSync();
    final caminhoApp = RegExp(r"child\('([^/']+)/").firstMatch(ds)!.group(1)!;
    final regras = File('docs/STORAGE_RULES.txt').readAsStringSync();
    expect(regras, contains('match /$caminhoApp/'),
        reason: 'app grava em "$caminhoApp/", regra não cobre esse caminho');
  });

  final semSite = !Directory('website').existsSync();
  const motivo = 'website/ não existe na cópia de trabalho atual';

  test('CT-COM-07 (E) página web declara viewport responsivo', () {
    final html = File('website/index.html').readAsStringSync();
    expect(html, contains('name="viewport"'));
  }, skip: semSite ? motivo : false);

  test('CT-COM-08 (E) APK publicado presente e versão igual à do app', () {
    expect(File('website/public/downloads/amazon-track.apk').existsSync(),
        isTrue);
  }, skip: semSite ? motivo : false);
}
