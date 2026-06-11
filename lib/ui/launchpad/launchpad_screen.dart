import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/entry_providers.dart';
import '../settings/settings_screen.dart';
import '../summary/summary_screen.dart';
import 'launchpad_tile.dart';

class LaunchpadScreen extends ConsumerWidget {
  const LaunchpadScreen({super.key});

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final gridSize = settings.gridSize;
    final dailySummaryAsync = ref.watch(dailySummaryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withAlpha(80),
            ),
          ),
        ),
        title: const Text('Launchpad'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          final dailySummary =
              dailySummaryAsync.whenOrNull(data: (d) => d) ?? {};
          final showDaily = gridSize <= 3;

          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize,
                      size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No tasks yet',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            );
          }

          final tiles = gridSize * gridSize;
          final filled = List.generate(
            tiles,
            (i) => i < tasks.length ? tasks[i] : null,
          );

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tiles,
              itemBuilder: (context, index) {
                final task = filled[index];
                if (task == null) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(20),
                        style: BorderStyle.solid,
                      ),
                    ),
                  );
                }

                final isActive =
                    timerState.activeTaskId == task.id;
                final elapsed = isActive
                    ? _formatElapsed(timerState.elapsed)
                    : null;
                final dailyTotal = dailySummary[task.id] ?? 0;

                return LaunchpadTile(
                  name: task.name,
                  color: task.color,
                  isActive: isActive,
                  elapsed: elapsed,
                  dailyTotal:
                      showDaily ? dailyTotal : null,
                  onTap: () => ref
                      .read(timerProvider.notifier)
                      .toggleTask(task.id),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart),
                    tooltip: 'Summary',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SummaryScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
