import 'package:equatable/equatable.dart';

enum UserType { passageiro, barqueiro }

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String cpf;
  final UserType userType;
  final int createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.cpf,
    required this.userType,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'cpf': cpf,
      'userType': userType.name,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      cpf: map['cpf'] ?? '',
      userType: UserType.values.firstWhere(
        (e) => e.name == map['userType'],
        orElse: () => UserType.passageiro,
      ),
      createdAt: map['createdAt'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? cpf,
    UserType? userType,
    int? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      cpf: cpf ?? this.cpf,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [uid, email, fullName, cpf, userType, createdAt, isActive];
}
