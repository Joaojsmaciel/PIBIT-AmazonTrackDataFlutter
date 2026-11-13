// Casos CT-RAS-08, CT-HCH-01, CT-HCH-08, CT-HCH-09, CT-OFF-01, CT-OFF-04 e
// CT-NF-10 sobre o LocationRepository real, com SQLite do host e Firestore
// em memória.

import 'package:flutter_test/flutter_test.dart';

import 'package:amazon_track_data/data/datasources/local_database.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/repositories/location_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/test_env.dart';

const _baseTs = 1757239200000;
const _lat = -3.148781;
const _lng = -58.449257;

/// Metros por grau de latitude no elipsoide WGS84 perto do Equador (Vincenty).
const _mPorGrauElipsoide = 110580.0;

LocationModel _p({
  required String tripId,
  required int ts,
  double norteMetros = 0,
  double speed = 5,
  String userId = 'uid-barqueiro-a',
}) =>
    LocationModel(
      userId: userId,
      tripId: tripId,
      boatId: 'boat-a',
      latitude: _lat + norteMetros / _mPorGrauElipsoide,
      longitude: _lng,
      speed: speed,
      accuracy: 8,
      timestamp: ts,
      userType: 'barqueiro',
      userName: 'Barqueiro A',
    );

void main() {
  late FakeFirestoreDatasource firestore;
  late LocationRepository repo;
  final db = LocalDatabaseService();

  setUpAll(setUpHostDatabase);
  tearDownAll(() => db.dispose());

  setUp(() async {
    await db.clearAll();
    firestore = FakeFirestoreDatasource();
    repo = LocationRepository(
      firestoreDatasource: firestore,
      geolocatorDatasource: FakeGeolocatorDatasource(),
      localDatabaseService: db,
    );
  });

  test('CT-RAS-08 resumo consistente com pontos entregues fora de ordem',
      () async {
    const min = 60 * 1000;
    firestore.tracks['uid-barqueiro-a'] = [
      _p(tripId: 't1', ts: _baseTs + 60 * min, norteMetros: 2000, speed: 6),
      _p(tripId: 't1', ts: _baseTs, norteMetros: 0, speed: 4),
      _p(tripId: 't1', ts: _baseTs + 30 * min, norteMetros: 1000, speed: 5),
    ];
    final trips = await repo.getUserTrips('uid-barqueiro-a');
    expect(trips, hasLength(1));
    final t = trips.single;
    expect(t.duration, const Duration(minutes: 60));
    expect(t.totalDistanceMeters, closeTo(2000, 20));
    expect(t.avgSpeedMs, closeTo(5, 1e-9));
    expect(t.pointCount, 3);
  });

  test('CT-HCH-01 histórico só do usuário, mais recente primeiro', () async {
    firestore.tracks['uid-barqueiro-a'] = [
      _p(tripId: 'antiga', ts: _baseTs),
      _p(tripId: 'antiga', ts: _baseTs + 5000),
      _p(tripId: 'recente', ts: _baseTs + 86400000),
    ];
    firestore.tracks['uid-outro'] = [
      _p(tripId: 'alheia', ts: _baseTs + 2 * 86400000, userId: 'uid-outro'),
    ];
    final trips = await repo.getUserTrips('uid-barqueiro-a');
    expect(trips.map((t) => t.tripId), ['recente', 'antiga']);
  });

  test('CT-HCH-08 pontos sem tripId são ignorados sem erro', () async {
    firestore.tracks['uid-barqueiro-a'] = [
      _p(tripId: '', ts: _baseTs),
      _p(tripId: '', ts: _baseTs + 5000),
    ];
    expect(await repo.getUserTrips('uid-barqueiro-a'), isEmpty);
  });

  group('CT-HCH-09 metadados da viagem', () {
    setUp(() {
      firestore.tracks['uid-barqueiro-a'] = [_p(tripId: 't1', ts: _baseTs)];
    });

    test('CT-HCH-09 falha nos metadados não impede o histórico', () async {
      firestore.failTripMeta = true;
      final trips = await repo.getUserTrips('uid-barqueiro-a');
      expect(trips, hasLength(1));
      expect(trips.single.departurePoint, '');
    });

    test('CT-HCH-09 metadados presentes são associados', () async {
      firestore.tripMeta['uid-barqueiro-a'] = {
        't1': {
          'departurePoint': 'Itacoatiara',
          'arrivalPoint': 'Manaus',
          'stops': ['Silves'],
        },
      };
      final t = (await repo.getUserTrips('uid-barqueiro-a')).single;
      expect(t.departurePoint, 'Itacoatiara');
      expect(t.arrivalPoint, 'Manaus');
      expect(t.stops, ['Silves']);
    });
  });

  test('CT-OFF-01 sem internet o ponto fica pendente no SQLite', () async {
    firestore.offline = true;
    for (var i = 0; i < 3; i++) {
      await repo.saveLocation(_p(tripId: 't1', ts: _baseTs + i * 5000));
    }
    expect(await db.getPendingCount(), 3);
    expect(firestore.tracks, isEmpty);
  });

  test('CT-OFF-04 falha parcial: só os confirmados saem da fila', () async {
    firestore.offline = true;
    for (var i = 0; i < 5; i++) {
      await repo.saveLocation(_p(tripId: 't1', ts: _baseTs + i * 5000));
    }
    firestore.offline = false;
    firestore.failingTimestamps.addAll([_baseTs + 5000, _baseTs + 15000]);
    await repo.syncOfflineLocations();
    final restantes =
        (await db.getAllUnsynced()).map((r) => r['timestamp']).toList();
    expect(restantes, [_baseTs + 5000, _baseTs + 15000]);

    firestore.failingTimestamps.clear();
    await repo.syncOfflineLocations();
    expect(await db.getPendingCount(), 0);
    expect(firestore.tracks['uid-barqueiro-a'], hasLength(5));
  });

  test('CT-NF-10 backend indisponível não lança exceção ao usuário', () async {
    firestore.offline = true;
    await expectLater(
      repo.saveLocation(_p(tripId: 't1', ts: _baseTs)),
      completes,
    );
    expect(await db.getPendingCount(), 1);
  });
}
