// Ambiente de execução no host (sem Android, sem Firebase real).
//
// Substitui as dependências nativas usadas pelo AmazonTrackData por versões
// controladas pelo teste (EAPT-ATD-001, PROC-01):
//   - sqflite            → sqflite_common_ffi (SQLite real do host)
//   - path_provider      → canal simulado apontando para um diretório temporário
//   - connectivity_plus  → canal + fluxo de eventos controlados (ConnectivityMock)
//   - local_notifications→ espião do canal (NotificationSpy)

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
const _connectivityChannel =
    MethodChannel('dev.fluttercommunity.plus/connectivity');
const _connectivityEvents =
    EventChannel('dev.fluttercommunity.plus/connectivity_status');
const _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Diretório temporário exclusivo da execução (banco SQLite isolado).
late Directory hostTempDir;

/// Prepara SQLite FFI e o diretório de documentos simulado.
Future<void> setUpHostDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  hostTempDir = await Directory.systemTemp.createTemp('atd_test_');
  _messenger.setMockMethodCallHandler(_pathProviderChannel, (call) async {
    return hostTempDir.path;
  });
}

/// Estados de rede controlados pelo teste.
class ConnectivityMock {
  ConnectivityMock._();
  static final ConnectivityMock instance = ConnectivityMock._();

  String current = 'none';
  MockStreamHandlerEventSink? _sink;

  void install({String initial = 'none'}) {
    TestWidgetsFlutterBinding.ensureInitialized();
    current = initial;
    _messenger.setMockMethodCallHandler(_connectivityChannel, (call) async {
      if (call.method == 'check') return current;
      return null;
    });
    _messenger.setMockStreamHandler(
      _connectivityEvents,
      MockStreamHandler.inline(
        onListen: (args, sink) => _sink = sink,
        onCancel: (args) => _sink = null,
      ),
    );
  }

  /// Emite uma transição de rede: 'wifi', 'mobile' ou 'none'.
  Future<void> emit(String state) async {
    current = state;
    _sink?.success(state);
    await settle();
  }
}

/// Registra cada notificação exibida pelo app (título e texto).
class NotificationSpy {
  NotificationSpy._();
  static final NotificationSpy instance = NotificationSpy._();

  final List<({String title, String body})> shown = [];

  List<String> get titles => shown.map((n) => n.title).toList();

  void install() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _messenger.setMockMethodCallHandler(_notificationsChannel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'show':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          shown.add((
            title: args['title'] as String? ?? '',
            body: args['body'] as String? ?? '',
          ));
          return null;
        default:
          return null;
      }
    });
  }

  void clear() => shown.clear();
}

/// Aguarda microtarefas e callbacks assíncronos pendentes.
Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Percentil p (0–100) de uma lista de amostras.
double percentile(List<double> samples, double p) {
  final sorted = [...samples]..sort();
  final rank = (p / 100 * (sorted.length - 1)).round();
  return sorted[rank];
}
