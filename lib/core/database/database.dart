import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;
  AppDatabase._();

  Database? _db;
  Database get db => _db!;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'launchpad.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        grid_position INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE time_entries (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_entries_task_id ON time_entries(task_id)');
    await db.execute(
        'CREATE INDEX idx_entries_start_time ON time_entries(start_time)');
    await db.execute(
        'CREATE INDEX idx_entries_synced ON time_entries(synced)');

    _seedDefaultTasks(db);
  }

  Future<void> _seedDefaultTasks(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      ('Work', 0xFF4CAF50, 0),
      ('Study', 0xFF2196F3, 1),
      ('Exercise', 0xFFFF5722, 2),
      ('Reading', 0xFF9C27B0, 3),
      ('Music', 0xFFFFC107, 4),
      ('Gaming', 0xFFE91E63, 5),
      ('Social', 0xFF00BCD4, 6),
      ('Cooking', 0xFFFF9800, 7),
      ('Chores', 0xFF607D8B, 8),
    ];

    for (final t in defaults) {
      await db.insert('tasks', {
        'id': _uuid.v4(),
        'name': t.$1,
        'color': t.$2,
        'grid_position': t.$3,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> close() async => _db?.close();
}
