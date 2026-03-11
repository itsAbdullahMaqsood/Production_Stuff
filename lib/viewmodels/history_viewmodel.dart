import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_entry.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryService _service;
  final NotificationService _notificationService;

  late final StreamSubscription _sub;

  HistoryViewModel(this._service, this._notificationService) {
    _sub = _notificationService.onNotificationShown.listen((_) {
      addEntry();
    });
  }

  List<NotificationEntry> _entries = [];

  List<NotificationEntry> get entries => List.unmodifiable(_entries);
  int get count => _entries.length;

  Future<void> loadEntries() async {
    _entries = await _service.loadEntries();
    notifyListeners();
  }

  Future<void> addEntry() async {
    final entry = await _service.addEntry();
    _entries.insert(0, entry);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    _entries.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
