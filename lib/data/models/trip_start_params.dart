import 'package:flutter/foundation.dart';

/// Parâmetros necessários para iniciar um rastreamento de viagem.
class TripStartParams {
  final String boatId;
  final String departurePoint;
  final String arrivalPoint;
  final List<String> stops;
  final int estimatedDurationMinutes;
  final double? originLatitude;
  final double? originLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;

  const TripStartParams({
    required this.boatId,
    required this.departurePoint,
    required this.arrivalPoint,
    this.stops = const [],
    this.estimatedDurationMinutes = 0,
    this.originLatitude,
    this.originLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripStartParams &&
        other.boatId == boatId &&
        other.departurePoint == departurePoint &&
        other.arrivalPoint == arrivalPoint &&
        listEquals(other.stops, stops) &&
        other.estimatedDurationMinutes == estimatedDurationMinutes &&
        other.originLatitude == originLatitude &&
        other.originLongitude == originLongitude &&
        other.destinationLatitude == destinationLatitude &&
        other.destinationLongitude == destinationLongitude;
  }

  @override
  int get hashCode => Object.hash(
        boatId,
        departurePoint,
        arrivalPoint,
        Object.hashAll(stops),
        estimatedDurationMinutes,
        originLatitude,
        originLongitude,
        destinationLatitude,
        destinationLongitude,
      );
}
