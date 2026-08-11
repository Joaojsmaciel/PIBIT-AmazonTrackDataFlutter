class ActiveTrackingSession {
  final String userId;
  final String tripId;
  final String boatId;
  final String userName;
  final String userType;
  final String departurePoint;
  final String arrivalPoint;
  final List<String> stops;

  const ActiveTrackingSession({
    required this.userId,
    required this.tripId,
    required this.boatId,
    required this.userName,
    required this.userType,
    this.departurePoint = '',
    this.arrivalPoint = '',
    this.stops = const [],
  });
}
