import 'dart:convert';

/// Representa um ponto de localização capturado localmente para sincronização
/// offline. Cada ponto contém todos os dados necessários para reconstituir
/// o evento de rastreamento quando a conectividade for restaurada.
class LocalLocationPoint {
  /// Identificador único gerado localmente (UUID ou timestamp-based).
  final String id;

  final double latitude;
  final double longitude;

  /// Velocidade em metros por segundo.
  final double velocidade;

  final DateTime timestamp;

  /// Indica se o ponto já foi sincronizado com o servidor.
  bool sincronizado;

  final String userId;
  final String tripId;
  final String boatId;

  LocalLocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.velocidade,
    required this.timestamp,
    this.sincronizado = false,
    this.userId = '',
    this.tripId = '',
    this.boatId = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'velocidade': velocidade,
        'timestamp': timestamp.toIso8601String(),
        'sincronizado': sincronizado,
        'userId': userId,
        'tripId': tripId,
        'boatId': boatId,
      };

  factory LocalLocationPoint.fromJson(Map<String, dynamic> json) {
    return LocalLocationPoint(
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      velocidade: (json['velocidade'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sincronizado: json['sincronizado'] as bool? ?? false,
      userId: json['userId'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      boatId: json['boatId'] as String? ?? '',
    );
  }

  String toJsonString() => json.encode(toJson());

  factory LocalLocationPoint.fromJsonString(String source) =>
      LocalLocationPoint.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'LocalLocationPoint(id: $id, lat: $latitude, lon: $longitude, '
      'vel: ${velocidade.toStringAsFixed(1)} m/s, sync: $sincronizado, '
      'ts: ${timestamp.toIso8601String()})';
}
