import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_realtime_service.dart';

class LocationTrackingViewModel extends ChangeNotifier {
  LocationTrackingViewModel({
    required LocationRealtimeService service,
  }) : _service = service;

  final LocationRealtimeService _service;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastWriteAt;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  String? _error;
  String? get lastError => _error;

  Future<void> toggleTracking() async {
    if (_isTracking) {
      await stopTracking();
      return;
    }
    await startTracking();
  }

  Future<void> startTracking() async {
    _error = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location service is disabled.';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _error = 'Location permission denied.';
        notifyListeners();
        return;
      }

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen(_onPosition, onError: errorFunc);

      _isTracking = true;
      notifyListeners();
    } catch (_) {
      _error = 'Could not start location tracking.';
      _isTracking = false;
      notifyListeners();
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _onPosition(Position position) async {
    final now = DateTime.now();
    if (_lastWriteAt != null &&
        now.difference(_lastWriteAt!) < const Duration(seconds: 2)) {
      return;
    }

    try {
      await _service.writeLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      _lastWriteAt = now;
      _error = null;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to send realtime location.';
      notifyListeners();
    }
  }

  void errorFunc(Object _) {
    _error = 'Location stream error.';
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
