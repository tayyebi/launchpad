import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/entry_providers.dart';
import '../../providers/task_providers.dart';
import '../../core/utils/color_utils.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allEntriesProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('No entries yet', style: TextStyle(color: Colors.white54)),
            );
          }

          final tasks = tasksAsync.whenOrNull(data: (t) => t) ?? [];
          final taskMap = {for (final t in tasks) t.id: t};

          final grouped = <String, List<MapEntry<int, dynamic>>>{};
          for (int i = 0; i < entries.length; i++) {
            final e = entries[i];
            final dayKey = DateFormat('yyyy-MM-dd').format(e.startTime);
            grouped.putIfAbsent(dayKey, () => []);
            grouped[dayKey]!.add(MapEntry(i, e));
          }

          final dateFormat = DateFormat('MMM d, yyyy');
          final timeFormat = DateFormat('HH:mm');

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: grouped.entries.length,
            itemBuilder: (context, index) {
              final dayEntry = grouped.entries.elementAt(index);
              final date = DateTime.parse(dayEntry.key);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Text(
                      isToday ? 'Today' : dateFormat.format(date),
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...dayEntry.value.map((entry) {
                    final e = entry.value;
                    final task = taskMap[e.taskId];
                    final clr = task != null ? colorFromInt(task.color) : Colors.grey;
                    final durStr = e.durationSeconds != null
                        ? _formatDuration(e.durationSeconds!)
                        : '--:--';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: clr.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: clr.withAlpha(60)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: clr,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(
                          task?.name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${timeFormat.format(e.startTime)} - '
                          '${e.endTime != null ? timeFormat.format(e.endTime!) : 'running'}',
                          style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
                        ),
                        trailing: Text(
                          durStr,
                          style: TextStyle(
                            color: e.isActive ? Colors.greenAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
