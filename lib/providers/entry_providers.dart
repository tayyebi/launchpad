import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/time_entry.dart';
import '../data/repositories/entry_repository.dart';

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});

final allEntriesProvider = FutureProvider<List<TimeEntry>>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getAll(limit: 200);
});

final dailyBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>(
  (ref, date) async {
    final repo = ref.watch(entryRepositoryProvider);
    return repo.getDailyBreakdown(date);
  },
);
