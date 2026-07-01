import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/l10n/strings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_providers.dart';
import '../../providers/timer_provider.dart';
import '../../providers/entry_providers.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task.dart';
import '../../core/utils/color_utils.dart';
import '../../services/widget_service.dart';
import '../launchpad/task_config_dialog.dart';

class _GlidingListTile extends StatefulWidget {
  final Task task;
  final bool isActive;
  final bool shouldGlide;
  final VoidCallback onEdit;

  const _GlidingListTile({
    required this.task,
    required this.isActive,
    required this.shouldGlide,
    required this.onEdit,
  });

  @override
  State<_GlidingListTile> createState() => _GlidingListTileState();
}

class _GlidingListTileState extends State<_GlidingListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnim = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(
        parent: _slideCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    if (widget.shouldGlide) {
      _slideCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GlidingListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldGlide && !oldWidget.shouldGlide) {
      _slideCtrl.repeat(reverse: true);
    } else if (!widget.shouldGlide && oldWidget.shouldGlide) {
      _slideCtrl.stop();
      _slideCtrl.reset();
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnim.value, 0),
          child: child,
        );
      },
      child: ListTile(
        dense: true,
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorFromInt(widget.task.color),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(widget.task.name),
        subtitle: widget.isActive
            ? const Text(Strings.active,
                style: TextStyle(color: Colors.greenAccent))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: widget.onEdit,
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int? _glideTaskIndex;

  @override
  void initState() {
    super.initState();
    _glideTaskIndex = null;
  }

  void _pickGlideTask(List<Task> tasks) {
    if (_glideTaskIndex != null) return;
    if (tasks.length >= 3) {
      _glideTaskIndex = Random().nextInt(3);
    } else if (tasks.isNotEmpty) {
      _glideTaskIndex = Random().nextInt(tasks.length);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: SwitchListTile(
              title: const Text(Strings.multitasking),
              subtitle: Text(Strings.multitaskingDesc(maxConcurrentTasks)),
              value: settings.multitaskingEnabled,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setMultitasking(v);
              },
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
                        onPressed: () => _addTask(context),
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
                      _pickGlideTask(tasks);
                      return Column(
                        children: tasks.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final task = entry.value;
                          final active = ref.watch(timerProvider).activeTaskNames.contains(task.name);
                          return _GlidingListTile(
                            task: task,
                            isActive: active,
                            shouldGlide: idx == _glideTaskIndex,
                            onEdit: () => showDialog(
                              context: context,
                              builder: (_) => TaskConfigDialog(task: task),
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
              leading: const Icon(Icons.file_download),
              title: const Text(Strings.viewLogs),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _exportCsv(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final entries = await ref.read(allEntriesProvider.future);

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.noEntriesToExport)),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('تاریخ,شروع,پایان,مدت (ثانیه),وظیفه');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final e in entries) {
      final date = dateFormat.format(e.startTime);
      final start = timeFormat.format(e.startTime);
      final end = e.endTime != null ? timeFormat.format(e.endTime!) : '';
      final dur = e.durationSeconds?.toString() ?? '';
      final task = _escapeCsv(e.taskName);
      buffer.writeln('$date,$start,$end,$dur,$task');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/launchpad_logs.csv');
    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'گزارش‌های Launchpad',
      );
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _addTask(BuildContext context) async {
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
