import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../../main.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'promarket_alerts_channel';
  static const String _channelName = 'ProMarket Alerts';
  static const String _channelDescription =
      'Order, message, and promotional alerts from ProMarket';
  static const String _androidSoundName = 'promarket_ping';
  static const String _iosSoundName = 'promarket_ping.wav';

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('Skipping FCM initialization on web (unsupported native setup)');
      return;
    }

    // 1. Initialize Local Notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _localNotifications.initialize(initializationSettings);
    await _ensureAndroidChannel();

    // 2. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      _showLocalNotification(message);
      
      // Save notification to Firestore if user is logged in
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .add({
            'title': message.notification?.title ?? 'New Message',
            'body': message.notification?.body ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': message.data['type'] ?? 'system',
            'data': message.data,
          });
        } catch (e) {
          debugPrint('Error saving notification: $e');
        }
      }

      // Global Snackbar via Navigation Key
      ProMarketApp.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'New Message'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.primaryIndigo,
          action: SnackBarAction(
            label: 'View', 
            textColor: Colors.white, 
            onPressed: () {
              // Navigation logic can be added here
            }
          ),
        ),
      );
    });

    // 3. Handle Background/Terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Keep FCM token synced for signed-in users.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _persistFcmToken(newToken);
    });
  }

  static Future<void> requestPermissionOnceForUser(String userId) async {
    if (kIsWeb || userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_permission_requested_v2_$userId';
    final alreadyRequested = prefs.getBool(key) == true;

    if (alreadyRequested) {
      final existing = await _fcm.getNotificationSettings();
      final existingAuthorized =
          existing.authorizationStatus == AuthorizationStatus.authorized ||
              existing.authorizationStatus == AuthorizationStatus.provisional;
      if (existingAuthorized) {
        final token = await _fcm.getToken();
        await _persistFcmToken(token);
      }
      return;
    }

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await prefs.setBool(key, true);

    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'notificationsEnabled': authorized,
        'notificationPermissionStatus': settings.authorizationStatus.name,
        'notificationPermissionRequestedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not persist notification permission state: $e');
    }

    if (authorized) {
      final token = await _fcm.getToken();
      await _persistFcmToken(token);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_androidSoundName),
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _iosSoundName,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinDetails,
    );
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

  static Future<void> _persistFcmToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not persist FCM token: $e');
    }
  }

  static Future<void> _ensureAndroidChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_androidSoundName),
      ),
    );
  }
}
