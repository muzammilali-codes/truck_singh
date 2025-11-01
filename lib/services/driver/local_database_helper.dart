import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseHelper {
  static const _databaseName = "LocationCache.db";
  static const _databaseVersion =
      1;
  static const tableLocations = 'locations';

  LocalDatabaseHelper._privateConstructor();
  static final LocalDatabaseHelper instance =
      LocalDatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableLocations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            custom_user_id TEXT NOT NULL,
            user_id TEXT,
            location_lat REAL NOT NULL,
            location_lng REAL NOT NULL,
            last_updated_at TEXT NOT NULL
          )
          ''');
  }

  Future<int> insertLocation(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableLocations, row);
  }
  Future<List<Map<String, dynamic>>> getAllLocations() async {
    Database db = await instance.database;
    return await db.query(tableLocations);
  }
  Future<int> clearAllLocations() async {
    Database db = await instance.database;
    return await db.delete(tableLocations);
  }
}
