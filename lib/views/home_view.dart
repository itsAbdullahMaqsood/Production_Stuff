import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../viewmodels/history_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

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
    final notifVm = context.watch<NotificationViewModel>();
    final int count = context.watch<HistoryViewModel>().count;
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (notifVm.isPermanentlyDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermanentlyDeniedDialog(context, notifVm);
      });
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
              onTap: () => Navigator.pushNamed(context, AppRoutes.history),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.history),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text(
                    'Notifs History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
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
  }
}
