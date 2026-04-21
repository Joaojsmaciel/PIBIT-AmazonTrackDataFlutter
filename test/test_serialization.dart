import 'package:flutter_test/flutter_test.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('UserModel serialization and deserialization', () {
      final user = UserModel(
        uid: 'user123',
        email: 'user@example.com',
        fullName: 'John Doe',
        cpf: '12345678909',
        userType: UserType.passageiro,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final map = user.toMap();
      final userFromMap = UserModel.fromMap(map);

      expect(userFromMap.uid, user.uid);
      expect(userFromMap.email, user.email);
      expect(userFromMap.fullName, user.fullName);
      expect(userFromMap.userType, user.userType);
    });

    test('StopModel serialization and deserialization', () {
      final stop = StopModel(
        id: 'stop123',
        name: 'Porto Central',
        city: 'Manaus',
        latitude: -3.1190,
        longitude: -60.0217,
        radius: 500,
        type: StopType.porto,
      );

      final map = stop.toMap();
      final stopFromMap = StopModel.fromMap(map);

      expect(stopFromMap.id, stop.id);
      expect(stopFromMap.name, stop.name);
      expect(stopFromMap.latitude, stop.latitude);
      expect(stopFromMap.type, stop.type);
    });

    test('RouteModel serialization and deserialization', () {
      final stop1 = StopModel(
        id: 'stop1',
        name: 'Porto A',
        city: 'Manaus',
        latitude: -3.1190,
        longitude: -60.0217,
        radius: 500,
        type: StopType.porto,
      );

      final stop2 = StopModel(
        id: 'stop2',
        name: 'Porto B',
        city: 'Manaus',
        latitude: -3.0500,
        longitude: -60.0100,
        radius: 500,
        type: StopType.porto,
      );

      final route = RouteModel(
        id: 'route123',
        name: 'Rota Manaus-Interior',
        origin: stop1,
        destination: stop2,
        stops: [stop1, stop2],
        estimatedDurationMinutes: 120,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final map = route.toMap();
      final routeFromMap = RouteModel.fromMap(map);

      expect(routeFromMap.id, route.id);
      expect(routeFromMap.name, route.name);
      expect(routeFromMap.origin.name, route.origin.name);
    });

    test('LocationModel serialization and deserialization', () {
      final location = LocationModel(
        userId: 'user123',
        tripId: 'trip123',
        latitude: -3.1190,
        longitude: -60.0217,
        speed: 25.5,
        altitude: 100.0,
        accuracy: 5.0,
        bearing: 45.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        userType: 'barqueiro',
        userName: 'João Silva',
      );

      final map = location.toMap();
      final locationFromMap = LocationModel.fromMap(map);

      expect(locationFromMap.userId, location.userId);
      expect(locationFromMap.latitude, location.latitude);
      expect(locationFromMap.speed, location.speed);
      expect(locationFromMap.userName, location.userName);
    });

    test('BoatModel serialization and deserialization', () {
      final boat = BoatModel(
        id: 'boat123',
        ownerId: 'user123',
        ownerName: 'João Silva',
        name: 'Barco 1',
        routes: [],
        capacity: 10,
        type: 'Barco de Linha',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final map = boat.toMap();
      final boatFromMap = BoatModel.fromMap(map);

      expect(boatFromMap.id, boat.id);
      expect(boatFromMap.ownerId, boat.ownerId);
      expect(boatFromMap.name, boat.name);
      expect(boatFromMap.capacity, boat.capacity);
    });
  });
}
