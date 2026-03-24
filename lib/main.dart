import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notif_analytics/background/firebase_messaging_background.dart';
import 'package:notif_analytics/services/history_service.dart';
import 'package:notif_analytics/services/location_realtime_service.dart';
import 'package:notif_analytics/services/notification_service.dart';
import 'package:notif_analytics/services/workmanager_service.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'pages/home/location_tracking_viewmodel.dart';
import 'pages/notification_history/history_viewmodel.dart';
import 'pages/notification_history/notification_viewmodel.dart';
import 'routes/app_routes.dart';
import 'pages/map/maps_viewmodel.dart';
import 'pages/notification_history/history_view.dart';
import 'pages/map/maps_view.dart';
import 'pages/analytics/analytics_view.dart';
import 'navigation_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e is! FirebaseException || e.code != 'duplicate-app') {
      rethrow; 
    }
  }
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    //alert: false,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final db = DatabaseService();
  await db.init();

  final workManagerService = WorkManagerService();
  await workManagerService.initialize();

  runApp(NotifApp(db: db, workManagerService: workManagerService));
}

class NotifApp extends StatelessWidget {
  final DatabaseService db;
  final WorkManagerService workManagerService;

  const NotifApp({
    super.key,
    required this.db,
    required this.workManagerService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// DATABASE
        Provider<DatabaseService>.value(value: db),
        Provider<WorkManagerService>.value(value: workManagerService),
        Provider<LocationRealtimeService>(
          create: (_) => LocationRealtimeService(),
        ),

        ProxyProvider<DatabaseService, HistoryService>(
          update: (_, database, _) => HistoryService(database),
        ),

        ChangeNotifierProxyProvider<HistoryService, HistoryViewModel>(
          create: (c) => HistoryViewModel(c.read<HistoryService>()),
          update: (_, historyService, previous) =>
              previous ?? HistoryViewModel(historyService),
        ),

        Provider<NotificationService>(create: (_) => NotificationService()),

        ChangeNotifierProxyProvider2<
          NotificationService,
          WorkManagerService,
          NotificationViewModel
        >(
          create: (c) => NotificationViewModel(
            service: c.read<NotificationService>(),
            workManagerService: c.read<WorkManagerService>(),
          ),
          update: (_, notificationService, workManagerService, previous) =>
              previous ??
              NotificationViewModel(
                service: notificationService,
                workManagerService: workManagerService,
              ),
        ),

        ChangeNotifierProvider<MapsViewModel>(create: (_) => MapsViewModel()),
        ChangeNotifierProvider<LocationTrackingViewModel>(
          create: (c) => LocationTrackingViewModel(
            service: c.read<LocationRealtimeService>(),
          ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  StreamSubscription<void>? _notificationShownSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final history = context.read<HistoryViewModel>();
      final notif = context.read<NotificationViewModel>();
      final notificationService = context.read<NotificationService>();

      await history.loadEntries();
      await notif.init();

      _notificationShownSub = notificationService.onNotificationShown.listen((
        _,
      ) {
        if (mounted) context.read<HistoryViewModel>().addEntry();
      });
    });
  }

  @override
  void dispose() {
    _notificationShownSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      routes: {
        AppRoutes.maps: (_) => const MapsView(),
        AppRoutes.analytics: (_) => const AnalyticsView(),
        AppRoutes.history: (_) => const HistoryView(),
      },
    );
  }
}
