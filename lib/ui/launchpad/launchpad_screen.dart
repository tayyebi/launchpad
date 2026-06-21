import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../core/l10n/strings.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/entry_providers.dart';
import '../../data/repositories/task_repository.dart';
import '../../services/widget_service.dart';
import '../settings/settings_screen.dart';
import '../summary/summary_screen.dart';
import 'launchpad_tile.dart';

class LaunchpadScreen extends ConsumerWidget {
  const LaunchpadScreen({super.key});

  String _formatElapsed(Duration d) => PersianUtils.formatDuration(d);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final gridSize = settings.gridSize;
    final dailySummaryAsync = ref.watch(dailySummaryProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final topPad = isLandscape ? 8.0 : 48.0;
          final sidePad = isLandscape ? 48.0 : 12.0;

          return tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${Strings.error}: $e')),
            data: (tasks) {
              final dailySummary =
                  dailySummaryAsync.whenOrNull(data: (d) => d) ?? {};
              final showDaily = gridSize <= 3;

              if (tasks.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: topPad),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize,
                            size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(Strings.noTasksYet,
                            style: TextStyle(
                                color: Colors.white54, fontSize: 18)),
                      ],
                    ),
                  ),
                );
              }

              final tiles = gridSize * gridSize;
              final children = <Widget>[];

              for (int i = 0; i < tiles; i++) {
                if (i < tasks.length) {
                  final task = tasks[i];
                  final isActive = timerState.activeTaskNames.contains(task.name);
                  final elapsed = isActive
                      ? _formatElapsed(
                          timerState.elapsedByTask[task.name] ?? Duration.zero)
                      : null;
                  final dailyTotal = dailySummary[task.name] ?? 0;

                  children.add(LaunchpadTile(
                    key: ValueKey(task.name),
                    name: task.name,
                    color: task.color,
                    isActive: isActive,
                    elapsed: elapsed,
                    dailyTotal: showDaily ? dailyTotal : null,
                    onTap: () =>
                        ref.read(timerProvider.notifier).toggleTask(task.name),
                  ));
                } else {
                  children.add(Container(
                    key: ValueKey('empty_$i'),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(20),
                        style: BorderStyle.solid,
                      ),
                    ),
                  ));
                }
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(sidePad, topPad, sidePad, 12),
                child: ReorderableGridView.count(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: children,
                  onReorder: (int oldIndex, int newIndex) async {
                    if (oldIndex == newIndex) return;
                    final task = tasks[oldIndex];
                    final reordered = [...tasks];
                    reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, task);

                    final repo = ref.read(taskRepositoryProvider);
                    final positions = reordered.asMap().entries
                        .map((e) => MapEntry(e.value.name, e.key))
                        .toList();
                    await repo.updateGridPositions(positions);
                    ref.invalidate(tasksProvider);

                    final updatedTasks =
                        await ref.read(tasksProvider.future);
                    WidgetService.updateWidget(
                      tasks: updatedTasks,
                      activeTaskName: timerState.activeTaskNames.isNotEmpty
                          ? timerState.activeTaskNames.first
                          : null,
                      gridSize: gridSize,
                    );
                  },
                ),
              );
            },
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
                    tooltip: Strings.summary,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SummaryScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: Strings.settings,
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
