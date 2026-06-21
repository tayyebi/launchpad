import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int maxConcurrentTasks = 2;

class SettingsState {
  final int gridSize;
  final bool multitaskingEnabled;

  const SettingsState({this.gridSize = 3, this.multitaskingEnabled = false});

  SettingsState copyWith({int? gridSize, bool? multitaskingEnabled}) =>
      SettingsState(
        gridSize: gridSize ?? this.gridSize,
        multitaskingEnabled: multitaskingEnabled ?? this.multitaskingEnabled,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final size = prefs.getInt('grid_size') ?? 3;
    final multitasking = prefs.getBool('multitasking_enabled') ?? false;
    state = state.copyWith(
      gridSize: size.clamp(2, 6),
      multitaskingEnabled: multitasking,
    );
  }

  Future<void> setGridSize(int size) async {
    final clamped = size.clamp(2, 6);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grid_size', clamped);
    state = state.copyWith(gridSize: clamped);
  }

  Future<void> setMultitasking(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('multitasking_enabled', enabled);
    state = state.copyWith(multitaskingEnabled: enabled);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
