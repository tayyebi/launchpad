import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app.dart';
import 'core/database/database.dart';
import 'data/repositories/task_repository.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  await WakelockPlus.enable();

  final tasks = await TaskRepository().getActiveTasks();
  WidgetService.updateWidget(tasks: tasks);

  runApp(const LaunchpadApp());
}
