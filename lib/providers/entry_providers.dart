import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/time_entry.dart';
import '../data/repositories/entry_repository.dart';

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});

// Unbounded on purpose: the CSV export is the only reader, and truncating here
// silently dropped every entry beyond the newest 200 from the exported file.
final allEntriesProvider = FutureProvider<List<TimeEntry>>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getAll();
});

final dailySummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getDailySummary(DateTime.now());
});

final dailyBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>(
  (ref, date) async {
    final repo = ref.watch(entryRepositoryProvider);
    return repo.getDailyBreakdown(date);
  },
);
