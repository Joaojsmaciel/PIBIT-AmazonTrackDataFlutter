import 'package:equatable/equatable.dart';

class TrackedUserModel extends Equatable {
  final String userId;
  final String userName;
  final String userType;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final int timestamp;
  final String tripId;
  final String boatId;

  const TrackedUserModel({
    required this.userId,
    required this.userName,
    required this.userType,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
    required this.tripId,
    this.boatId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp,
      'tripId': tripId,
      'boatId': boatId,
    };
  }

  factory TrackedUserModel.fromMap(Map<String, dynamic> map) {
    return TrackedUserModel(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userType: map['userType'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] ?? 0,
      tripId: map['tripId'] ?? '',
      boatId: map['boatId'] ?? '',
    );
  }

  bool isRecent(Duration windowDuration) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp).abs() <= windowDuration.inMilliseconds;
  }

  @override
  List<Object?> get props => [
    userId,
    userName,
    userType,
    latitude,
    longitude,
    speed,
    accuracy,
    timestamp,
    tripId,
    boatId,
  ];
}
