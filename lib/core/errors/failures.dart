abstract class Failure {
  final String message;
  final String? code;

  Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class FirebaseAuthFailure extends Failure {
  FirebaseAuthFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class FirestoreFailure extends Failure {
  FirestoreFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class StorageFailure extends Failure {
  StorageFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class LocationFailure extends Failure {
  LocationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class ValidationFailure extends Failure {
  ValidationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  NetworkFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class LocalDatabaseFailure extends Failure {
  LocalDatabaseFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class UnknownFailure extends Failure {
  UnknownFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}
