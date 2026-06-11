import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/time_entry.dart';
import '../data/repositories/entry_repository.dart';
import '../data/repositories/task_repository.dart';
import '../services/widget_service.dart';
import 'entry_providers.dart';
import 'task_providers.dart';

class TimerState {
  final TimeEntry? activeEntry;
  final String? activeTaskId;
  final Duration elapsed;
  final bool isLoading;

  const TimerState({
    this.activeEntry,
    this.activeTaskId,
    this.elapsed = Duration.zero,
    this.isLoading = false,
  });

  TimerState copyWith({
    TimeEntry? activeEntry,
    String? activeTaskId,
    Duration? elapsed,
    bool? isLoading,
  }) =>
      TimerState(
        activeEntry: activeEntry ?? this.activeEntry,
        activeTaskId: activeTaskId ?? this.activeTaskId,
        elapsed: elapsed ?? this.elapsed,
        isLoading: isLoading ?? this.isLoading,
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  final EntryRepository _entryRepo;
  final TaskRepository _taskRepo;
  final Ref _ref;
  Timer? _tickTimer;

  TimerNotifier(this._entryRepo, this._taskRepo, this._ref)
      : super(const TimerState()) {
    _loadActiveEntry();
  }

  Future<void> _loadActiveEntry() async {
    final entry = await _entryRepo.getActiveEntry();
    if (entry != null) {
      state = state.copyWith(
        activeEntry: entry,
        activeTaskId: entry.taskId,
        elapsed: DateTime.now().difference(entry.startTime),
      );
      _startTicking();
    }
    _ref.invalidate(tasksProvider);
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.activeEntry != null) {
        state = state.copyWith(
          elapsed: DateTime.now().difference(state.activeEntry!.startTime),
        );
      }
    });
  }

  Future<void> toggleTask(String taskId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      if (state.activeTaskId == taskId) {
        await _stopTimer();
      } else {
        if (state.activeEntry != null) {
          await _stopTimer();
        }
        await _startTimer(taskId);
      }
    } finally {
      state = state.copyWith(isLoading: false);
      _ref.invalidate(allEntriesProvider);
      _ref.invalidate(tasksProvider);
      final tasks = await _taskRepo.getActiveTasks();
      WidgetService.updateWidget(
        tasks: tasks,
        activeTaskId: state.activeTaskId,
      );
    }
  }

  Future<void> _startTimer(String taskId) async {
    final entry = await _entryRepo.startEntry(taskId);
    state = state.copyWith(
      activeEntry: entry,
      activeTaskId: taskId,
      elapsed: Duration.zero,
    );
    _startTicking();
  }

  Future<void> _stopTimer() async {
    if (state.activeEntry == null) return;
    _tickTimer?.cancel();
    await _entryRepo.stopEntry(state.activeEntry!.id);
    state = const TimerState();
  }

  Future<void> stopIfRunning() async {
    if (state.activeEntry != null) {
      await _stopTimer();
    }
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
