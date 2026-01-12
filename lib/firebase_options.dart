import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567',
    appId: '1:123456789012:web:abcdef123456789',
    messagingSenderId: '123456789012',
    projectId: 'martyr-system-app',
    authDomain: 'martyr-system-app.firebaseapp.com',
    storageBucket: 'martyr-system-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567',
    appId: '1:123456789012:android:abcdef123456789',
    messagingSenderId: '123456789012',
    projectId: 'martyr-system-app',
    storageBucket: 'martyr-system-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567',
    appId: '1:123456789012:ios:abcdef123456789',
    messagingSenderId: '123456789012',
    projectId: 'martyr-system-app',
    storageBucket: 'martyr-system-app.appspot.com',
    iosBundleId: 'com.example.martyrSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567',
    appId: '1:123456789012:macos:abcdef123456789',
    messagingSenderId: '123456789012',
    projectId: 'martyr-system-app',
    storageBucket: 'martyr-system-app.appspot.com',
    iosBundleId: 'com.example.martyrSystem',
  );
}