// Casos CT-OFF-01..11, CT-NF-05 e CT-NF-08 sobre o OfflineSyncService real
// (fila SharedPreferences), com conectividade controlada e servidor simulado
// (EAPT-ATD-001, seções 3.3 e 3.5).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amazon_track_data/core/services/offline_sync_service.dart';
import 'package:amazon_track_data/data/datasources/local_database.dart';
import 'package:amazon_track_data/data/models/local_location_point.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

import '../helpers/test_env.dart';

const _storageKey = 'amazon_offline_location_queue';
final _base = DateTime.utc(2026, 9, 7, 10);

/// Servidor simulado: registra envios e injeta falhas, exceções e lentidão.
class FakeBackend {
  final List<String> received = [];
  final Set<String> reject = {};
  final Set<String> throwOn = {};
  bool rejectAll = false;
  Duration delay = Duration.zero;
  DateTime? firstReceivedAt;

  void reset() {
    received.clear();
    reject.clear();
    throwOn.clear();
    rejectAll = false;
    delay = Duration.zero;
    firstReceivedAt = null;
    attempts = 0;
  }

  int attempts = 0;

  Future<bool> handle(LocalLocationPoint p) async {
    attempts++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwOn.contains(p.id)) throw Exception('falha de rede em ${p.id}');
    if (rejectAll || reject.contains(p.id)) return false;
    firstReceivedAt ??= DateTime.now();
    received.add(p.id);
    return true;
  }
}

LocalLocationPoint _pt(int i) => LocalLocationPoint(
      id: 'p$i',
      latitude: -3.148781,
      longitude: -58.449257,
      velocidade: 3,
      timestamp: _base.add(Duration(seconds: 5 * i)),
      userId: 'uid-barqueiro-a',
      tripId: 'trip-1',
      boatId: 'boat-a',
    );

final _svc = OfflineSyncService();
final _net = ConnectivityMock.instance;
final _backend = FakeBackend();

Future<List<String>> _pendentes() async =>
    (await _svc.getPendingPoints()).map((p) => p.id).toList();

Future<void> _salvarOffline(Iterable<int> ids) async {
  for (final i in ids) {
    await _svc.savePoint(_pt(i));
  }
}

