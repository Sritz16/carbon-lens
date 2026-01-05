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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // ---------------------------------------------------------
  // 👇 PASTE YOUR WEB CONFIG HERE (FROM FIREBASE CONSOLE) 👇
  // ---------------------------------------------------------
  static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyB2Gv_k4xPKmMuFBS_OtFRBkHIyne18ts8",
  authDomain: "carbon-shadow-tracker-db297.firebaseapp.com",
  projectId: "carbon-shadow-tracker-db297",
  storageBucket: "carbon-shadow-tracker-db297.firebasestorage.app",
  messagingSenderId: "312487021634",
  appId: "1:312487021634:web:8bca056f80bb195da831db",
  measurementId: "G-FC481W2R8T"
);

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2Gv_k4xPKmMuFBS_OtFRBkHIyne18ts8', 
    appId: '1:312487021634:android:c1fb41ae10ebc597a831db', 
    messagingSenderId: '312487021634', 
    projectId: 'carbon-shadow-tracker-db297', 
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
  );

  // ---------------------------------------------------------
  // 👇 IOS CONFIG (KEEP THIS AS IS) 👇
  // ---------------------------------------------------------
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'carbon-shadow-tracker',
    storageBucket: 'carbon-shadow-tracker.appspot.com',
    iosBundleId: 'com.example.carbonshadowtracker',
  );
}