import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

/// Camada de acesso ao SQLite (usuários, hábitos e registros).
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'quit_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            unit TEXT NOT NULL,
            emoji TEXT NOT NULL,
            baseline_per_day REAL NOT NULL,
            cost_per_unit REAL NOT NULL,
            start_date TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )''');
        await db.execute('''
          CREATE TABLE habit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            consumed REAL NOT NULL,
            note TEXT,
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )''');
      },
    );
  }

  // ------------------------- Usuários -------------------------

  /// Retorna o mapa bruto (inclui hash e salt) ou null se não existir.
  Future<Map<String, Object?>?> findUserRowByEmail(String email) async {
    final db = await _database;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<AppUser?> findUserById(int id) async {
    final db = await _database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<int> insertUser({
    required String name,
    required String email,
    required String passwordHash,
    required String salt,
  }) async {
    final db = await _database;
    return db.insert('users', {
      'name': name,
      'email': email.toLowerCase(),
      'password_hash': passwordHash,
      'salt': salt,
    });
  }

  // ------------------------- Hábitos (CRUD) -------------------------

  Future<int> insertHabit(Habit h) async {
    final db = await _database;
    return db.insert('habits', h.toMap());
  }

  Future<List<Habit>> getHabits(int userId) async {
    final db = await _database;
    final rows = await db.query('habits',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'id DESC');
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final db = await _database;
    final rows =
        await db.query('habits', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Habit.fromMap(rows.first);
  }

  Future<void> updateHabit(Habit h) async {
    final db = await _database;
    await db.update('habits', h.toMap(), where: 'id = ?', whereArgs: [h.id]);
  }

  Future<void> deleteHabit(int id) async {
    final db = await _database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------- Registros (CRUD) -------------------------

  Future<int> insertLog(HabitLog l) async {
    final db = await _database;
    return db.insert('habit_logs', l.toMap());
  }

  Future<List<HabitLog>> getLogs(int habitId) async {
    final db = await _database;
    final rows = await db.query('habit_logs',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        orderBy: 'date DESC, id DESC');
    return rows.map(HabitLog.fromMap).toList();
  }

  Future<void> updateLog(HabitLog l) async {
    final db = await _database;
    await db.update('habit_logs', l.toMap(), where: 'id = ?', whereArgs: [l.id]);
  }

  Future<void> deleteLog(int id) async {
    final db = await _database;
    await db.delete('habit_logs', where: 'id = ?', whereArgs: [id]);
  }
}
