// Testes Unitários — RouteModel
//
// Cobre:
//   - toMap() / fromMap() (serialização e desserialização)
//   - Lista de paradas (stops) serializada corretamente
//   - Valores padrão (isFrequent = false, isActive = true)
//   - copyWith()
//   - Igualdade via Equatable
//
// Para executar:
//   flutter test testes/unit_test/models/route_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';

void main() {
  final stopA = StopModel(
    id: 'stop-a',
    name: 'Porto A',
    city: 'Manaus',
    latitude: -3.1190,
    longitude: -60.0217,
    radius: 500,
    type: StopType.porto,
  );

  final stopB = StopModel(
    id: 'stop-b',
    name: 'Porto B',
    city: 'Parintins',
    latitude: -2.6278,
    longitude: -56.7358,
    radius: 500,
    type: StopType.porto,
  );

  final route = RouteModel(
    id: 'route-001',
    name: 'Manaus–Parintins',
    origin: stopA,
    destination: stopB,
    stops: [stopA, stopB],
    estimatedDurationMinutes: 480,
    createdAt: 1700000000000,
  );

  group('RouteModel.toMap', () {
    test('Serializa campos escalares corretamente', () {
      final map = route.toMap();

      expect(map['id'], 'route-001');
      expect(map['name'], 'Manaus–Parintins');
      expect(map['estimatedDurationMinutes'], 480);
      expect(map['isFrequent'], isFalse);
      expect(map['isActive'], isTrue);
      expect(map['createdAt'], 1700000000000);
    });

    test('Serializa origin e destination como mapas aninhados', () {
      final map = route.toMap();

      expect(map['origin'], isA<Map>());
      expect((map['origin'] as Map)['id'], 'stop-a');

      expect(map['destination'], isA<Map>());
      expect((map['destination'] as Map)['id'], 'stop-b');
    });

    test('Serializa lista de stops corretamente', () {
      final stops = route.toMap()['stops'] as List;

      expect(stops, hasLength(2));
      expect(stops[0]['id'], 'stop-a');
      expect(stops[1]['id'], 'stop-b');
    });
  });

  group('RouteModel.fromMap', () {
    test('Desserializa todos os campos corretamente', () {
      final restored = RouteModel.fromMap(route.toMap());

      expect(restored.id, route.id);
      expect(restored.name, route.name);
      expect(restored.estimatedDurationMinutes, route.estimatedDurationMinutes);
      expect(restored.isFrequent, route.isFrequent);
      expect(restored.isActive, route.isActive);
    });

    test('Desserializa origin e destination como StopModel', () {
      final restored = RouteModel.fromMap(route.toMap());

      expect(restored.origin, isA<StopModel>());
      expect(restored.origin.id, 'stop-a');
      expect(restored.destination.id, 'stop-b');
    });

    test('Desserializa lista de stops como List<StopModel>', () {
      final restored = RouteModel.fromMap(route.toMap());

      expect(restored.stops, hasLength(2));
      expect(restored.stops.every((s) => s is StopModel), isTrue);
    });

    test('Lista de stops vazia quando ausente no mapa', () {
      final map = route.toMap()..remove('stops');
      expect(RouteModel.fromMap(map).stops, isEmpty);
    });
  });

  group('RouteModel round-trip (toMap → fromMap)', () {
    test('Mantém igualdade após serialização e desserialização', () {
      expect(RouteModel.fromMap(route.toMap()), equals(route));
    });
  });

  group('RouteModel.copyWith', () {
    test('Altera apenas o campo indicado', () {
      final updated = route.copyWith(name: 'Nova Rota');
      expect(updated.name, 'Nova Rota');
      expect(updated.id, route.id);
    });

    test('isFrequent pode ser alterado para true', () {
      expect(route.copyWith(isFrequent: true).isFrequent, isTrue);
    });
  });

  group('RouteModel Equatable', () {
    test('Dois modelos idênticos são iguais', () {
      final route2 = RouteModel(
        id: 'route-001',
        name: 'Manaus–Parintins',
        origin: stopA,
        destination: stopB,
        stops: [stopA, stopB],
        estimatedDurationMinutes: 480,
        createdAt: 1700000000000,
      );
      expect(route, equals(route2));
    });

    test('Modelos com id diferente não são iguais', () {
      expect(route, isNot(equals(route.copyWith(id: 'route-002'))));
    });
  });
}
