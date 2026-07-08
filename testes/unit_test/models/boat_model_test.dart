// Testes Unitários — BoatModel
//
// Cobre:
//   - toMap() / fromMap() (serialização e desserialização)
//   - Campos opcionais (photoUrl, capacity)
//   - Listas routes e routeCities
//   - Valores padrão (routeCities = [], isActive = true)
//   - copyWith()
//   - Igualdade via Equatable
//
// Para executar:
//   flutter test testes/unit_test/models/boat_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';

void main() {
  final boat = BoatModel(
    id: 'boat-001',
    ownerId: 'user-001',
    ownerName: 'Carlos Barqueiro',
    name: 'Barco Veloz',
    routes: ['route-001', 'route-002'],
    routeCities: ['Manaus', 'Parintins'],
    capacity: 50,
    type: 'Lancha',
    createdAt: 1700000000000,
  );

  group('BoatModel.toMap', () {
    test('Serializa todos os campos corretamente', () {
      final map = boat.toMap();

      expect(map['id'], 'boat-001');
      expect(map['ownerId'], 'user-001');
      expect(map['ownerName'], 'Carlos Barqueiro');
      expect(map['name'], 'Barco Veloz');
      expect(map['routes'], ['route-001', 'route-002']);
      expect(map['routeCities'], ['Manaus', 'Parintins']);
      expect(map['capacity'], 50);
      expect(map['type'], 'Lancha');
      expect(map['isActive'], isTrue);
    });

    test('photoUrl serializado como null quando não fornecido', () {
      expect(boat.toMap()['photoUrl'], isNull);
    });

    test('photoUrl serializado quando fornecido', () {
      final withPhoto = boat.copyWith(photoUrl: 'https://img.example.com/boat.jpg');
      expect(withPhoto.toMap()['photoUrl'], 'https://img.example.com/boat.jpg');
    });
  });

  group('BoatModel.fromMap', () {
    test('Desserializa todos os campos corretamente', () {
      final restored = BoatModel.fromMap(boat.toMap());

      expect(restored.id, boat.id);
      expect(restored.ownerId, boat.ownerId);
      expect(restored.ownerName, boat.ownerName);
      expect(restored.name, boat.name);
      expect(restored.routes, boat.routes);
      expect(restored.routeCities, boat.routeCities);
      expect(restored.capacity, boat.capacity);
      expect(restored.type, boat.type);
      expect(restored.isActive, boat.isActive);
    });

    test('Listas routes e routeCities vazias quando ausentes no mapa', () {
      final restored = BoatModel.fromMap({
        'id': 'x',
        'ownerId': 'y',
        'ownerName': 'Z',
        'name': 'W',
        'type': 'T',
        'createdAt': 0,
      });
      expect(restored.routes, isEmpty);
      expect(restored.routeCities, isEmpty);
    });

    test('capacity pode ser null', () {
      final map = boat.toMap()..['capacity'] = null;
      final restored = BoatModel.fromMap(map);
      expect(restored.capacity, isNull);
    });

    test('isActive padrão true quando ausente', () {
      final restored = BoatModel.fromMap({});
      expect(restored.isActive, isTrue);
    });
  });

  group('BoatModel round-trip (toMap → fromMap)', () {
    test('Mantém igualdade após serialização e desserialização', () {
      expect(BoatModel.fromMap(boat.toMap()), equals(boat));
    });
  });

  group('BoatModel.copyWith', () {
    test('Altera apenas o campo indicado', () {
      final updated = boat.copyWith(name: 'Barco Rápido');
      expect(updated.name, 'Barco Rápido');
      expect(updated.id, boat.id);
    });

    test('isActive pode ser alterado para false', () {
      final inactive = boat.copyWith(isActive: false);
      expect(inactive.isActive, isFalse);
    });
  });

  group('BoatModel Equatable', () {
    test('Dois modelos idênticos são iguais', () {
      final boat2 = BoatModel(
        id: 'boat-001',
        ownerId: 'user-001',
        ownerName: 'Carlos Barqueiro',
        name: 'Barco Veloz',
        routes: ['route-001', 'route-002'],
        routeCities: ['Manaus', 'Parintins'],
        capacity: 50,
        type: 'Lancha',
        createdAt: 1700000000000,
      );
      expect(boat, equals(boat2));
    });

    test('Modelos com id diferente não são iguais', () {
      expect(boat, isNot(equals(boat.copyWith(id: 'boat-002'))));
    });
  });
}
