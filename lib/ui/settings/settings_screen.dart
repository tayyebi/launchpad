import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/strings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../data/repositories/task_repository.dart';
import '../../core/utils/color_utils.dart';
import '../../services/widget_service.dart';
import '../launchpad/task_config_dialog.dart';
import '../logs/logs_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(Strings.gridSize,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '${PersianUtils.toPersianDigits(settings.gridSize)} × ${PersianUtils.toPersianDigits(settings.gridSize)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: settings.gridSize.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: PersianUtils.toPersianDigits(settings.gridSize),
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).setGridSize(v.round());
                    },
                  ),
                  Text(
                    Strings.slotsCount(settings.gridSize * settings.gridSize),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(Strings.tasks,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => _addTask(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(Strings.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  tasksAsync.when(
                    loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('${Strings.error}: $e'),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return const Text(Strings.noTasks,
                            style: TextStyle(color: Colors.white54));
                      }
                      return Column(
                        children: tasks.map((task) {
                          final active = ref.watch(timerProvider).activeTaskName == task.name;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorFromInt(task.color),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            title: Text(task.name),
                            subtitle: active
                                ? const Text(Strings.active,
                                    style: TextStyle(color: Colors.greenAccent))
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => TaskConfigDialog(task: task),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: const Text(Strings.viewLogs),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.newTask),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: Strings.taskName,
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(Strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(Strings.add),
          ),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final repo = ref.read(taskRepositoryProvider);
      await repo.create(
        name: nameCtrl.text.trim(),
      );
      ref.invalidate(tasksProvider);
      final tasks = await ref.read(tasksProvider.future);
      WidgetService.updateWidget(tasks: tasks);
    }
    nameCtrl.dispose();
  }
}
