import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/strings.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../services/widget_service.dart';

class TaskConfigDialog extends ConsumerStatefulWidget {
  final Task task;

  const TaskConfigDialog({super.key, required this.task});

  @override
  ConsumerState<TaskConfigDialog> createState() => _TaskConfigDialogState();
}

class _TaskConfigDialogState extends ConsumerState<TaskConfigDialog> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.configureTask),
      content: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          labelText: Strings.taskName,
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => _deleteTask(context),
          child: Text(Strings.delete, style: const TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text(Strings.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    final oldName = widget.task.name;
    if (oldName != name) {
      await repo.update(oldName, name);
    }
    ref.invalidate(tasksProvider);
    final tasks = await ref.read(tasksProvider.future);
    WidgetService.updateWidget(tasks: tasks);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteTask(BuildContext context) async {
    final timerState = ref.read(timerProvider);
    if (timerState.activeTaskNames.contains(widget.task.name)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(Strings.cannotDeleteRunningTask),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.deleteTask),
        content: Text(Strings.deleteTaskConfirm(widget.task.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(Strings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
          child: Text(Strings.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(taskRepositoryProvider);
      await repo.delete(widget.task.name);
      ref.invalidate(tasksProvider);
      final tasks = await ref.read(tasksProvider.future);
      WidgetService.updateWidget(tasks: tasks);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
