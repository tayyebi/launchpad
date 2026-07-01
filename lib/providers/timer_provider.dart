import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/time_entry.dart';
import '../data/repositories/entry_repository.dart';
import '../data/repositories/task_repository.dart';
import '../services/widget_service.dart';
import 'entry_providers.dart';
import 'task_providers.dart';
import 'settings_provider.dart';

class TimerState {
  final Map<String, TimeEntry> activeEntries;
  final Map<String, Duration> elapsedByTask;
  final bool isLoading;
  final Set<String> activeTaskNames;

  const TimerState({
    this.activeEntries = const {},
    this.elapsedByTask = const {},
    this.isLoading = false,
    this.activeTaskNames = const {},
  });

  TimerState copyWith({
    Map<String, TimeEntry>? activeEntries,
    Map<String, Duration>? elapsedByTask,
    bool? isLoading,
    Set<String>? activeTaskNames,
  }) =>
      TimerState(
        activeEntries: activeEntries ?? this.activeEntries,
        elapsedByTask: elapsedByTask ?? this.elapsedByTask,
        isLoading: isLoading ?? this.isLoading,
        activeTaskNames: activeTaskNames ?? this.activeTaskNames,
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  final EntryRepository _entryRepo;
  final TaskRepository _taskRepo;
  final Ref _ref;
  Timer? _tickTimer;

  TimerNotifier(this._entryRepo, this._taskRepo, this._ref)
      : super(const TimerState()) {
    _loadActiveEntries();
  }

  Future<void> _loadActiveEntries() async {
    final entries = await _entryRepo.getActiveEntries();
    if (entries.isNotEmpty) {
      final activeEntries = <String, TimeEntry>{};
      final elapsedByTask = <String, Duration>{};
      final now = DateTime.now();
      for (final entry in entries) {
        activeEntries[entry.taskName] = entry;
        elapsedByTask[entry.taskName] = now.difference(entry.startTime);
      }
      state = state.copyWith(
        activeEntries: activeEntries,
        elapsedByTask: elapsedByTask,
        activeTaskNames: activeEntries.keys.toSet(),
      );
      _saveActiveTaskNames(activeEntries.keys.toList());
      _startTicking();
    }
    _ref.invalidate(tasksProvider);
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.activeEntries.isNotEmpty) {
        final now = DateTime.now();
        final elapsedByTask = <String, Duration>{};
        for (final entry in state.activeEntries.values) {
          elapsedByTask[entry.taskName] = now.difference(entry.startTime);
        }
        state = state.copyWith(elapsedByTask: elapsedByTask);
      }
    });
  }

  Future<void> _saveActiveTaskNames(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    if (names.isEmpty) {
      await prefs.remove('active_task_names');
    } else {
      await prefs.setStringList('active_task_names', names);
    }
  }

  Future<void> toggleTask(String taskName) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      if (state.activeTaskNames.contains(taskName)) {
        await _stopTimer(taskName);
      } else {
        final settings = _ref.read(settingsProvider);
        if (settings.multitaskingEnabled &&
            state.activeEntries.length >= maxConcurrentTasks) {
          final firstTask = state.activeEntries.keys.first;
          await _stopTimer(firstTask);
        }
        if (!settings.multitaskingEnabled && state.activeEntries.isNotEmpty) {
          final firstTask = state.activeEntries.keys.first;
          await _stopTimer(firstTask);
        }
        await _startTimer(taskName);
      }
    } finally {
      state = state.copyWith(isLoading: false);
      _ref.invalidate(allEntriesProvider);
      _ref.invalidate(tasksProvider);
      final tasks = await _taskRepo.getAll();
      WidgetService.updateWidget(
        tasks: tasks,
        activeTaskName:
            state.activeTaskNames.isNotEmpty ? state.activeTaskNames.first : null,
      );
    }
  }

  Future<void> _startTimer(String taskName) async {
    final entry = await _entryRepo.startEntry(taskName);
    final activeEntries = Map<String, TimeEntry>.from(state.activeEntries);
    activeEntries[taskName] = entry;
    final activeTaskNames = activeEntries.keys.toSet();
    state = state.copyWith(
      activeEntries: activeEntries,
      activeTaskNames: activeTaskNames,
      elapsedByTask: {...state.elapsedByTask, taskName: Duration.zero},
    );
    _saveActiveTaskNames(activeTaskNames.toList());
    _startTicking();
  }

  Future<void> _stopTimer(String taskName) async {
    final entry = state.activeEntries[taskName];
    if (entry == null) return;
    final elapsed = state.elapsedByTask[taskName] ?? Duration.zero;
    await _entryRepo.stopEntry(
      entry.id,
      elapsedSeconds: elapsed.inSeconds,
    );
    final activeEntries = Map<String, TimeEntry>.from(state.activeEntries);
    activeEntries.remove(taskName);
    final elapsedByTask = Map<String, Duration>.from(state.elapsedByTask);
    elapsedByTask.remove(taskName);
    final activeTaskNames = activeEntries.keys.toSet();
    state = state.copyWith(
      activeEntries: activeEntries,
      elapsedByTask: elapsedByTask,
      activeTaskNames: activeTaskNames,
    );
    _saveActiveTaskNames(activeTaskNames.toList());
    if (activeEntries.isEmpty) {
      _tickTimer?.cancel();
    }
  }

  Future<void> stopIfRunning() async {
    if (state.activeEntries.isEmpty) return;
    final entries = Map<String, TimeEntry>.from(state.activeEntries);
    for (final taskName in entries.keys) {
      await _stopTimer(taskName);
    }
    _tickTimer?.cancel();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}

final timerProvider =
    StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  return TimerNotifier(entryRepo, taskRepo, ref);
});
