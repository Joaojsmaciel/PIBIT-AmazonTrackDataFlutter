// Casos CT-RAS-03, CT-RAS-11, CT-OFF-02, CT-OFF-05, CT-OFF-07, CT-OFF-08,
// CT-NF-01 e CT-NF-06 sobre o LocalDatabaseService real (SQLite do host).

import 'package:flutter_test/flutter_test.dart';

import 'package:amazon_track_data/core/utils/kalman_filter.dart';
import 'package:amazon_track_data/data/datasources/local_database.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

import '../helpers/test_env.dart';

const _baseTs = 1757239200000;

LocationModel ponto(
  int i, {
  double lat = -3.148781,
  double lng = -58.449257,
  double accuracy = 8,
  double speed = 3.0,
  String userId = 'uid-barqueiro-a',
}) =>
    LocationModel(
      userId: userId,
      tripId: 'trip-1',
      boatId: 'boat-a',
      latitude: lat,
      longitude: lng,
      speed: speed,
      accuracy: accuracy,
      altitude: 32,
      bearing: 90,
      timestamp: _baseTs + i * 5000,
      userType: 'barqueiro',
      userName: 'Barqueiro A',
    );

void main() {
  final db = LocalDatabaseService();

  setUpAll(setUpHostDatabase);
  setUp(() => db.clearAll());
  tearDownAll(() => db.dispose());

  test('CT-RAS-03 ponto válido é persistido completo com ID uid_timestamp',
      () async {
    await db.insertLocation(ponto(0));
    final rows = await db.getAllUnsynced();
    expect(rows, hasLength(1));
    final r = rows.single;
    expect(r['id'], 'uid-barqueiro-a_$_baseTs');
    expect(r['userId'], 'uid-barqueiro-a');
    expect(r['tripId'], 'trip-1');
    expect(r['boatId'], 'boat-a');
    expect(r['speed'], 3.0);
    expect(r['accuracy'], 8.0);
    expect(r['altitude'], 32.0);
    expect(r['bearing'], 90.0);
    expect(r['timestamp'], _baseTs);
    expect(r['synced'], 0);
    expect(LocationModel.fromMap(r), ponto(0));
  });

  group('CT-RAS-11 leituras inválidas (RD-02, RD-04)', () {
    test('CT-RAS-11 limites lat ±90 e lon ±180 são aceitos', () async {
      await db.insertLocation(ponto(1, lat: 90, lng: 180));
      await db.insertLocation(ponto(2, lat: -90, lng: -180));
      expect(await db.getPendingCount(), 2);
    });

    test('CT-RAS-11 lat 95, lat -90,5, lon 181 e precisão -1 não entram '
        'na fila de sincronização', () async {
      final invalidos = [
        ponto(1, lat: 95),
        ponto(2, lat: -90.5),
        ponto(3, lng: 181),
        ponto(4, accuracy: -1),
      ];
      for (final p in invalidos) {
        try {
          await db.insertLocation(p);
        } catch (_) {
          // rejeição explícita também atende ao caso
        }
      }
      expect(await db.getPendingCount(), 0);
    });
  });

  test('CT-OFF-02 fila sobrevive ao fechamento do banco; limpeza remove só '
      'confirmados', () async {
    for (var i = 0; i < 10; i++) {
      await db.insertLocation(ponto(i));
    }
    await db.markAsSyncedById('uid-barqueiro-a_$_baseTs');
    await db.dispose(); // simula encerramento do processo
    final reaberto = LocalDatabaseService();
    final rows = await reaberto.getAllUnsynced();
    expect(rows, hasLength(9));
    expect(rows.map((r) => r['timestamp']),
        List.generate(9, (i) => _baseTs + (i + 1) * 5000));
    final removidos = await reaberto.deleteOlderThan(_baseTs + 10 * 5000);
    expect(removidos, 1);
    expect(await reaberto.getPendingCount(), 9);
  });

  test('CT-OFF-05 o mesmo ponto inserido 3 vezes gera 1 pendente', () async {
    for (var i = 0; i < 3; i++) {
      await db.insertLocation(ponto(7));
    }
    expect(await db.getPendingCount(), 1);
  });

  test('CT-OFF-07 pendentes retornam em ordem cronológica (FIFO)', () async {
    for (final i in [5, 1, 9, 3, 7]) {
      await db.insertLocation(ponto(i));
    }
    final ts = (await db.getAllUnsynced()).map((r) => r['timestamp']).toList();
    expect(ts, [1, 3, 5, 7, 9].map((i) => _baseTs + i * 5000).toList());
  });

  test('CT-OFF-08 consulta de pendentes limita o lote a 50', () async {
    for (var i = 0; i < 51; i++) {
      await db.insertLocation(ponto(i));
    }
    expect(await db.getAllUnsynced(), hasLength(50));
    expect(await db.getPendingCount(), 51);
  });

  test('CT-NF-01 processamento local do ponto (Kalman + SQLite) p95 ≤ 2 s',
      () async {
    final kf = KalmanFilter(initialValue: 0);
    final amostras = <double>[];
    for (var i = 0; i < 60; i++) {
      final sw = Stopwatch()..start();
      final v = kf.update(3.0 + (i % 3) * 0.1);
      await db.insertLocation(ponto(i, speed: v));
      sw.stop();
      amostras.add(sw.elapsedMicroseconds / 1000);
    }
    final p95 = percentile(amostras, 95);
    // ignore: avoid_print
    print('CT-NF-01 p95 = ${p95.toStringAsFixed(2)} ms (n=60, host)');
    expect(p95, lessThanOrEqualTo(2000));
  });

  test('CT-NF-06 fila com 5.000 pontos: lote 50 em ordem, consulta < 2 s',
      () async {
    final swInsert = Stopwatch()..start();
    for (var i = 4999; i >= 0; i--) {
      await db.insertLocation(ponto(i));
    }
    swInsert.stop();
    final sw = Stopwatch()..start();
    final lote = await db.getAllUnsynced();
    sw.stop();
    // ignore: avoid_print
    print('CT-NF-06 inserção 5000 = ${swInsert.elapsedMilliseconds} ms; '
        'consulta lote = ${sw.elapsedMilliseconds} ms');
    expect(lote, hasLength(50));
    expect(lote.first['timestamp'], _baseTs);
    expect(lote.last['timestamp'], _baseTs + 49 * 5000);
    expect(sw.elapsedMilliseconds, lessThan(2000));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
