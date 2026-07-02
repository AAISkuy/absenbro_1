import 'dart:developer';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model_sql.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'skinoura.db');

    return await openDatabase(
      path,
      version: 2, // Upgraded version to support migrations
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');

        await _createV2Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
      },
    );
  }

  Future<void> _createV2Tables(Database db) async {
    // 1. Session User Table
    await db.execute('''
      CREATE TABLE session_user (
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT,
        role TEXT,
        token TEXT,
        batch_id INTEGER,
        training_id INTEGER
      )
    ''');

    // 2. Attendance Queue Table (Offline Check-in / Check-out / Izin)
    await db.execute('''
      CREATE TABLE attendance_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT,
        attendance_date TEXT,
        check_time TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        status TEXT,
        alasan_izin TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    log("SQLite Version 2 tables created successfully.");
  }

  // --- Attendance Queue Methods (Offline Caching) ---

  Future<int> queueOfflineAttendance({
    required String actionType, // 'check-in', 'check-out', 'izin'
    required String attendanceDate,
    required String checkTime,
    double? latitude,
    double? longitude,
    String? address,
    String? status,
    String? alasanIzin,
  }) async {
    final db = await database;
    try {
      final id = await db.insert('attendance_queue', {
        'action_type': actionType,
        'attendance_date': attendanceDate,
        'check_time': checkTime,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'status': status,
        'alasan_izin': alasanIzin,
        'is_synced': 0,
      });
      log("Queued offline attendance successfully. ID: $id");
      return id;
    } catch (e) {
      log("Failed to queue offline attendance: $e");
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAttendance() async {
    final db = await database;
    return await db.query(
      'attendance_queue',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAttendanceAsSynced(int id) async {
    final db = await database;
    await db.update(
      'attendance_queue',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSyncedAttendance() async {
    final db = await database;
    await db.delete(
      'attendance_queue',
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }

  // --- Original Users Table Methods (SQLite Local Users) ---

  Future<bool> registerUser(UserModelSql pengguna) async {
    final db = await database;
    try {
      await db.insert('users', pengguna.toMap());
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<UserModelSql?> loginUser(UserModelSql pengguna) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [pengguna.email, pengguna.password],
    );
    log(results.toString());

    if (results.isNotEmpty) {
      return UserModelSql.fromMap(results.first);
    }
    return null;
  }

  Future<List<UserModelSql>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('users');

    return results.map((map) => UserModelSql.fromMap(map)).toList();
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> updateUser(UserModelSql pengguna) async {
    final db = await database;
    try {
      int count = await db.update(
        'users',
        pengguna.toMap(),
        where: 'id = ?',
        whereArgs: [pengguna.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }
}
