import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:notif_analytics/pages/home/home_view.dart';
import 'package:notif_analytics/pages/notification_history/history_viewmodel.dart';
import 'package:notif_analytics/pages/notification_history/notification_viewmodel.dart';
import 'package:notif_analytics/services/notification_service.dart';
import 'package:notif_analytics/services/workmanager_service.dart';

void main() {
  testWidgets('HomeView renders with providers', (WidgetTester tester) async {
    // final notifService = NotificationService(onNotificationShown: () async {});
    final workManagerService = WorkManagerService();

    // await tester.pumpWidget(
    //   // MultiProvider(
    //   //   // providers: [
    //   //   //   ChangeNotifierProvider<HistoryViewModel>(
    //   //   //     create: (_) => HistoryViewModel(null),
    //   //   //   ),
    //   //   //   ChangeNotifierProvider<NotificationViewModel>(
    //   //   //     // create: (_) => NotificationViewModel(
    //   //   //       // service: notifService,
    //   //   //       workManagerService: workManagerService,
    //   //   //     ),
    //   //   //   ),
    //   //   // ],
    //   //   child: const MaterialApp(home: HomeView()),
    //   // ),
    // );

    expect(find.text('Notifier'), findsOneWidget);
    expect(find.text('Send Notification'), findsOneWidget);
    expect(find.text('Schedule to send after 1 minute'), findsOneWidget);
    expect(find.text('Trigger background task (10s)'), findsOneWidget);
    expect(find.text('Debug: list background tasks'), findsOneWidget);
  });
}
