import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notif_analytics/pages/notification_history/notification_history_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'home_location_tracking_viewmodel.dart';
import '../notification_history/history_viewmodel.dart';
import '../notification_history/notification_viewmodel.dart';

String _formatRemaining(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  if (minutes > 0) {
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '0:${seconds.toString().padLeft(2, '0')}';
}

class HomeView extends StatefulWidget {
  static const String route = '/home';
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showPermanentlyDeniedDialog(
    BuildContext context,
    NotificationViewModel vm,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications Disabled'),
        content: const Text('Open Settings to re-enable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
    vm.resetDeniedFlag();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      NotificationViewModel?,
      HomeLocationTrackingViewModel?,
      HistoryViewModel?
    >(
      builder: (context, notifVm, locationVm, historyVm, _) {
        final ColorScheme colors = Theme.of(context).colorScheme;

        if (notifVm == null || locationVm == null) {
          return Scaffold(
            backgroundColor: colors.surface,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final int count = historyVm?.count ?? 0;

        if (notifVm.isPermanentlyDenied) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermanentlyDeniedDialog(context, notifVm);
          });
        }

        final oneOff = notifVm.oneOffRemaining;
        final local = notifVm.localScheduledRemaining;
        final periodic = notifVm.periodicRemaining;
        if (oneOff != null && oneOff <= Duration.zero) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => notifVm.clearOneOffTimer(),
          );
        }
        if (local != null && local <= Duration.zero) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => notifVm.clearLocalTimer(),
          );
        }
        if (periodic != null && periodic <= Duration.zero) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => notifVm.refreshPeriodicCountdown(),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: const Text(
              'Notifier',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    NotificationHistoryView.route,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 28,
                        color: colors.onSurface,
                      ),
                      if (count > 0)
                        Positioned(
                          top: 2,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'notification sender',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => notifVm.checkAndSend(),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Send Notification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => locationVm.toggleTracking(),
                      icon: Icon(
                        locationVm.isTracking
                            ? Icons.location_off_rounded
                            : Icons.location_searching_rounded,
                      ),
                      label: Text(
                        locationVm.isTracking
                            ? 'Stop Realtime Location'
                            : 'Start Realtime Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (locationVm.lastError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      locationVm.lastError!,
                      style: TextStyle(fontSize: 13, color: colors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => notifVm.scheduleLocal(
                        id: 42,
                        title: 'Scheduled notification',
                        body: 'This was scheduled 1 minute ago.',
                        DelayTime: const Duration(minutes: 1),
                      ),
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text(
                        'Schedule to send after (Now+1 min)', //using local notifications
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          notifVm.triggerOneOffBackgroundReminder(),
                      icon: const Icon(Icons.timer_rounded),
                      label: const Text(
                        'Schedule to send after 10 secs', //using WorkManager
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "Allow background tracking",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      Spacer(),
                      Switch(
                        value: locationVm.allowTracking,
                        onChanged: (value) =>
                            locationVm.toggleBackgroundTracking(value),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (oneOff != null || local != null || periodic != null) ...[
                    Text(
                      'Scheduled timers',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (oneOff != null)
                      _TimerRow(
                        label: 'One-off (10s)',
                        remaining: oneOff,
                        colors: colors,
                      ),
                    if (local != null)
                      _TimerRow(
                        label: 'Local (1 min)',
                        remaining: local,
                        colors: colors,
                      ),
                    if (periodic != null)
                      _TimerRow(
                        label: 'Periodic (~15 min)',
                        remaining: periodic,
                        colors: colors,
                      ),
                    const SizedBox(height: 20),
                  ],
                  Center(
                    child: Text(
                      count == 0
                          ? 'No notifications yet.'
                          : '$count notification${count == 1 ? '' : 's'} sent this session.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimerRow extends StatelessWidget {
  const _TimerRow({
    required this.label,
    required this.remaining,
    required this.colors,
  });

  final String label;
  final Duration remaining;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            _formatRemaining(remaining),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
