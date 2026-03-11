import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/notification_entry.dart';

class DatabaseService {
  static const _dbName = 'notif_history.db';
  static const _dbVersion = 1;
  static const _table = 'notification_history';

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, _dbName);

    _db = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(NotificationEntry entry) async {
    return await _db!.insert(
      _table,
      entry.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationEntry>> getAll() async {
    final rows = await _db!.query(_table, orderBy: 'timestamp DESC');
    return rows.map(NotificationEntry.fromMap).toList();
  }

  Future<void> clearAll() async {
    await _db!.delete(_table);
  }
}