void main() {
  setUpAll(() async {
    // A suíte fica fora de test/, então o analisador não a reconhece como teste.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    _net.install(initial: 'none');
    await _svc.initialize(onSync: _backend.handle);
  });

  setUp(() async {
    await _net.emit('none');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _backend.reset();
  });

  test('CT-OFF-01 sem internet os pontos ficam pendentes e nada é enviado',
      () async {
    await _salvarOffline([1, 2, 3]);
    expect(await _svc.getPendingCount(), 3);
    expect(_backend.received, isEmpty);
  });

  test('CT-OFF-02 fila persistida é recuperada e registro corrompido é '
      'ignorado', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, [
      _pt(1).toJsonString(),
      '{corrompido',
      _pt(2).toJsonString(),
    ]);
    expect(await _pendentes(), ['p1', 'p2']);
  });

  test('CT-OFF-03 ao reconectar a sincronização é iniciada e esvazia a fila',
      () async {
    await _salvarOffline([1, 2]);
    await _net.emit('wifi');
    await settle(200);
    expect(_backend.received, ['p1', 'p2']);
    expect(await _svc.getPendingCount(), 0);
  });

  test('CT-OFF-04 falha parcial mantém só os recusados para o próximo ciclo',
      () async {
    await _salvarOffline([1, 2, 3, 4, 5]);
    _backend.reject.addAll(['p2', 'p4']);
    await _svc.forcSync();
    expect(_backend.received, ['p1', 'p3', 'p5']);
    expect(await _pendentes(), ['p2', 'p4']);
    _backend.reject.clear();
    await _svc.forcSync();
    expect(await _svc.getPendingCount(), 0);
  });

  test('CT-OFF-05 o mesmo ponto salvo 3 vezes é enviado uma vez', () async {
    for (var i = 0; i < 3; i++) {
      await _svc.savePoint(_pt(7));
    }
    expect(await _svc.getPendingCount(), 1);
    await _svc.forcSync();
    expect(_backend.received, ['p7']);
  });

  test('CT-OFF-06 Wi-Fi → móvel não reenvia; offline → Wi-Fi esvazia a fila',
      () async {
    await _net.emit('wifi');
    _backend.rejectAll = true;
    await _svc.savePoint(_pt(1)); // tentativa imediata recusada
    await settle(100);
    final tentativas = _backend.attempts;
    expect(tentativas, 1);
    await _net.emit('mobile');
    await settle(100);
    expect(_backend.attempts, tentativas);
    expect(await _svc.getPendingCount(), 1);

    _backend.rejectAll = false;
    await _net.emit('none');
    await _svc.savePoint(_pt(2));
    expect(await _svc.getPendingCount(), 2);
    await _net.emit('wifi');
    await settle(200);
    expect(await _svc.getPendingCount(), 0);
    expect(_backend.received, ['p1', 'p2']);
  });

  test('CT-OFF-07 envio na ordem de captura (FIFO)', () async {
    await _salvarOffline([1, 2, 3, 4, 5]);
    await _svc.forcSync();
    expect(_backend.received, ['p1', 'p2', 'p3', 'p4', 'p5']);
  });

  group('CT-OFF-08 lote máximo de 50 por ciclo', () {
    for (final n in [49, 50, 51]) {
      test('CT-OFF-08 fila de $n pontos', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            _storageKey, [for (var i = 0; i < n; i++) _pt(i).toJsonString()]);
        await _svc.forcSync();
        expect(_backend.received.length, n > 50 ? 50 : n);
        await _svc.forcSync();
        expect(_backend.received.length, n);
        expect(await _svc.getPendingCount(), 0);
      });
    }
  });

  group('CT-OFF-09 indicador de pendentes', () {
    test('CT-OFF-09 (a) contador acompanha inclusões e envio', () async {
      final valores = <int>[];
      final sub = _svc.pendingCount.listen(valores.add);
      await _salvarOffline([1, 2]);
      await _svc.forcSync();
      await settle();
      await sub.cancel();
      expect(valores, containsAllInOrder([1, 2, 0]));
    });

    test('CT-OFF-09 (b) indicador do mapa reflete pontos pendentes do '
        'rastreamento (SQLite)', () async {
      await setUpHostDatabase();
      final db = LocalDatabaseService();
      await db.clearAll();
      for (var i = 0; i < 3; i++) {
        await db.insertLocation(LocationModel(
          userId: 'uid-barqueiro-a',
          tripId: 'trip-1',
          boatId: 'boat-a',
          latitude: -3.148781,
          longitude: -58.449257,
          speed: 3,
          accuracy: 8,
          timestamp: 1757239200000 + i * 5000,
          userType: 'barqueiro',
          userName: 'Barqueiro A',
        ));
      }
      expect(await db.getPendingCount(), 3);
      // A MapScreen exibe offlinePendingCountProvider → OfflineSyncService.
      expect(await _svc.getPendingCount(), 3);
      // Limpeza: não deixar pontos no SQLite para os testes seguintes.
      await db.clearAll();
      await db.dispose();
    });
  });

  test('CT-OFF-10 exceção em um ponto não bloqueia os demais', () async {
    await _salvarOffline([1, 2, 3]);
    _backend.throwOn.add('p2');
    await _svc.forcSync();
    expect(_backend.received, ['p1', 'p3']);
    expect(await _pendentes(), ['p2']);
    _backend.throwOn.clear();
    await _svc.forcSync();
    expect(_backend.received, ['p1', 'p3', 'p2']);
  });

  test('CT-OFF-11 ponto salvo durante uma sincronização não é perdido',
      () async {
    await _salvarOffline([1]);
    _backend.delay = const Duration(milliseconds: 300);
    final sync = _svc.forcSync();
    await settle(50);
    await _svc.savePoint(_pt(2)); // capturado durante o envio lento
    await sync;
    expect(_backend.received, ['p1']);
    expect(await _pendentes(), ['p2']);
  });

  test('CT-NF-05 sincronização começa em até 30 s após reconectar', () async {
    await _salvarOffline([1, 2]);
    final religada = DateTime.now();
    await _net.emit('wifi');
    await settle(200);
    expect(_backend.firstReceivedAt, isNotNull);
    final ms = _backend.firstReceivedAt!.difference(religada).inMilliseconds;
    // ignore: avoid_print
    print('CT-NF-05 início do sync após reconexão = $ms ms (host)');
    expect(ms, lessThanOrEqualTo(30000));
  });

  test('CT-NF-08 100 alternâncias de rede: cada ponto enviado uma vez',
      () async {
    await _salvarOffline(List.generate(20, (i) => i));
    _backend.delay = const Duration(milliseconds: 2);
    for (var i = 0; i < 100; i++) {
      await _net.emit(i.isEven ? 'wifi' : 'none');
    }
    await _net.emit('wifi');
    await settle(500);
    await _svc.forcSync();
    expect(_backend.received, hasLength(20));
    expect(_backend.received.toSet(), hasLength(20));
    expect(await _svc.getPendingCount(), 0);
    final prefs = await SharedPreferences.getInstance();
    expect(
        (prefs.getStringList(_storageKey) ?? [])
            .map((s) => jsonDecode(s)['id']),
        isEmpty);
  });
}
