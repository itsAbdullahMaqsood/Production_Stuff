import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService service;

  NotificationViewModel({required this.service});

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init() async {
    await service.initPerm();
    await service.init();

    service.listenToMessages(_onMessageReceived);

    _initialized = true;
    notifyListeners();
  }

  Future<void> checkAndSend() async {
    await service.initPerm();

    if (service.permStatus == PermissionStatus.permanentlyDenied) {
      _isPermanentlyDenied = true;
      notifyListeners();
      return;
    }

    final dummy = RemoteMessage(
      notification: RemoteNotification(title: "No Title", body: "No Body"),
    );

    await service.sendNotification(
      dummy
    );
    notifyListeners();
  }

  bool _isPermanentlyDenied = false;
  bool get isPermanentlyDenied => _isPermanentlyDenied;

  void resetDeniedFlag() {
    _isPermanentlyDenied = false;
    notifyListeners();
  }

  Future<void> _onMessageReceived(RemoteMessage message) async {
    await service.sendNotification(message);
    notifyListeners();
  }

  Future<String?> getToken() => service.getToken();
}
