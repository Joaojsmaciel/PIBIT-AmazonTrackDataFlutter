class TripSummary {
  final String tripId;
  final String userId;
  final String userName;
  final String boatId;
  final int startTimestamp;
  final int endTimestamp;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final int pointCount;
  final String departurePoint;
  final String arrivalPoint;
  final List<String> stops;

  /// Velocidade média em m/s (geolocator retorna m/s)
  final double avgSpeedMs;

  /// Distância total em metros
  final double totalDistanceMeters;

  const TripSummary({
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.boatId,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.pointCount,
    required this.avgSpeedMs,
    required this.totalDistanceMeters,
    this.departurePoint = '',
    this.arrivalPoint = '',
    this.stops = const [],
  });

  Duration get duration =>
      Duration(milliseconds: endTimestamp - startTimestamp);

  /// Velocidade média em km/h
  double get avgSpeedKmh => avgSpeedMs * 3.6;

  /// Distância total em km
  double get totalDistanceKm => totalDistanceMeters / 1000;

  DateTime get startDate =>
      DateTime.fromMillisecondsSinceEpoch(startTimestamp);

  DateTime get endDate =>
      DateTime.fromMillisecondsSinceEpoch(endTimestamp);
}
