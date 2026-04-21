import 'package:flutter/foundation.dart';

/// Parâmetros necessários para iniciar um rastreamento de viagem.
class TripStartParams {
  final String boatId;
  final String departurePoint;
  final String arrivalPoint;
  final List<String> stops;

  const TripStartParams({
    required this.boatId,
    required this.departurePoint,
    required this.arrivalPoint,
    this.stops = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripStartParams &&
        other.boatId == boatId &&
        other.departurePoint == departurePoint &&
        other.arrivalPoint == arrivalPoint &&
        listEquals(other.stops, stops);
  }

  @override
  int get hashCode => Object.hash(
        boatId,
        departurePoint,
        arrivalPoint,
        Object.hashAll(stops),
      );
}
