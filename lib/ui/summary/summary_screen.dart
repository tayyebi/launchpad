import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../core/utils/color_utils.dart';


class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _weeklyView = false;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final result = snapshot.data as _SummaryData?;
          final hasChartData = !loading && result != null && result.chartData.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!hasChartData)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('No data for this period',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  )
                else ...[
                  const SizedBox(height: 24),
                  const Text('Time per Task',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildBarChart(result.chartData)),
                ],
                const SizedBox(height: 24),
                const Text('Logs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                if (result != null) ..._buildLogs(result.entries),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    final fmt = DateFormat(_weeklyView ? 'MMM d' : 'MMM d, yyyy');
    final label = _weeklyView
        ? 'Week of ${fmt.format(_selectedDate)}'
        : fmt.format(_selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedDate = _weeklyView
                  ? _selectedDate.subtract(const Duration(days: 7))
                  : _selectedDate.subtract(const Duration(days: 1));
            });
          },
        ),
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _selectedDate = _weeklyView
                  ? _selectedDate.add(const Duration(days: 7))
                  : _selectedDate.add(const Duration(days: 1));
            });
          },
        ),
      ],
    );
  }

  Future<_SummaryData> _loadData() async {
    final entryRepo = EntryRepository();
    final taskRepo = TaskRepository();
    final tasks = await taskRepo.getActiveTasks();
    final taskMap = {for (final t in tasks) t.name: t};

    Map<String, int> raw;
    DateTime rangeStart, rangeEnd;

    if (_weeklyView) {
      rangeStart =
          _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      rangeEnd = rangeStart.add(const Duration(days: 7));
      raw = await entryRepo.getWeeklySummary(rangeStart);
    } else {
      rangeStart =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      rangeEnd = rangeStart.add(const Duration(days: 1));
      raw = await entryRepo.getDailySummary(_selectedDate);
    }

    final chartData = <_ChartData>[];
    for (final entry in raw.entries) {
      final task = taskMap[entry.key];
      if (task != null) {
        chartData.add(_ChartData(
          task.name,
          entry.value.toDouble(),
          colorFromInt(task.color),
        ));
      }
    }
    chartData.sort((a, b) => b.value.compareTo(a.value));

    final entries = await entryRepo.getEntriesInRange(rangeStart, rangeEnd);

    return _SummaryData(chartData: chartData, entries: entries);
  }

  List<Widget> _buildLogs(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text('No entries for this period',
                style: TextStyle(color: Colors.white54)),
          ),
        ),
      ];
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      final startTime = DateTime.parse(e['start_time'] as String);
      final dayKey = DateFormat('yyyy-MM-dd').format(startTime);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(e);
    }

    final widgets = <Widget>[];
    for (final dayEntry in grouped.entries) {
      final date = DateTime.parse(dayEntry.key);
      final isToday = DateUtils.isSameDay(date, DateTime.now());

      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          isToday ? 'Today' : dateFormat.format(date),
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ));

      for (final e in dayEntry.value) {
        final entryId = e['id'] as String;
        final taskName = e['task_name'] as String? ?? 'Unknown';
        final taskColor = colorFromInt(colorFromName(taskName));
        final startTime = DateTime.parse(e['start_time'] as String);
        final endTimeStr = e['end_time'] as String?;
        final endTime =
            endTimeStr != null ? DateTime.parse(endTimeStr) : null;
        final durationSeconds = e['duration_seconds'] as int?;

        final durStr = durationSeconds != null
            ? _formatDuration(durationSeconds)
            : '--:--';

        widgets.add(Dismissible(
          key: Key(entryId),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {
            DismissDirection.endToStart: 0.2,
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerRight,
            child: Container(
              width: 70,
              height: double.infinity,
              alignment: Alignment.center,
              child: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
          confirmDismiss: (direction) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Entry'),
                content: Text('Delete this entry for "$taskName"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              final repo = EntryRepository();
              await repo.deleteEntry(entryId);
              setState(() {});
              return true;
            }
            return false;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: taskColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: taskColor.withAlpha(60)),
            ),
            child: ListTile(
              leading: Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: taskColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(taskName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${timeFormat.format(startTime)} - '
                '${endTime != null ? timeFormat.format(endTime) : 'running'}',
                style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
              ),
              trailing: Text(
                durStr,
                style: TextStyle(
                  color: endTime == null ? Colors.greenAccent : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ));
      }
    }

    return widgets;
  }

  Widget _buildBarChart(List<_ChartData> data) {
    final maxY = data.fold(0.0, (m, d) => d.value > m ? d.value : m);
    final chartMaxY = maxY * 1.2;
    final midY = chartMaxY / 2;
    const leftMargin = 42.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = constraints.maxWidth - leftMargin;
        final n = data.length;

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[groupIndex].label}\n${_formatDuration(rod.toY.round())}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: leftMargin,
                        interval: midY,
                        getTitlesWidget: (value, meta) {
                          if (value == midY || value == chartMaxY) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                _formatDuration(value.toInt()),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white38),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: midY,
                    checkToShowHorizontalLine: (value) {
                      return value == midY || value == chartMaxY;
                    },
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white24,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: entry.value.color,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              ...data.asMap().entries.map((entry) {
                final centerX =
                    leftMargin + plotWidth * (2 * entry.key + 1) / (2 * n);
                final labelWidth = plotWidth / n;
                final barHeightRatio = entry.value.value / chartMaxY;
                final barHeight = barHeightRatio * constraints.maxHeight;
                final showInside = barHeight > 18;

                return Positioned(
                  left: centerX - labelWidth / 2,
                  top: showInside
                      ? constraints.maxHeight - barHeight + 4
                      : constraints.maxHeight - barHeight - 14,
                  width: labelWidth,
                  child: Text(
                    entry.value.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: showInside
                          ? Colors.white.withAlpha(200)
                          : Colors.white70,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _SummaryData {
  final List<_ChartData> chartData;
  final List<Map<String, dynamic>> entries;

  const _SummaryData({
    required this.chartData,
    required this.entries,
  });
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  const _ChartData(this.label, this.value, this.color);
}
