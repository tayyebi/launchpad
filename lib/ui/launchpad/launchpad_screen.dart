import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/settings_screen.dart';
import '../logs/logs_screen.dart';
import '../summary/summary_screen.dart';
import 'launchpad_tile.dart';
import 'task_config_dialog.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launchpad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Logs',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Summary',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No tasks yet', style: TextStyle(color: Colors.white54, fontSize: 18)),
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

                final isActive = timerState.activeTaskId == task.id;
                final elapsed = isActive ? _formatElapsed(timerState.elapsed) : null;

                return LaunchpadTile(
                  name: task.name,
                  color: task.color,
                  isActive: isActive,
                  elapsed: elapsed,
                  onTap: () => ref.read(timerProvider.notifier).toggleTask(task.id),
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (_) => TaskConfigDialog(task: task),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
