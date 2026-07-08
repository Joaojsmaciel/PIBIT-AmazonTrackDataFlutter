class ScheduledTrip {
  final String id;
  final String boatId;
  final String boatName;
  final String ownerId;
  final String ownerName;
  final String departurePoint;
  final String arrivalPoint;
  final List<String> stops;
  final int departureDateMs;
  final int? estimatedArrivalMs;
  final int? availableSeats;
  final String notes;
  final bool isCancelled;
  final int createdAt;

  const ScheduledTrip({
    required this.id,
    required this.boatId,
    required this.boatName,
    required this.ownerId,
    required this.ownerName,
    required this.departurePoint,
    required this.arrivalPoint,
    this.stops = const [],
    required this.departureDateMs,
    this.estimatedArrivalMs,
    this.availableSeats,
    this.notes = '',
    this.isCancelled = false,
    required this.createdAt,
  });

  DateTime get departureDate =>
      DateTime.fromMillisecondsSinceEpoch(departureDateMs);

  DateTime? get estimatedArrival => estimatedArrivalMs != null
      ? DateTime.fromMillisecondsSinceEpoch(estimatedArrivalMs!)
      : null;

  bool get isUpcoming =>
      departureDateMs > DateTime.now().millisecondsSinceEpoch && !isCancelled;

  Map<String, dynamic> toMap() => {
        'id': id,
        'boatId': boatId,
        'boatName': boatName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'departurePoint': departurePoint,
        'arrivalPoint': arrivalPoint,
        'stops': stops,
        'departureDateMs': departureDateMs,
        'estimatedArrivalMs': estimatedArrivalMs,
        'availableSeats': availableSeats,
        'notes': notes,
        'isCancelled': isCancelled,
        'createdAt': createdAt,
      };

  factory ScheduledTrip.fromMap(String id, Map<String, dynamic> map) =>
      ScheduledTrip(
        id: id,
        boatId: map['boatId'] as String? ?? '',
        boatName: map['boatName'] as String? ?? '',
        ownerId: map['ownerId'] as String? ?? '',
        ownerName: map['ownerName'] as String? ?? '',
        departurePoint: map['departurePoint'] as String? ?? '',
        arrivalPoint: map['arrivalPoint'] as String? ?? '',
        stops: List<String>.from(map['stops'] as List? ?? []),
        departureDateMs: map['departureDateMs'] as int? ?? 0,
        estimatedArrivalMs: map['estimatedArrivalMs'] as int?,
        availableSeats: map['availableSeats'] as int?,
        notes: map['notes'] as String? ?? '',
        isCancelled: map['isCancelled'] as bool? ?? false,
        createdAt: map['createdAt'] as int? ?? 0,
      );
}
