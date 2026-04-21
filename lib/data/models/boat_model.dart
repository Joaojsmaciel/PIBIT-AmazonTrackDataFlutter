import 'package:equatable/equatable.dart';

class BoatModel extends Equatable {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String? photoUrl;
  final List<String> routes; // IDs das rotas
  final List<String> routeCities; // Cidades/pontos da rota (texto livre)
  final int? capacity;
  final String type;
  final int createdAt;
  final bool isActive;

  const BoatModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    this.photoUrl,
    required this.routes,
    this.routeCities = const [],
    this.capacity,
    required this.type,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': name,
      'photoUrl': photoUrl,
      'routes': routes,
      'routeCities': routeCities,
      'capacity': capacity,
      'type': type,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory BoatModel.fromMap(Map<String, dynamic> map) {
    return BoatModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      routes: List<String>.from(map['routes'] as List? ?? []),
      routeCities: List<String>.from(map['routeCities'] as List? ?? []),
      capacity: map['capacity'],
      type: map['type'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  BoatModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? name,
    String? photoUrl,
    List<String>? routes,
    List<String>? routeCities,
    int? capacity,
    String? type,
    int? createdAt,
    bool? isActive,
  }) {
    return BoatModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      routes: routes ?? this.routes,
      routeCities: routeCities ?? this.routeCities,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    ownerName,
    name,
    photoUrl,
    routes,
    routeCities,
    capacity,
    type,
    createdAt,
    isActive,
  ];
}
