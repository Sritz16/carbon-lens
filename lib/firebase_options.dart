import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // 1. Check if running on Web FIRST
    if (kIsWeb) {
      return web;
    }
    // 2. Otherwise check mobile platforms
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  // ---------------------------------------------------------
  // 👇 PASTE YOUR WEB CONFIG HERE (FROM FIREBASE CONSOLE) 👇

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2Gv_k4xPKmMuFBS_OtFRBkHIyne18ts8',
    appId: '1:312487021634:web:05acf4582305ee88a831db',
    messagingSenderId: '312487021634',
    projectId: 'carbon-shadow-tracker-db297',
    authDomain: 'carbon-shadow-tracker-db297.firebaseapp.com',
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
    measurementId: 'G-F7EWBT4WTY',
  );

  // ---------------------------------------------------------

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKhhQHdi3m4QyO3K7upkdCHFcMRY9R4i0',
    appId: '1:312487021634:android:c1fb41ae10ebc597a831db',
    messagingSenderId: '312487021634',
    projectId: 'carbon-shadow-tracker-db297',
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
  );

  // ---------------------------------------------------------
  // 👇 IOS CONFIG (KEEP THIS AS IS) 👇

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCF7p1BsPTJXsP5ml_BupyRUweAur_kHgE',
    appId: '1:312487021634:ios:ddd7fdb3d1b4f9c4a831db',
    messagingSenderId: '312487021634',
    projectId: 'carbon-shadow-tracker-db297',
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
    iosBundleId: 'com.example.carbonshadowtracker',
  );

  // ---------------------------------------------------------

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCF7p1BsPTJXsP5ml_BupyRUweAur_kHgE',
    appId: '1:312487021634:ios:ddd7fdb3d1b4f9c4a831db',
    messagingSenderId: '312487021634',
    projectId: 'carbon-shadow-tracker-db297',
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
    iosBundleId: 'com.example.carbonshadowtracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB2Gv_k4xPKmMuFBS_OtFRBkHIyne18ts8',
    appId: '1:312487021634:web:15a85c2de499147ba831db',
    messagingSenderId: '312487021634',
    projectId: 'carbon-shadow-tracker-db297',
    authDomain: 'carbon-shadow-tracker-db297.firebaseapp.com',
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
    measurementId: 'G-5RZ1QX03W3',
  );

}