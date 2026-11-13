// Testes Unitários — LocationModel
//
// Cobre:
//   - toMap() / fromMap() (serialização e desserialização)
//   - Campos opcionais (altitude, bearing, boatId)
//   - Cast de int para double nos campos numéricos
//   - Igualdade via Equatable
//
// Para executar:
//   flutter test testes/unit_test/models/location_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

void main() {
  final location = LocationModel(
    userId: 'user-001',
    tripId: 'trip-001',
    boatId: 'boat-001',
    latitude: -3.1190,
    longitude: -60.0217,
    speed: 12.5,
    altitude: 15.0,
    accuracy: 5.0,
    bearing: 270.0,
    timestamp: 1700000000000,
    userType: 'passageiro',
    userName: 'João Silva',
  );

  group('LocationModel.toMap', () {
    test('Serializa todos os campos corretamente', () {
      final map = location.toMap();

      expect(map['userId'], 'user-001');
      expect(map['tripId'], 'trip-001');
      expect(map['boatId'], 'boat-001');
      expect(map['latitude'], -3.1190);
      expect(map['longitude'], -60.0217);
      expect(map['speed'], 12.5);
      expect(map['altitude'], 15.0);
      expect(map['accuracy'], 5.0);
      expect(map['bearing'], 270.0);
      expect(map['timestamp'], 1700000000000);
      expect(map['userType'], 'passageiro');
      expect(map['userName'], 'João Silva');
    });

    test('altitude e bearing serializados como null quando ausentes', () {
      final noAlt = LocationModel(
        userId: 'u', tripId: 't',
        latitude: 0, longitude: 0,
        speed: 0, accuracy: 0,
        timestamp: 0, userType: '', userName: '',
      );
      final map = noAlt.toMap();
      expect(map['altitude'], isNull);
      expect(map['bearing'], isNull);
    });
  });

  group('LocationModel.fromMap', () {
    test('Desserializa todos os campos corretamente', () {
      final restored = LocationModel.fromMap(location.toMap());

      expect(restored.userId, location.userId);
      expect(restored.tripId, location.tripId);
      expect(restored.latitude, location.latitude);
      expect(restored.longitude, location.longitude);
      expect(restored.speed, location.speed);
      expect(restored.altitude, location.altitude);
      expect(restored.accuracy, location.accuracy);
      expect(restored.bearing, location.bearing);
      expect(restored.timestamp, location.timestamp);
    });

    test('Aceita valores inteiros para campos double (cast automático)', () {
      final restored = LocationModel.fromMap({
        'userId': 'u', 'tripId': 't',
        'latitude': -3, 'longitude': -60,
        'speed': 10, 'accuracy': 5,
        'timestamp': 0, 'userType': '', 'userName': '',
      });
      expect(restored.latitude, -3.0);
      expect(restored.speed, 10.0);
    });

    test('altitude e bearing nulos quando ausentes no mapa', () {
      final restored = LocationModel.fromMap({
        'userId': 'u', 'tripId': 't',
        'latitude': 0.0, 'longitude': 0.0,
        'speed': 0.0, 'accuracy': 0.0,
        'timestamp': 0, 'userType': '', 'userName': '',
      });
      expect(restored.altitude, isNull);
      expect(restored.bearing, isNull);
    });

    test('boatId padrão string vazia quando ausente', () {
      expect(LocationModel.fromMap({}).boatId, isEmpty);
    });
  });

  group('LocationModel round-trip (toMap → fromMap)', () {
    test('Mantém igualdade após serialização e desserialização', () {
      expect(LocationModel.fromMap(location.toMap()), equals(location));
    });
  });

  group('LocationModel Equatable', () {
    test('Dois modelos idênticos são iguais', () {
      final loc2 = LocationModel(
        userId: 'user-001', tripId: 'trip-001', boatId: 'boat-001',
        latitude: -3.1190, longitude: -60.0217,
        speed: 12.5, altitude: 15.0, accuracy: 5.0, bearing: 270.0,
        timestamp: 1700000000000, userType: 'passageiro', userName: 'João Silva',
      );
      expect(location, equals(loc2));
    });

    test('Modelos com userId diferente não são iguais', () {
      final loc2 = LocationModel(
        userId: 'user-002', tripId: 'trip-001',
        latitude: -3.1190, longitude: -60.0217,
        speed: 12.5, accuracy: 5.0,
        timestamp: 1700000000000, userType: 'passageiro', userName: 'João Silva',
      );
      expect(location, isNot(equals(loc2)));
    });
  });
}
