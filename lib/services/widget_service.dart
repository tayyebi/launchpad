import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../data/models/task.dart';

class WidgetService {
  static Future<void> updateWidget({
    required List<Task> tasks,
    String? activeTaskName,
  }) async {
    final data = tasks.map((t) => {
      'name': t.name,
      'color': t.color,
      'isActive': t.name == activeTaskName,
    }).toList();

    await HomeWidget.saveWidgetData('launchpad_tasks', jsonEncode(data));
    await HomeWidget.updateWidget(name: 'LaunchpadWidgetProvider');
  }
}
