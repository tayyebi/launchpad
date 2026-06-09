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
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task.name);
    _selectedColor = widget.task.color;
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetColors.map((c) {
                final selected = c.value == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.value),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.withAlpha(150), blurRadius: 8)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
      color: _selectedColor,
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
