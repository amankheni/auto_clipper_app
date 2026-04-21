import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 🔥 Background handler (TOP LEVEL REQUIRED)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔙 Background Message: ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// ✅ INIT (call in main or first screen)
  static Future<void> init() async {
    // 🔹 Firebase background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 🔹 Permission (iOS + Android 13+)
    await _messaging.requestPermission();

    // 🔹 Get FCM Token (optional)
    String? token = await _messaging.getToken();
    debugPrint("🔥 FCM Token: $token");

    // 🔥 Subscribe all users
    await _messaging.subscribeToTopic("all_users");

    // 🔹 Local notification init
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: settings);

    // 🔹 Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground Message: ${message.notification?.title}");

      _showLocalNotification(message);
    });

    // 🔹 Notification click (app open)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("👉 Notification Clicked: ${message.notification?.title}");
    });
  }

  /// 🔔 Show local notification (foreground)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: 0,
      title: message.notification?.title ?? "Notification",
      body: message.notification?.body ?? "",
      notificationDetails: details,
    );
  }
}
