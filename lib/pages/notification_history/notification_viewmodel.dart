import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/notification_service.dart';
import '../../services/workmanager_service.dart';

/// Default delay for the one-off WorkManager reminder (must match [WorkManagerService.registerOneOffReminder]).
const Duration oneOffReminderDelay = Duration(seconds: 10);

/// Hypothetical interval for the periodic WorkManager (must match [WorkManagerService.registerPeriodicReminder]).
const Duration periodicReminderInterval = Duration(minutes: 15);

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({
    required this.service,
    required this.workManagerService,
  });

  final NotificationService service;
  final WorkManagerService workManagerService;

  bool _initialized = false;
  bool get initialized => _initialized;

  DateTime? _oneOffScheduledAt;
  DateTime? _localScheduledEndAt;
  DateTime? _periodicNextAt;

  /// Remaining time until the one-off (10s) reminder fires
  Duration? get oneOffRemaining {
    if (_oneOffScheduledAt == null) return null;
    final remaining = oneOffReminderDelay - (DateTime.now().difference(_oneOffScheduledAt!));
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Remaining time until the local scheduled notification (e.g. 1 min) fires. Null if not scheduled or expired.
  Duration? get localScheduledRemaining {
    if (_localScheduledEndAt == null) return null;
    final remaining = _localScheduledEndAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Hypothetical remaining time until "next" periodic run (15 min). Null if not initialized.
  Duration? get periodicRemaining {
    if (_periodicNextAt == null) return null;
    final remaining = _periodicNextAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void clearOneOffTimer() {
    _oneOffScheduledAt = null;
    notifyListeners();
  }

  void clearLocalTimer() {
    _localScheduledEndAt = null;
    notifyListeners();
  }

  void refreshPeriodicCountdown() {
    _periodicNextAt = DateTime.now().add(periodicReminderInterval);
    notifyListeners();
  }

  Future<void> init() async {
    await service.initPerm();
    await service.init();
    service.listenToMessages(_onMessageReceived);
    await workManagerService.registerPeriodicReminder();
    _periodicNextAt = DateTime.now().add(periodicReminderInterval);

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

    await service.sendNotification(null);
    notifyListeners();
  }

  Future<void> scheduleLocal({
    required int id,
    required String title,
    required String body,
    required Duration DelayTime,
  }) async {
    await service.initPerm();
    await service.scheduleNotification(
      id: id,
      title: title,
      body: body,
      DelayTime: DelayTime,
    );
    _localScheduledEndAt = DateTime.now().add(DelayTime);
    notifyListeners();
  }

  Future<void> triggerOneOffBackgroundReminder() async {
    await workManagerService.registerOneOffReminder();
    _oneOffScheduledAt = DateTime.now();
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
