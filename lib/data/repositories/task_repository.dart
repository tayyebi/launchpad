import 'package:sqflite/sqflite.dart';
import '../../core/database/database.dart';
import '../models/task.dart';

class TaskRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Task>> getAll() async {
    final maps = await _db.db.query('tasks', orderBy: 'grid_position ASC');
    return maps.map(Task.fromMap).toList();
  }

  Future<Task?> getByName(String name) async {
    final maps =
        await _db.db.query('tasks', where: 'name = ?', whereArgs: [name]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<Task> create({
    required String name,
    int? gridPosition,
  }) async {
    final now = DateTime.now();
    if (gridPosition == null) {
      final count =
          (await _db.db.rawQuery('SELECT COUNT(*) as c FROM tasks')).first['c']
              as int;
      gridPosition = count;
    }
    final task = Task(
      name: name,
      gridPosition: gridPosition,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('tasks', task.toMap());
    return task;
  }

  Future<void> update(String oldName, String newName) async {
    final now = DateTime.now().toIso8601String();
    await _db.db.update(
      'tasks',
      {
        'name': newName,
        'updated_at': now,
      },
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  Future<void> delete(String name) async {
    await _db.db.delete('tasks', where: 'name = ?', whereArgs: [name]);
  }

  Future<int> count() async {
    final result =
        await _db.db.rawQuery('SELECT COUNT(*) as c FROM tasks');
    return result.first['c'] as int;
  }

  Future<List<Task>> getActiveTasks() async {
    final maps = await _db.db.rawQuery('''
      SELECT DISTINCT tasks.* FROM tasks
      INNER JOIN time_entries ON time_entries.task_name = tasks.name
      WHERE time_entries.end_time IS NULL
      ORDER BY tasks.grid_position ASC
    ''');
    return maps.map(Task.fromMap).toList();
  }

  Future<void> updateGridPosition(String name, int newPosition) async {
    await _db.db.update(
      'tasks',
      {'grid_position': newPosition, 'updated_at': DateTime.now().toIso8601String()},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<void> updateGridPositions(List<MapEntry<String, int>> positions) async {
    final batch = _db.db.batch();
    final now = DateTime.now().toIso8601String();
    for (final entry in positions) {
      batch.update(
        'tasks',
        {'grid_position': entry.value, 'updated_at': now},
        where: 'name = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }
}
