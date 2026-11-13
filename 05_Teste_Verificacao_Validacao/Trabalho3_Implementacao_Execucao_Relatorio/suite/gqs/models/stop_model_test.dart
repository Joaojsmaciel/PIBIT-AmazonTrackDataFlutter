// Testes Unitários — StopModel
//
// Cobre:
//   - toMap() / fromMap() (serialização e desserialização)
//   - Valor padrão state = 'AM'
//   - copyWith()
//   - Igualdade via Equatable (props)
//   - Enum StopType (porto, terminal, comunidade, cidade, outro)
//
// Para executar:
//   flutter test testes/unit_test/models/stop_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';

void main() {
  final stop = StopModel(
    id: 'stop-001',
    name: 'Porto Central',
    city: 'Manaus',
    latitude: -3.1190,
    longitude: -60.0217,
    radius: 500,
    type: StopType.porto,
    createdAt: 1700000000000,
  );

  group('StopModel.toMap', () {
    test('Serializa todos os campos corretamente', () {
      final map = stop.toMap();

      expect(map['id'], 'stop-001');
      expect(map['name'], 'Porto Central');
      expect(map['city'], 'Manaus');
      expect(map['state'], 'AM');
      expect(map['latitude'], -3.1190);
      expect(map['longitude'], -60.0217);
      expect(map['radius'], 500.0);
      expect(map['type'], 'porto');
      expect(map['createdAt'], 1700000000000);
    });

    test('Serializa cada StopType como string do nome do enum', () {
      for (final type in StopType.values) {
        final model = stop.copyWith(type: type);
        expect(model.toMap()['type'], type.name);
      }
    });
  });

  group('StopModel.fromMap', () {
    test('Desserializa todos os campos corretamente', () {
      final restored = StopModel.fromMap(stop.toMap());

      expect(restored.id, stop.id);
      expect(restored.name, stop.name);
      expect(restored.city, stop.city);
      expect(restored.state, stop.state);
      expect(restored.latitude, stop.latitude);
      expect(restored.longitude, stop.longitude);
      expect(restored.radius, stop.radius);
      expect(restored.type, stop.type);
    });

    test('Usa valor padrão "AM" para state quando ausente', () {
      final restored = StopModel.fromMap({
        'id': 'x', 'name': 'Y', 'city': 'Z',
        'latitude': 0.0, 'longitude': 0.0,
        'radius': 100.0, 'type': 'outro',
      });
      expect(restored.state, 'AM');
    });

    test('Usa radius 500.0 quando ausente no mapa', () {
      expect(StopModel.fromMap({'type': 'porto'}).radius, 500.0);
    });

    test('Interpreta type desconhecido como StopType.outro', () {
      expect(StopModel.fromMap({'type': 'xyz'}).type, StopType.outro);
    });

    test('latitude e longitude aceitam int no mapa (cast para double)', () {
      final restored = StopModel.fromMap({
        'latitude': -3, 'longitude': -60,
        'type': 'porto', 'radius': 500,
      });
      expect(restored.latitude, -3.0);
      expect(restored.longitude, -60.0);
    });
  });

  group('StopModel round-trip (toMap → fromMap)', () {
    test('Mantém igualdade após serialização e desserialização', () {
      expect(StopModel.fromMap(stop.toMap()), equals(stop));
    });
  });

  group('StopModel.copyWith', () {
    test('Altera apenas o campo indicado', () {
      final updated = stop.copyWith(name: 'Porto Norte');
      expect(updated.name, 'Porto Norte');
      expect(updated.id, stop.id);
      expect(updated.type, stop.type);
    });
  });

  group('StopModel Equatable', () {
    test('Dois modelos idênticos são iguais', () {
      final stop2 = StopModel(
        id: 'stop-001',
        name: 'Porto Central',
        city: 'Manaus',
        latitude: -3.1190,
        longitude: -60.0217,
        radius: 500,
        type: StopType.porto,
        createdAt: 1700000000000,
      );
      expect(stop, equals(stop2));
    });

    test('Modelos com id diferente não são iguais', () {
      expect(stop, isNot(equals(stop.copyWith(id: 'stop-002'))));
    });
  });
}
