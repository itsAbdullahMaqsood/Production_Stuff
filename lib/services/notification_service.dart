import 'dart:core';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final Future<void> Function() onNotificationShown;

  NotificationService({required this.onNotificationShown});

  final _plugin = FlutterLocalNotificationsPlugin();
  late PermissionStatus permStatus;

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
    await onNotificationShown();
  }

  void listenToMessages(Future<void> Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}
