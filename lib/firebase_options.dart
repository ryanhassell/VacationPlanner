//this is an auto generated firebase file
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAkNa-eJIN0whGKh-KXuqGMtOeCTJ8qGzY',
    appId: 'your-web-app-id',
    messagingSenderId: 'your-web-messaging-sender-id',
    projectId: 'vacation-698a8',
    storageBucket: 'your-web-storage-bucket',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAkNa-eJIN0whGKh-KXuqGMtOeCTJ8qGzY',
    appId: '1:677967319643:android:ee18c54d3c3c8bc719657e',
    messagingSenderId: '677967319643',
    projectId: 'vacation-698a8',
    storageBucket: 'vacation-698a8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: 'your-ios-app-id',
    messagingSenderId: 'your-ios-messaging-sender-id',
    projectId: 'vacation-698a8',
    storageBucket: 'your-ios-storage-bucket',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: 'your-macos-app-id',
    messagingSenderId: 'your-macos-messaging-sender-id',
    projectId: 'vacation-698a8',
    storageBucket: 'your-macos-storage-bucket',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-windows-api-key',
    appId: 'your-windows-app-id',
    messagingSenderId: 'your-windows-messaging-sender-id',
    projectId: 'vacation-698a8',
    storageBucket: 'your-windows-storage-bucket',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'your-linux-api-key',
    appId: 'your-linux-app-id',
    messagingSenderId: 'your-linux-messaging-sender-id',
    projectId: 'vacation-698a8',
    storageBucket: 'your-linux-storage-bucket',
  );
}