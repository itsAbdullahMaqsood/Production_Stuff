import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notif_analytics/background/firebase_messaging_background.dart';
import 'package:notif_analytics/config/app_flavor.dart';
import 'package:notif_analytics/services/history_service.dart';
import 'package:notif_analytics/services/location_service.dart';
import 'package:notif_analytics/services/notification_service.dart';
import 'package:notif_analytics/services/workmanager_service.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'pages/notification_history/history_viewmodel.dart';
import 'navigation_screen.dart';
import 'routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background/firbase_location_background.dart';

Future<void> bootstrap({required AppFlavor flavor}) async {
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
  await initBackgroundService();
  final workManagerService = WorkManagerService();
  await workManagerService.initialize();

  runApp(
    NotifApp(
      db: db,
      workManagerService: workManagerService,
      flavor: flavor,
    ),
  );
}

class NotifApp extends StatelessWidget {
  final DatabaseService db;
  final WorkManagerService workManagerService;
  final AppFlavor flavor;

  const NotifApp({
    super.key,
    required this.db,
    required this.workManagerService,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: db),
        Provider<WorkManagerService>.value(value: workManagerService),
        Provider<LocationRealtimeService>(
          create: (_) => LocationRealtimeService(),
        ),

        ProxyProvider<DatabaseService, HistoryService>(
          update: (_, database, _) => HistoryService(database),
        ),

        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MyApp(flavor: flavor),
    );
  }
}

class MyApp extends StatefulWidget {
  final AppFlavor flavor;

  const MyApp({super.key, required this.flavor});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  StreamSubscription<void>? _notificationShownSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationService = context.read<NotificationService>();
      if (await FlutterBackgroundService().isRunning()) {
        FlutterBackgroundService().invoke('stop');
      }

      _notificationShownSub = notificationService.onNotificationShown.listen((
        _,
      ) {
        if (!mounted) return;
        final historyVm = context.read<HistoryViewModel?>();
        historyVm?.addEntry();
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
      builder: (context, child) {
        if (!widget.flavor.showBanner || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Banner(
          location: BannerLocation.topStart,
          message: widget.flavor.bannerLabel,
          color: widget.flavor == AppFlavor.development
              ? Colors.orange
              : Colors.blue,
          child: child,
        );
      },
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
      initialRoute: MainScreen.route,
      onGenerateRoute: generateRoute,
    );
  }
}
