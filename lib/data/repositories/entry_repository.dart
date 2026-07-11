import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../models/time_entry.dart';

const _uuid = Uuid();

class EntryRepository {
  final AppDatabase _db = AppDatabase.instance;

  int _overlapSeconds(DateTime entryStart, DateTime entryEnd,
      DateTime rangeStart, DateTime rangeEnd) {
    final start =
        entryStart.isAfter(rangeStart) ? entryStart : rangeStart;
    final end = entryEnd.isBefore(rangeEnd) ? entryEnd : rangeEnd;
    if (start.isBefore(end)) return end.difference(start).inSeconds;
    return 0;
  }

  Future<List<TimeEntry>> getAll({int? limit, int? offset}) async {
    final maps = await _db.db.query(
      'time_entries',
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getByTaskName(String taskName) async {
    final maps = await _db.db.query(
      'time_entries',
      where: 'task_name = ?',
      whereArgs: [taskName],
      orderBy: 'start_time DESC',
    );
    return maps.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getActiveEntries() async {
    final maps = await _db.db.query(
      'time_entries',
      where: 'end_time IS NULL',
      orderBy: 'start_time ASC',
    );
    return maps.map(TimeEntry.fromMap).toList();
  }

  Future<TimeEntry> startEntry(String taskName) async {
    final now = DateTime.now();
    final entry = TimeEntry(
      id: _uuid.v4(),
      taskName: taskName,
      startTime: now,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('time_entries', entry.toMap());
    return entry;
  }

  Future<TimeEntry> stopEntry(String entryId, {int? elapsedSeconds}) async {
    final now = DateTime.now();
    final maps = await _db.db.query(
      'time_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
    if (maps.isEmpty) throw Exception('Entry not found');
    final entry = TimeEntry.fromMap(maps.first);
    if (entry.endTime != null) return entry;

    final duration = elapsedSeconds ?? now.difference(entry.startTime).inSeconds;
    final updated = entry.copyWith(
      endTime: now,
      durationSeconds: duration,
      updatedAt: now,
    );
    await _db.db.update(
      'time_entries',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [entryId],
    );
    return updated;
  }

  Future<List<TimeEntry>> getUnsyncedEntries() async {
    final maps = await _db.db.query(
      'time_entries',
      where: 'synced = 0',
      orderBy: 'start_time ASC',
    );
    return maps.map(TimeEntry.fromMap).toList();
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.db.delete(
      'time_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> markSynced(String entryId) async {
    await _db.db.update(
      'time_entries',
      {'synced': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<Map<String, int>> getDailySummary(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final maps = await _db.db.rawQuery('''
      SELECT task_name, start_time, end_time, duration_seconds
      FROM time_entries
      WHERE start_time < ? AND end_time >= ? AND duration_seconds IS NOT NULL
    ''', [dayEnd.toIso8601String(), dayStart.toIso8601String()]);

    final result = <String, int>{};
    for (final m in maps) {
      final entryStart = DateTime.parse(m['start_time'] as String);
      final entryEnd = DateTime.parse(m['end_time'] as String);
      final overlap =
          _overlapSeconds(entryStart, entryEnd, dayStart, dayEnd);
      if (overlap > 0) {
        final taskName = m['task_name'] as String;
        result[taskName] = (result[taskName] ?? 0) + overlap;
      }
    }
    return result;
  }

  Future<Map<String, int>> getWeeklySummary(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final maps = await _db.db.rawQuery('''
      SELECT task_name, start_time, end_time, duration_seconds
      FROM time_entries
      WHERE start_time < ? AND end_time >= ? AND duration_seconds IS NOT NULL
    ''', [weekEnd.toIso8601String(), weekStart.toIso8601String()]);

    final result = <String, int>{};
    for (final m in maps) {
      final entryStart = DateTime.parse(m['start_time'] as String);
      final entryEnd = DateTime.parse(m['end_time'] as String);
      final overlap =
          _overlapSeconds(entryStart, entryEnd, weekStart, weekEnd);
      if (overlap > 0) {
        final taskName = m['task_name'] as String;
        result[taskName] = (result[taskName] ?? 0) + overlap;
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getEntriesInRange(
      DateTime start, DateTime end) async {
    final rows = await _db.db.rawQuery('''
      SELECT time_entries.*, tasks.name as task_name_ref
      FROM time_entries
      LEFT JOIN tasks ON tasks.name = time_entries.task_name
      WHERE time_entries.start_time < ? AND (time_entries.end_time IS NULL OR time_entries.end_time >= ?)
      ORDER BY time_entries.start_time DESC
    ''', [end.toIso8601String(), start.toIso8601String()]);

    for (final row in rows) {
      final endTimeStr = row['end_time'] as String?;
      if (endTimeStr != null) {
        final entryStart = DateTime.parse(row['start_time'] as String);
        final entryEnd = DateTime.parse(endTimeStr);
        row['_overlap_seconds'] =
            _overlapSeconds(entryStart, entryEnd, start, end);
      }
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> getDailyBreakdown(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return await getEntriesInRange(dayStart, dayEnd);
  }
}
