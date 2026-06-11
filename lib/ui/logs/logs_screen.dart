import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, ref),
          ),
        ],
      ),
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
          final taskMap = {for (final t in tasks) t.name: t};

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
                    final task = taskMap[e.taskName];
                    final clr = task != null ? colorFromInt(task.color) : colorFromInt(colorFromName(e.taskName));
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
                          e.taskName,
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

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final entries = await ref.read(allEntriesProvider.future);

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries to export')),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Date,Start,End,Duration (seconds),Task');

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
        subject: 'Launchpad Logs',
      );
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
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
