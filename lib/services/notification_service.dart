import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _notificationShownController = StreamController<void>.broadcast();

  /// Emits when a notification is shown (e.g. send or FCM). ViewModels can listen to update history.
  Stream<void> get onNotificationShown => _notificationShownController.stream;

  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  late PermissionStatus permStatus;
  bool _timezoneReady = false;
  String? _fcmToken;

  final NotificationDetails details = NotificationDetails(
    android: AndroidNotificationDetails(
      'notif_channel',
      'Notifications',
      channelDescription: 'App notifications',
      importance: Importance.high,
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
    await _plugin
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

    await _initTimezone();
    _fcmToken = await FirebaseMessaging.instance.getToken();
    getToken();
    await _plugin.initialize(settings);
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  Future<String?> getToken() async {
    _fcmToken ??= await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $_fcmToken');
    return _fcmToken;
  }

  Future<void> sendNotification(RemoteMessage? message) async {
    if (permStatus.isDenied) {
      await requestPermission();
      return;
    }

    final notif = message?.notification;
    final id = notif?.hashCode ?? 0;
    final title = notif?.title ?? 'Default Null Notification';
    final body = notif?.body ?? 'Sent from app';
    await _plugin.show(id, title, body, details);
    _notificationShownController.add(null);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration DelayTime,
  }) async {
    if (permStatus.isDenied) {
      await requestPermission();
      return;
    }

    await _initTimezone();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(DelayTime),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelScheduled(int id) => _plugin.cancel(id);

  Future<void> cancelAllScheduled() => _plugin.cancelAll();

  void listenToMessages(Future<void> Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  Future<void> _initTimezone() async {
    if (_timezoneReady) return;
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    _timezoneReady = true;
  }
}
