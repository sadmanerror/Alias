// File generated for alias-messaging-app
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.windows:
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDsU5GSVWKQCtktniUSAqhRjDQj69owCeQ',
    appId: '1:679075084081:android:412acacb5e698f16c9e210',
    messagingSenderId: '679075084081',
    projectId: 'alias-messaging-app',
    authDomain: 'alias-messaging-app.firebaseapp.com',
    storageBucket: 'alias-messaging-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsU5GSVWKQCtktniUSAqhRjDQj69owCeQ',
    appId: '1:679075084081:android:412acacb5e698f16c9e210',
    messagingSenderId: '679075084081',
    projectId: 'alias-messaging-app',
    storageBucket: 'alias-messaging-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsU5GSVWKQCtktniUSAqhRjDQj69owCeQ',
    appId: '1:679075084081:android:412acacb5e698f16c9e210',
    messagingSenderId: '679075084081',
    projectId: 'alias-messaging-app',
    storageBucket: 'alias-messaging-app.firebasestorage.app',
    iosBundleId: 'com.piyal.alias',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDsU5GSVWKQCtktniUSAqhRjDQj69owCeQ',
    appId: '1:679075084081:android:412acacb5e698f16c9e210',
    messagingSenderId: '679075084081',
    projectId: 'alias-messaging-app',
    authDomain: 'alias-messaging-app.firebaseapp.com',
    storageBucket: 'alias-messaging-app.firebasestorage.app',
  );
}
