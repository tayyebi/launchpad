import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/api/api_client.dart';
import '../data/repositories/entry_repository.dart';
import 'entry_providers.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? message;
  final bool isOnline;

  const SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.isOnline = false,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    bool? isOnline,
  }) =>
      SyncState(
        status: status ?? this.status,
        message: message ?? this.message,
        isOnline: isOnline ?? this.isOnline,
      );
}

class SyncNotifier extends StateNotifier<SyncState> {
  final EntryRepository _entryRepo;
  final Ref _ref;

  SyncNotifier(this._entryRepo, this._ref) : super(const SyncState()) {
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      state = state.copyWith(isOnline: online);
      if (online) syncNow();
    });
  }

  Future<void> syncNow() async {
    if (!ApiClient.instance.isConfigured) return;
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final unsynced = await _entryRepo.getUnsyncedEntries();
      for (final entry in unsynced) {
        try {
          await ApiClient.instance.post('/time-entries', data: entry.toMap());
          await _entryRepo.markSynced(entry.id);
        } catch (_) {}
      }
      state = state.copyWith(
        status: SyncStatus.success,
        message: 'Synced ${unsynced.length} entries',
      );
      _ref.invalidate(allEntriesProvider);
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed: $e',
      );
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  return SyncNotifier(entryRepo, ref);
});
