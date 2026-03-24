import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

const String workManagerOneOff = 'one_off_reminder';
const String workManagerPeriodic = 'periodic_reminder';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await plugin.initialize(settings);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'notif_channel_background',
        'Background Notifications',
        channelDescription: 'Background task notifications',
        importance: Importance.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (taskName == workManagerOneOff ||
        taskName == Workmanager.iOSBackgroundTask) {
      await plugin.show(
        0,
        'One Off Reminder',
        'WorkManager ran in the background.',
        details,
      );
    }

    if (taskName == workManagerPeriodic ||
        taskName == Workmanager.iOSBackgroundTask) {
      await plugin.show(
        0,
        'Periodic Reminder',
        'WorkManager ran in the background.',
        details,
      );
    }

    return Future.value(true);
  });
}
