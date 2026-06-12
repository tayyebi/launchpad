import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../data/models/task.dart';
import 'widget_renderer.dart';

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
    await WidgetRenderer.renderAndSave(
      tasks: tasks,
      activeTaskName: activeTaskName,
    );
    await HomeWidget.updateWidget(name: 'LaunchpadWidgetProvider');
  }
}
