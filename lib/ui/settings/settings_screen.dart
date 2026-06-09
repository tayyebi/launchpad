import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../data/repositories/task_repository.dart';
import '../launchpad/task_config_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Grid Size',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '${settings.gridSize} × ${settings.gridSize}',
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
                    label: '${settings.gridSize}',
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).setGridSize(v.round());
                    },
                  ),
                  Text(
                    '${settings.gridSize * settings.gridSize} slots total',
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
                      const Text('Tasks',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => _addTask(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  tasksAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return const Text('No tasks',
                            style: TextStyle(color: Colors.white54));
                      }
                      return Column(
                        children: tasks.map((task) {
                          final active = ref.watch(timerProvider).activeTaskId == task.id;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(task.color),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            title: Text(task.name),
                            subtitle: active
                                ? const Text('Active',
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
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final selectedColor = ValueNotifier<int>(0xFF4CAF50);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: selectedColor,
              builder: (context, color, _) {
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2196F3),
                    const Color(0xFFFF5722),
                    const Color(0xFF9C27B0),
                    const Color(0xFFFFC107),
                    const Color(0xFFE91E63),
                    const Color(0xFF00BCD4),
                    const Color(0xFFFF9800),
                  ].map((c) {
                    final sel = c.value == color;
                    return GestureDetector(
                      onTap: () => selectedColor.value = c.value,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: sel
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: sel
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final repo = ref.read(taskRepositoryProvider);
      await repo.create(
        name: nameCtrl.text.trim(),
        color: selectedColor.value,
      );
      ref.invalidate(tasksProvider);
    }
    nameCtrl.dispose();
  }
}
