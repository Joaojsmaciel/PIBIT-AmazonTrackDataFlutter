import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String userId;
  final String tripId;
  final String boatId;
  final double latitude;
  final double longitude;
  final double speed;
  final double? altitude;
  final double accuracy;
  final double? bearing;
  final int timestamp;
  final String userType;
  final String userName;

  const LocationModel({
    required this.userId,
    required this.tripId,
    this.boatId = '',
    required this.latitude,
    required this.longitude,
    required this.speed,
    this.altitude,
    required this.accuracy,
    this.bearing,
    required this.timestamp,
    required this.userType,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tripId': tripId,
      'boatId': boatId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'altitude': altitude,
      'accuracy': accuracy,
      'bearing': bearing,
      'timestamp': timestamp,
      'userType': userType,
      'userName': userName,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      userId: map['userId'] ?? '',
      tripId: map['tripId'] ?? '',
      boatId: map['boatId'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      bearing: (map['bearing'] as num?)?.toDouble(),
      timestamp: map['timestamp'] ?? 0,
      userType: map['userType'] ?? '',
      userName: map['userName'] ?? '',
    );
  }

  LocationModel copyWith({
    String? userId,
    String? tripId,
    double? latitude,
    double? longitude,
    double? speed,
    double? altitude,
    double? accuracy,
    double? bearing,
    int? timestamp,
    String? userType,
    String? userName,
  }) {
    return LocationModel(
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      bearing: bearing ?? this.bearing,
      timestamp: timestamp ?? this.timestamp,
      userType: userType ?? this.userType,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    tripId,
    latitude,
    longitude,
    speed,
    altitude,
    accuracy,
    bearing,
    timestamp,
    userType,
    userName,
  ];
}
