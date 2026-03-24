import 'package:firebase_database/firebase_database.dart';

class LocationRealtimeService {
  LocationRealtimeService({
    FirebaseDatabase? database,
    this.deviceId = 'notif_analytics_device',
  }) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  final String deviceId;

  DatabaseReference get _locationRef => _database.ref('locations/$deviceId');

  Future<void> writeLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    await _locationRef.set({
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'updatedAt': ServerValue.timestamp,
    });
  }
}
