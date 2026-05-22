import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sportify_amateur/firebase_options.dart';

/// Handler FCM con app en segundo plano o cerrada (obligatorio top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    'FCM background: ${message.notification?.title ?? message.data['title']}',
  );
}
