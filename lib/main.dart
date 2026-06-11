import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app.dart';
import 'core/database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  await WakelockPlus.enable();
  runApp(const LaunchpadApp());
}
