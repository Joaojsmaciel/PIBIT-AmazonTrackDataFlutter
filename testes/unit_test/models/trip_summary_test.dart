// Testes Unitários — TripSummary
//
// Cobre:
//   - duration (Duration)
//   - avgSpeedKmh (m/s → km/h)
//   - totalDistanceKm (metros → km)
//   - startDate / endDate (milliseconds → DateTime)
//   - Campos opcionais (departurePoint, arrivalPoint, stops)
//
// Para executar:
//   flutter test testes/unit_test/models/trip_summary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';

void main() {
  // Viagem de 2 horas, velocidade 5 m/s = 18 km/h, distância 36 km
  final trip = TripSummary(
    tripId: 'trip-001',
    userId: 'user-001',
    userName: 'João Silva',
    boatId: 'boat-001',
    startTimestamp: 1700000000000,
    endTimestamp: 1700007200000, // +2h
    startLat: -3.1190,
    startLng: -60.0217,
    endLat: -2.6278,
    endLng: -56.7358,
    pointCount: 720,
    avgSpeedMs: 5.0,
    totalDistanceMeters: 36000,
    departurePoint: 'Porto Manaus',
    arrivalPoint: 'Porto Parintins',
    stops: ['parada-001'],
  );

  group('TripSummary.duration', () {
    test('Calcula duração corretamente como Duration', () {
      expect(trip.duration, const Duration(hours: 2));
    });

    test('Duração zero quando start e end são iguais', () {
      final instant = TripSummary(
        tripId: 't', userId: 'u', userName: 'N', boatId: 'b',
        startTimestamp: 1000, endTimestamp: 1000,
        startLat: 0, startLng: 0, endLat: 0, endLng: 0,
        pointCount: 0, avgSpeedMs: 0, totalDistanceMeters: 0,
      );
      expect(instant.duration, Duration.zero);
    });
  });

  group('TripSummary.avgSpeedKmh', () {
    test('Converte m/s para km/h corretamente (5 m/s = 18 km/h)', () {
      expect(trip.avgSpeedKmh, closeTo(18.0, 0.001));
    });

    test('Velocidade zero resulta em 0 km/h', () {
      final stopped = TripSummary(
        tripId: 't', userId: 'u', userName: 'N', boatId: 'b',
        startTimestamp: 0, endTimestamp: 0,
        startLat: 0, startLng: 0, endLat: 0, endLng: 0,
        pointCount: 0, avgSpeedMs: 0, totalDistanceMeters: 0,
      );
      expect(stopped.avgSpeedKmh, 0.0);
    });
  });

  group('TripSummary.totalDistanceKm', () {
    test('Converte metros para km (36 000 m = 36 km)', () {
      expect(trip.totalDistanceKm, closeTo(36.0, 0.001));
    });

    test('1 000 m = 1 km', () {
      final short = TripSummary(
        tripId: 't', userId: 'u', userName: 'N', boatId: 'b',
        startTimestamp: 0, endTimestamp: 0,
        startLat: 0, startLng: 0, endLat: 0, endLng: 0,
        pointCount: 0, avgSpeedMs: 0, totalDistanceMeters: 1000,
      );
      expect(short.totalDistanceKm, 1.0);
    });
  });

  group('TripSummary.startDate e endDate', () {
    test('startDate corresponde ao timestamp de início', () {
      expect(trip.startDate, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('endDate corresponde ao timestamp de fim', () {
      expect(trip.endDate, DateTime.fromMillisecondsSinceEpoch(1700007200000));
    });

    test('endDate é depois de startDate', () {
      expect(trip.endDate.isAfter(trip.startDate), isTrue);
    });
  });

  group('TripSummary campos opcionais', () {
    test('departurePoint e arrivalPoint padrão string vazia', () {
      final t = TripSummary(
        tripId: 't', userId: 'u', userName: 'N', boatId: 'b',
        startTimestamp: 0, endTimestamp: 0,
        startLat: 0, startLng: 0, endLat: 0, endLng: 0,
        pointCount: 0, avgSpeedMs: 0, totalDistanceMeters: 0,
      );
      expect(t.departurePoint, isEmpty);
      expect(t.arrivalPoint, isEmpty);
    });

    test('stops padrão lista vazia', () {
      final t = TripSummary(
        tripId: 't', userId: 'u', userName: 'N', boatId: 'b',
        startTimestamp: 0, endTimestamp: 0,
        startLat: 0, startLng: 0, endLat: 0, endLng: 0,
        pointCount: 0, avgSpeedMs: 0, totalDistanceMeters: 0,
      );
      expect(t.stops, isEmpty);
    });
  });
}
