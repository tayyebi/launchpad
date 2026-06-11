import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../models/time_entry.dart';

const _uuid = Uuid();

class EntryRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<TimeEntry>> getAll({int? limit, int? offset}) async {
    final maps = await _db.db.query(
      'time_entries',
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getByTaskId(String taskId) async {
    final maps = await _db.db.query(
      'time_entries',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'start_time DESC',
    );
    return maps.map(TimeEntry.fromMap).toList();
  }

  Future<TimeEntry?> getActiveEntry() async {
    final maps = await _db.db.query(
      'time_entries',
      where: 'end_time IS NULL',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TimeEntry.fromMap(maps.first);
  }

  Future<TimeEntry> startEntry(String taskId) async {
    final now = DateTime.now();
    final entry = TimeEntry(
      id: _uuid.v4(),
      taskId: taskId,
      startTime: now,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('time_entries', entry.toMap());
    return entry;
  }

  Future<TimeEntry> stopEntry(String entryId) async {
    final now = DateTime.now();
    final maps = await _db.db.query(
      'time_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
    if (maps.isEmpty) throw Exception('Entry not found');
    final entry = TimeEntry.fromMap(maps.first);
    if (entry.endTime != null) return entry;

    final duration = now.difference(entry.startTime).inSeconds;
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
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final maps = await _db.db.rawQuery('''
      SELECT task_id, COALESCE(SUM(duration_seconds), 0) as total
      FROM time_entries
      WHERE start_time >= ? AND start_time < ? AND duration_seconds IS NOT NULL
      GROUP BY task_id
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final result = <String, int>{};
    for (final m in maps) {
      result[m['task_id'] as String] = m['total'] as int;
    }
    return result;
  }

  Future<Map<String, int>> getWeeklySummary(DateTime weekStart) async {
    final end = weekStart.add(const Duration(days: 7));
    final maps = await _db.db.rawQuery('''
      SELECT task_id, COALESCE(SUM(duration_seconds), 0) as total
      FROM time_entries
      WHERE start_time >= ? AND start_time < ? AND duration_seconds IS NOT NULL
      GROUP BY task_id
    ''', [weekStart.toIso8601String(), end.toIso8601String()]);

    final result = <String, int>{};
    for (final m in maps) {
      result[m['task_id'] as String] = m['total'] as int;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getEntriesInRange(DateTime start, DateTime end) async {
    return await _db.db.rawQuery('''
      SELECT time_entries.*, tasks.name as task_name, tasks.color as task_color
      FROM time_entries
      INNER JOIN tasks ON tasks.id = time_entries.task_id
      WHERE time_entries.start_time >= ? AND time_entries.start_time < ?
      ORDER BY time_entries.start_time DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> getDailyBreakdown(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return await _db.db.rawQuery('''
      SELECT time_entries.*, tasks.name as task_name, tasks.color as task_color
      FROM time_entries
      INNER JOIN tasks ON tasks.id = time_entries.task_id
      WHERE time_entries.start_time >= ? AND time_entries.start_time < ?
      ORDER BY time_entries.start_time DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }
}
