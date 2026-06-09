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
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Day')),
              ButtonSegment(value: true, label: Text('Week')),
            ],
            selected: {_weeklyView},
            onSelectionChanged: (v) => setState(() => _weeklyView = v.first),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text('No data for this period',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 24),
                const Text('Time per Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Expanded(flex: 3, child: _buildBarChart(data)),
                const SizedBox(height: 16),
                const Text('Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Expanded(flex: 2, child: _buildPieChart(data)),
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

  Future<List<_ChartData>> _loadData() async {
    final entryRepo = EntryRepository();
    final taskRepo = TaskRepository();
    final tasks = await taskRepo.getActiveTasks();
    final taskMap = {for (final t in tasks) t.id: t};

    Map<String, int> raw;
    if (_weeklyView) {
      final weekStart = _selectedDate.subtract(Duration(
          days: _selectedDate.weekday - 1));
      raw = await entryRepo.getWeeklySummary(weekStart);
    } else {
      raw = await entryRepo.getDailySummary(_selectedDate);
    }

    final data = <_ChartData>[];
    for (final entry in raw.entries) {
      final task = taskMap[entry.key];
      if (task != null) {
        data.add(_ChartData(
          task.name,
          entry.value.toDouble(),
          colorFromInt(task.color),
        ));
      }
    }
    data.sort((a, b) => b.value.compareTo(a.value));
    return data;
  }

  Widget _buildBarChart(List<_ChartData> data) {
    final maxY = data.fold(0.0, (m, d) => d.value > m ? d.value : m);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[idx].label.length > 6
                        ? '${data[idx].label.substring(0, 6)}..'
                        : data[idx].label,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
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
    );
  }

  Widget _buildPieChart(List<_ChartData> data) {
    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((entry) {
          final total = data.fold(0.0, (s, d) => s + d.value);
          final pct = total > 0 ? (entry.value.value / total * 100) : 0.0;
          return PieChartSectionData(
            color: entry.value.color,
            value: entry.value.value,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  const _ChartData(this.label, this.value, this.color);
}
