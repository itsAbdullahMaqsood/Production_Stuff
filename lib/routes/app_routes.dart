import 'package:flutter/material.dart';
import 'package:notif_analytics/pages/home/home_view.dart';
import 'package:notif_analytics/pages/home/home_location_tracking_viewmodel.dart';
import 'package:notif_analytics/navigation_screen.dart';
import 'package:notif_analytics/pages/notification_history/history_viewmodel.dart';
import 'package:notif_analytics/pages/notification_history/notification_viewmodel.dart';
import 'package:notif_analytics/services/history_service.dart';
import 'package:notif_analytics/services/location_service.dart';
import 'package:notif_analytics/services/notification_service.dart';
import 'package:notif_analytics/services/workmanager_service.dart';
import 'package:provider/provider.dart';
import 'package:notif_analytics/pages/map/maps_viewmodel.dart';
import 'package:notif_analytics/pages/map/maps_view.dart';
import 'package:notif_analytics/pages/analytics/analytics_view.dart';
import 'package:notif_analytics/pages/notification_history/notification_history_view.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name as String) {
    case MainScreen.route:
      return MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeLocationTrackingViewModel>(
              create: (_) => HomeLocationTrackingViewModel(
                service: LocationRealtimeService(),
              ),
            ),
            ChangeNotifierProvider<MapsViewModel>(create: (_) => MapsViewModel()),
            ChangeNotifierProxyProvider<HistoryService, HistoryViewModel>(
              create: (ctx) {
                final vm = HistoryViewModel(ctx.read<HistoryService>());
                vm.loadEntries();
                return vm;
              },
              update: (_, historyService, previous) =>
                  previous ?? HistoryViewModel(historyService),
            ),
            ChangeNotifierProxyProvider2<
              NotificationService,
              WorkManagerService,
              NotificationViewModel
            >(
              create: (ctx) => NotificationViewModel(
                service: ctx.read<NotificationService>(),
                workManagerService: ctx.read<WorkManagerService>(),
              )..init(),
              update: (_, notificationService, workManagerService, previous) =>
                  previous ??
                  NotificationViewModel(
                    service: notificationService,
                    workManagerService: workManagerService,
                  ),
            ),
          ],
          child: const MainScreen(),
        ),
      );

    case HomeView.route:
      return MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeLocationTrackingViewModel>(
              create: (_) => HomeLocationTrackingViewModel(
                service: LocationRealtimeService(),
              ),
            ),
          ],
          child: const HomeView(),
        ),
      );

    case MapsView.route:
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => MapsViewModel(),
          child: const MapsView(),
        ),
      );

    case AnalyticsView.route:
      return MaterialPageRoute(builder: (context) => const AnalyticsView());

    case NotificationHistoryView.route:
      return MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProxyProvider<HistoryService, HistoryViewModel>(
              create: (ctx) {
                final vm = HistoryViewModel(ctx.read<HistoryService>());
                vm.loadEntries();
                return vm;
              },
              update: (_, historyService, previous) =>
                  previous ?? HistoryViewModel(historyService),
            ),

            ChangeNotifierProxyProvider2<
              NotificationService,
              WorkManagerService,
              NotificationViewModel
            >(
              create: (c) => NotificationViewModel(
                service: c.read<NotificationService>(),
                workManagerService: c.read<WorkManagerService>(),
              )..init(),
              update: (_, notificationService, workManagerService, previous) =>
                  previous ??
                  NotificationViewModel(
                    service: notificationService,
                    workManagerService: workManagerService,
                  ),
            ),
          ],
          child: const NotificationHistoryView(),
        ),
      );

    default:
      return MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route not found')),
            body: const Center(child: Text('Error Page 404')),
          );
        },
      );
  }
}
