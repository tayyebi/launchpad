import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/color_utils.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../providers/task_providers.dart';

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
      title: const Text('Configure Task'),
      content: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          labelText: 'Task Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => _deleteTask(context),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    await repo.update(widget.task.copyWith(
      name: name,
      color: colorFromName(name),
    ));
    ref.invalidate(tasksProvider);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteTask(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${widget.task.name}" and all its entries?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(taskRepositoryProvider);
      await repo.delete(widget.task.id);
      ref.invalidate(tasksProvider);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
