import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../data/models/task.dart';

class WidgetService {
  static Future<void> updateWidget({
    required List<Task> tasks,
    String? activeTaskId,
  }) async {
    final data = tasks.map((t) => {
      'id': t.id,
      'name': t.name,
      'color': t.color,
      'isActive': t.id == activeTaskId,
    }).toList();

    await HomeWidget.saveWidgetData('launchpad_tasks', jsonEncode(data));
    await HomeWidget.updateWidget(
      android: AndroidWidget(
        name: 'LaunchpadWidgetProvider',
      ),
    );
  }
}
