import '../models/notification_entry.dart';
import '../services/database_service.dart';

class HistoryService {
  final DatabaseService _db;

  HistoryService(this._db);

  Future<List<NotificationEntry>> loadEntries() async {
    return await _db.getAll();
  }

  Future<NotificationEntry> addEntry() async {
    final entry = NotificationEntry(timestamp: DateTime.now());
    final id = await _db.insertEntry(entry);
    return NotificationEntry(id: id, timestamp: entry.timestamp);
  }

  Future<void> clearAll() async {
    await _db.clearAll();
  }
}
