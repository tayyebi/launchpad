import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../models/task.dart';

const _uuid = Uuid();

class TaskRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Task>> getAll() async {
    final maps = await _db.db.query('tasks', orderBy: 'grid_position ASC');
    return maps.map(Task.fromMap).toList();
  }

  Future<Task?> getById(String id) async {
    final maps = await _db.db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<Task> create({
    required String name,
    required int color,
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
      id: _uuid.v4(),
      name: name,
      color: color,
      gridPosition: gridPosition,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('tasks', task.toMap());
    return task;
  }

  Future<void> update(Task task) async {
    await _db.db.update(
      'tasks',
      task.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete('time_entries', where: 'task_id = ?', whereArgs: [id]);
    await _db.db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final result =
        await _db.db.rawQuery('SELECT COUNT(*) as c FROM tasks');
    return result.first['c'] as int;
  }

  Future<List<Task>> getActiveTasks() async {
    final maps = await _db.db.query('tasks', orderBy: 'grid_position ASC');
    return maps.map(Task.fromMap).toList();
  }

  Future<void> updateGridPosition(String id, int newPosition) async {
    await _db.db.update(
      'tasks',
      {'grid_position': newPosition, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
