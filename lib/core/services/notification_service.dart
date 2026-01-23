import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../main.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('Skipping FCM initialization on web (unsupported native setup)');
      return;
    }

    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 2. Initialize Local Notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    // 3. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      _showLocalNotification(message);
      
      // Global Snackbar via Navigation Key
      ProMarketApp.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'New Message'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.indigo,
          action: SnackBarAction(label: 'View', textColor: Colors.white, onPressed: () {}),
        ),
      );
    });

    // 4. Handle Background/Terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      0,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Handle background message logic
    debugPrint("Handling a background message: ${message.messageId}");
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
