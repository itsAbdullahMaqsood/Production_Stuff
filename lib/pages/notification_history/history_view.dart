import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'history_viewmodel.dart';
import '../../widgets/history_tile.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          Consumer<HistoryViewModel>(
            builder: (context, history, _) {
              if (history.count == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<HistoryViewModel>().clearAll(),
                child: Text('Clear', style: TextStyle(color: colors.error)),
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryViewModel>(
        builder: (context, history, _) {
          if (history.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: colors.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing sent yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            );
          }

          final reversed = history.entries.reversed.toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: reversed.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return HistoryTile(
                entry: reversed[index],
                index: reversed.length - index,
              );
            },
          );
        },
      ),
    );
  }
}
