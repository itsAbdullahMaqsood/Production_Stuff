import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../background/workmanager_handler.dart';

class WorkManagerService {
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  Future<void> registerOneOffReminder({
    Duration initialDelay = const Duration(seconds: 10),
  }) async {
    await Workmanager().registerOneOffTask(
      'one_off_reminder',
      workManagerOneOff,
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> registerPeriodicReminder() async {
    await Workmanager().registerPeriodicTask(
      'periodic_reminder',
      workManagerPeriodic,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }
}
