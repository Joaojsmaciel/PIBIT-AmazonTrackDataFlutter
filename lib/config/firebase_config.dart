import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Substitua com seu project ID do Firebase
  static const String projectId = 'amazon-track-data';
  
  // URLs e endpoints
  static const String firestoreEmulator = 'localhost:8080';
  static const String storageEmulator = 'localhost:9199';
}
