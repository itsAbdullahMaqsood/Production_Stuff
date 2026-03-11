import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notif_analytics/viewmodels/notification_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  late PermissionStatus permStatus;

  final _notificationShownController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationShown =>
      _notificationShownController.stream;

  final NotificationDetails details = NotificationDetails(
    android: AndroidNotificationDetails(
      'notif_channel',
      'Notifications',
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: false,
    ),
    iOS: DarwinNotificationDetails(
      presentSound: false,
      presentBadge: true,
      presentAlert: true,
    ),
  );

  Future<void> initPerm() async {
    permStatus = await Permission.notification.status;
  }

  Future<void> init() async {
    _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await FirebaseMessaging.instance.getToken();
    await _plugin.initialize(settings);
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  Future<String?> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: $token');
    return token;
  }

  Future<void> sendNotification(RemoteMessage? message) async {
    if (permStatus.isDenied) {
      await requestPermission();
      return;
    }

    final notif = message?.notification;

    await _plugin.show(notif.hashCode, notif?.title, notif?.body, details);

    if (message != null) {
      _notificationShownController.add(message);
    }
  }

  void listenToMessages(Future<void> Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}
