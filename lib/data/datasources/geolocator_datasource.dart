import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

class GeolocatorDatasource {
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<Position> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      throw LocationFailure(
        message: 'Erro ao obter posição atual',
      );
    }
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      final permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await requestPermission();
        if (newPermission == LocationPermission.denied) {
          return null;
        }
      }

      final position = await getCurrentPosition();
      return LocationModel(
        userId: '',
        userName: '',
        userType: '',
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
        altitude: position.altitude,
        bearing: position.heading,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        tripId: '',
      );
    } catch (e) {
      return null;
    }
  }

  Stream<Position> getPositionStream({
    int intervalSeconds = 5,
  }) {
    try {
      final LocationSettings settings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: Duration(seconds: intervalSeconds),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );
      } else {
        settings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      }
      return Geolocator.getPositionStream(locationSettings: settings);
    } catch (e) {
      throw LocationFailure(
        message: 'Erro ao obter fluxo de posição',
      );
    }
  }
}
