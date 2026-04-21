import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYw8XnJCbYUXwdt7sZRcppVxELOvKROhQ',
    appId: '1:414477644661:web:placeholder',
    messagingSenderId: '414477644661',
    projectId: 'fir-capdex',
    authDomain: 'fir-capdex.firebaseapp.com',
    storageBucket: 'fir-capdex.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYw8XnJCbYUXwdt7sZRcppVxELOvKROhQ',
    appId: '1:414477644661:android:c646aefc777f384268593c',
    messagingSenderId: '414477644661',
    projectId: 'fir-capdex',
    storageBucket: 'fir-capdex.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYw8XnJCbYUXwdt7sZRcppVxELOvKROhQ',
    appId: '1:414477644661:ios:placeholder',
    messagingSenderId: '414477644661',
    projectId: 'fir-capdex',
    storageBucket: 'fir-capdex.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBYw8XnJCbYUXwdt7sZRcppVxELOvKROhQ',
    appId: '1:414477644661:macos:placeholder',
    messagingSenderId: '414477644661',
    projectId: 'fir-capdex',
    storageBucket: 'fir-capdex.firebasestorage.app',
  );
}
