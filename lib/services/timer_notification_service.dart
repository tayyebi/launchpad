import 'dart:io';
import 'package:flutter/services.dart';
import '../core/l10n/strings.dart';

/// Drives the Android foreground service that shows the running task on the
/// lock screen. Failures are swallowed on purpose: the notification is a
/// nicety, and losing it must never interfere with time tracking itself.
class TimerNotificationService {
  static const MethodChannel _channel =
      MethodChannel('ir.lpad.mobile/timer_service');

  /// Shows or updates the ongoing notification. Android ticks the stopwatch
  /// itself from [startTime], so the elapsed time stays correct while the phone
  /// is locked and no Dart code is running.
  ///
  /// A notification supports a single chronometer, so when several tasks run at
  /// once [taskName] carries the live clock and [otherTasks] is listed below it.
  static Future<void> show({
    required String taskName,
    required DateTime startTime,
    List<String> otherTasks = const [],
  }) async {
    if (!Platform.isAndroid) return;
    await _invoke('start', {
      'taskName': taskName,
      'startTimeMillis': startTime.millisecondsSinceEpoch,
      'contentText': otherTasks.isEmpty
          ? Strings.timerRunning
          : Strings.timerAlsoRunning(otherTasks.join('، ')),
      'channelName': Strings.timerChannelName,
    });
  }

  static Future<void> hide() async {
    if (!Platform.isAndroid) return;
    await _invoke('stop', null);
  }

  static Future<void> _invoke(String method, Map<String, dynamic>? args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException {
      // Ignored - see class doc.
    } on MissingPluginException {
      // Ignored - see class doc.
    }
  }
}
