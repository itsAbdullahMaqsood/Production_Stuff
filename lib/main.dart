import 'package:flutter/material.dart';
import 'package:notif_analytics/services/history_service.dart';
import 'package:notif_analytics/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'viewmodels/history_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'routes/app_routes.dart';
import 'views/history_view.dart';
import 'views/home_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = DatabaseService();
  await db.init();

  runApp(NotifApp(db: db));
}

class NotifApp extends StatelessWidget {
  final DatabaseService db;

  const NotifApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// DATABASE
        Provider<DatabaseService>.value(value: db),

        ProxyProvider<DatabaseService, HistoryService>(
          update: (_, database, __) => HistoryService(database),
        ),

        ChangeNotifierProxyProvider<HistoryService, HistoryViewModel>(
          create: (c) => HistoryViewModel(c.read<HistoryService>()),
          update: (_, historyService, previous) =>
              previous ?? HistoryViewModel(historyService),
        ),

        ProxyProvider<HistoryViewModel, NotificationService>(
          update: (_, historyVm, __) =>
              NotificationService(onNotificationShown: historyVm.addEntry),
        ),

        ChangeNotifierProxyProvider<NotificationService, NotificationViewModel>(
          create: (c) =>
              NotificationViewModel(service: c.read<NotificationService>()),
          update: (_, service, previous) =>
              previous ?? NotificationViewModel(service: service),
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final history = context.read<HistoryViewModel>();
      final notif = context.read<NotificationViewModel>();

      await history.loadEntries();
      await notif.init();
    });
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
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeView(),
        AppRoutes.history: (_) => const HistoryView(),
      },
    );
  }
}
