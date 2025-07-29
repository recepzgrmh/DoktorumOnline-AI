import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _printToken();
    _setupTokenRefreshListener();
    _setupForegroundMessageListener();
    _setupOnMessageOpenedApp();
  }

  Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission();
  }

  Future<void> _printToken() async {
    final token = await _firebaseMessaging.getToken();
    debugPrint("📱 FCM Token: $token");
  }

  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("🔁 Token refreshed: $newToken");
    });
  }

  /// 🔔 Foreground mesajları yerel bildirimle göster
  void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = notification?.android;

      if (notification != null && android != null) {
        _showLocalNotification(notification.title, notification.body);
      }
    });
  }

  /// 🔄 Bildirime tıklanınca yapılacaklar
  void _setupOnMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📲 Bildirime tıklandı: ${message.notification?.title}");
    });
  }

  /// 📍 Yerel bildirim başlat
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(initSettings);
  }

  /// 📤 Yerel bildirim göster
  Future<void> _showLocalNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Genel Bildirimler',
      channelDescription: 'Uygulama içi bildirimler',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(0, title, body, notificationDetails);
  }
}
