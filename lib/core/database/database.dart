import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../l10n/strings.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;
  AppDatabase._();

  Database? _db;
  Database get db => _db!;

  Future<String> get dbPath async {
    final base = await getExternalStorageDirectory();
    final root = base?.path ?? (await getDatabasesPath());
    final dir = Directory(p.join(root, 'launchpad_data'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.join(dir.path, 'launchpad.db');
  }

  Future<void> initialize() async {
    final path = await dbPath;
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        name TEXT PRIMARY KEY,
        grid_position INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE time_entries (
        id TEXT PRIMARY KEY,
        task_name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_entries_task_name ON time_entries(task_name)');
    await db.execute(
        'CREATE INDEX idx_entries_start_time ON time_entries(start_time)');
    await db.execute(
        'CREATE INDEX idx_entries_synced ON time_entries(synced)');

    _seedDefaultTasks(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE tasks RENAME TO tasks_old');
        await txn.execute('ALTER TABLE time_entries RENAME TO time_entries_old');

        await txn.execute('''
          CREATE TABLE tasks (
            name TEXT PRIMARY KEY,
            grid_position INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE time_entries (
            id TEXT PRIMARY KEY,
            task_name TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            duration_seconds INTEGER,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          INSERT INTO tasks (name, grid_position, created_at, updated_at)
          SELECT name, grid_position, created_at, updated_at FROM tasks_old
        ''');

        await txn.execute('''
          INSERT INTO time_entries (id, task_name, start_time, end_time, duration_seconds, synced, created_at, updated_at)
          SELECT te.id, COALESCE(t.name, te.task_id), te.start_time, te.end_time, te.duration_seconds, te.synced, te.created_at, te.updated_at
          FROM time_entries_old te
          LEFT JOIN tasks_old t ON t.id = te.task_id
        ''');

        await txn.execute('DROP TABLE IF EXISTS time_entries_old');
        await txn.execute('DROP TABLE IF EXISTS tasks_old');
      });

      await db.execute(
          'CREATE INDEX idx_entries_task_name ON time_entries(task_name)');
      await db.execute(
          'CREATE INDEX idx_entries_start_time ON time_entries(start_time)');
      await db.execute(
          'CREATE INDEX idx_entries_synced ON time_entries(synced)');
    }
  }

  Future<void> _seedDefaultTasks(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = Strings.defaultTasks;

    for (int i = 0; i < defaults.length; i++) {
      await db.insert('tasks', {
        'name': defaults[i],
        'grid_position': i,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<String> exportToDownloads() async {
    final src = await dbPath;
    final base = await getExternalStorageDirectory();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final exportName = 'launchpad_backup_$dateStr.db';
    final exportPath =
        p.join(base?.path ?? (await getDatabasesPath()), exportName);

    await File(src).copy(exportPath);
    return exportPath;
  }

  Future<void> close() async => _db?.close();
}
