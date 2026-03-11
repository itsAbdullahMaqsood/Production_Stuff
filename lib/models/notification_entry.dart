class NotificationEntry {
  final int? id;
  final DateTime timestamp;

  const NotificationEntry({this.id, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'id': id, 'timestamp': timestamp.millisecondsSinceEpoch};
  }

  factory NotificationEntry.fromMap(Map<String, dynamic> map) {
    return NotificationEntry(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
