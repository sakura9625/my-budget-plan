import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyAmzuPd7awSRHvD94enUv5DmgNAbztgvxw',
    appId:             '1:432311315711:web:PLACEHOLDER',
    messagingSenderId: '432311315711',
    projectId:         'my-budget-plan-7dd10',
    storageBucket:     'my-budget-plan-7dd10.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyAmzuPd7awSRHvD94enUv5DmgNAbztgvxw',
    appId:             '1:432311315711:ios:b52759d1a97fc88ab770ca',
    messagingSenderId: '432311315711',
    projectId:         'my-budget-plan-7dd10',
    storageBucket:     'my-budget-plan-7dd10.firebasestorage.app',
    iosBundleId:       'com.sakura9625.mybudgetplan',
  );
}
