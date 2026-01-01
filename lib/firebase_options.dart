import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2Gv_k4xPKmMuFBS_OtFRBkHIyne18ts8', 
    
    // 👇 2. PASTE YOUR APP ID HERE (From "Your Apps" section)
    appId: '1:312487021634:android:c1fb41ae10ebc597a831db', 
    
    messagingSenderId: '312487021634', 
    
    // 👇 I FIXED THIS FOR YOU (Based on your screenshot)
    projectId: 'carbon-shadow-tracker-db297', 
    storageBucket: 'carbon-shadow-tracker-db297.firebasestorage.app',
  );
}