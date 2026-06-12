import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/task.dart';
import 'widget_renderer.dart';

class WidgetService {
  static Future<void> updateWidget({
    required List<Task> tasks,
    String? activeTaskName,
    int? gridSize,
  }) async {
    if (gridSize == null) {
      final prefs = await SharedPreferences.getInstance();
      gridSize = prefs.getInt('grid_size') ?? 3;
    }

    await WidgetRenderer.renderAndSave(
      tasks: tasks,
      activeTaskName: activeTaskName,
      gridSize: gridSize,
    );
    await HomeWidget.updateWidget(name: 'LaunchpadWidgetProvider');
  }
}
