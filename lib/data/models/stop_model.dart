import 'package:equatable/equatable.dart';

enum StopType { porto, terminal, comunidade, cidade, outro }

class StopModel extends Equatable {
  final String id;
  final String name;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final double radius;
  final StopType type;
  final int? createdAt;

  const StopModel({
    required this.id,
    required this.name,
    required this.city,
    this.state = 'AM',
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.type,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'type': type.name,
      'createdAt': createdAt,
    };
  }

  factory StopModel.fromMap(Map<String, dynamic> map) {
    return StopModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? 'AM',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: (map['radius'] as num?)?.toDouble() ?? 500.0,
      type: StopType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StopType.outro,
      ),
      createdAt: map['createdAt'],
    );
  }

  StopModel copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    double? radius,
    StopType? type,
    int? createdAt,
  }) {
    return StopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, city, state, latitude, longitude, radius, type, createdAt];
}
