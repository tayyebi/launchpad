import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final int gridSize;

  const SettingsState({this.gridSize = 3});

  SettingsState copyWith({int? gridSize}) =>
      SettingsState(gridSize: gridSize ?? this.gridSize);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final size = prefs.getInt('grid_size') ?? 3;
    state = state.copyWith(gridSize: size.clamp(2, 6));
  }

  Future<void> setGridSize(int size) async {
    final clamped = size.clamp(2, 6);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grid_size', clamped);
    state = state.copyWith(gridSize: clamped);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
