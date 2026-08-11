import 'package:equatable/equatable.dart';
import 'stop_model.dart';

class RouteModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final StopModel origin;
  final StopModel destination;
  final List<StopModel> stops;
  final int estimatedDurationMinutes;
  final bool isFrequent;
  final int createdAt;
  final bool isActive;

  const RouteModel({
    required this.id,
    this.ownerId = '',
    required this.name,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.estimatedDurationMinutes,
    this.isFrequent = false,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'stops': stops.map((s) => s.toMap()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isFrequent': isFrequent,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      origin: StopModel.fromMap(map['origin'] ?? {}),
      destination: StopModel.fromMap(map['destination'] ?? {}),
      stops: List<StopModel>.from(
        (map['stops'] as List?)?.map((s) => StopModel.fromMap(s)) ?? [],
      ),
      estimatedDurationMinutes: map['estimatedDurationMinutes'] ?? 0,
      isFrequent: map['isFrequent'] ?? false,
      createdAt: map['createdAt'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  RouteModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    StopModel? origin,
    StopModel? destination,
    List<StopModel>? stops,
    int? estimatedDurationMinutes,
    bool? isFrequent,
    int? createdAt,
    bool? isActive,
  }) {
    return RouteModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      stops: stops ?? this.stops,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isFrequent: isFrequent ?? this.isFrequent,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    origin,
    destination,
    stops,
    estimatedDurationMinutes,
    isFrequent,
    createdAt,
    isActive,
  ];
}
