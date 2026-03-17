import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsViewModel extends ChangeNotifier {
  GoogleMapController? _mapController;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      animateCameraTo(_currentLocation!, zoom: 15.0);
    } else {
      fetchCurrentLocation();
    }
  }

  static const LatLng _defaultCenter = LatLng(45.521563, -122.677433);

  CameraPosition get initialCameraPosition =>
      const CameraPosition(target: _defaultCenter, zoom: 13.0);

  Future<void> animateCameraTo(
    LatLng target, {
    double zoom = 14.0,
    double tilt = 0.0,
    double bearing = 0.0,
  }) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          tilt: tilt,
          bearing: bearing,
        ),
      ),
    );
  }

  Future<void> zoomIn() async =>
      _mapController?.animateCamera(CameraUpdate.zoomIn());

  Future<void> zoomOut() async =>
      _mapController?.animateCamera(CameraUpdate.zoomOut());

  Future<void> tiltCamera() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _defaultCenter,
          zoom: 14.0,
          tilt: 60.0,
          bearing: 45.0,
        ),
      ),
    );
  }

  Future<void> resetCamera() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(initialCameraPosition),
    );
  }

  LatLng? _currentLocation;
  LatLng? get currentLocation => _currentLocation;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  String? _locationError;
  String? get locationError => _locationError;

  Future<void> fetchCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _locationError = 'Location permission denied.';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      await animateCameraTo(_currentLocation!, zoom: 15.0);
    } catch (e) {
      _locationError = 'Could not fetch location.';
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  final Map<String, Marker> _markerMap = {};
  Set<Marker> get markers => _markerMap.values.toSet();

  String? _selectedMarkerId;
  String? get selectedMarkerId => _selectedMarkerId;

  BitmapDescriptor? _customIcon;

  Future<void> loadCustomIcon() async {
    _customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/markers/custom_pin.png',
    );
  }

  int _markerCounter = 0;
  int _tapCounter = 0;

  static const List<List<double>> _offsets = [
    [0.0, 0.0],
    [0.001, 0.0],
    [-0.001, 0.0],
    [0.0, 0.001],
    [0.0, -0.001],
    [0.001, 0.001],
    [-0.001, -0.001],
    [0.001, -0.001],
    [-0.001, 0.001],
  ];

  Future<void> addDefaultMarker() async {
    if (_currentLocation == null) await fetchCurrentLocation();
    final origin = _currentLocation;
    if (origin == null) return;
    _markerCounter++;
    final off = _offsets[_markerCounter % _offsets.length];
    final point = LatLng(origin.latitude + off[0], origin.longitude + off[1]);
    final id = 'default_$_markerCounter';
    final marker = Marker(
      markerId: MarkerId(id),
      position: point,
      infoWindow: InfoWindow(
        title: 'Marker #$_markerCounter',
        snippet:
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
      ),
      onTap: () => _onMarkerTapped(id),
    );
    _markerMap[id] = marker;
    notifyListeners();
  }

  int _customCounter = 0;

  Future<void> addCustomMarker() async {
    if (_currentLocation == null) await fetchCurrentLocation();
    final origin = _currentLocation;
    if (origin == null) return;
    _customCounter++;
    final off = _offsets[(_customCounter + 4) % _offsets.length];
    final point = LatLng(origin.latitude + off[0], origin.longitude + off[1]);
    final id = 'custom_$_customCounter';
    final marker = Marker(
      markerId: MarkerId(id),
      position: point,
      icon:
          _customIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(
        title: 'Custom #$_customCounter',
        snippet:
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
      ),
      onTap: () => _onMarkerTapped(id),
    );
    _markerMap[id] = marker;
    notifyListeners();
  }

  void _onMarkerTapped(String id) {
    _selectedMarkerId = id;
    notifyListeners();
  }

  void removeSelectedMarker() {
    if (_selectedMarkerId != null) {
      _markerMap.remove(_selectedMarkerId);
      _selectedMarkerId = null;
      notifyListeners();
    }
  }

  void removeAllMarkers() {
    _markerMap.clear();
    _selectedMarkerId = null;
    notifyListeners();
  }

  void addTapMarker(LatLng point) {
    _tapCounter++;
    final id = 'tap_$_tapCounter';
    final marker = Marker(
      markerId: MarkerId(id),
      position: point,
      infoWindow: InfoWindow(
        title: 'Tap #$_tapCounter',
        snippet:
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
      ),
      onTap: () => _onMarkerTapped(id),
    );
    _markerMap[id] = marker;
    notifyListeners();
  }

  final Map<String, Polyline> _polylineMap = {};
  Set<Polyline> get polylines => _polylineMap.values.toSet();

  Future<void> addStaticPolyline() async {
    if (_currentLocation == null) await fetchCurrentLocation();
    final origin = _currentLocation;
    if (origin == null) return;
    const id = 'static_route';
    final polyline = Polyline(
      polylineId: const PolylineId(id),
      points: [
        LatLng(origin.latitude + 0.006, origin.longitude - 0.004),
        LatLng(origin.latitude + 0.004, origin.longitude + 0.002),
        LatLng(origin.latitude + 0.002, origin.longitude - 0.002),
        LatLng(origin.latitude, origin.longitude + 0.003),
        LatLng(origin.latitude - 0.003, origin.longitude - 0.001),
        LatLng(origin.latitude - 0.006, origin.longitude + 0.004),
      ],
      color: Colors.blue,
      width: 5,
    );
    _polylineMap[id] = polyline;
    notifyListeners();
  }

  void clearPolylines() {
    _polylineMap.clear();
    notifyListeners();
  }

  final Map<String, Polygon> _polygonMap = {};
  Set<Polygon> get polygons => _polygonMap.values.toSet();

  void clearPolygons() {
    _polygonMap.clear();
    notifyListeners();
  }

  final Map<String, Circle> _circleMap = {};
  Set<Circle> get circles => _circleMap.values.toSet();

  Future<void> addCircle() async {
    if (_currentLocation == null) await fetchCurrentLocation();
    final origin = _currentLocation;
    if (origin == null) return;
    const id = 'circle';
    final circle = Circle(
      circleId: const CircleId(id),
      center: origin,
      radius: 400,
      fillColor: Colors.purple.withOpacity(0.2),
      strokeColor: Colors.purple,
      strokeWidth: 2,
    );
    _circleMap[id] = circle;
    notifyListeners();
  }

  void clearCircles() {
    _circleMap.clear();
    notifyListeners();
  }

  void clearAll() {
    _markerMap.clear();
    _polylineMap.clear();
    _polygonMap.clear();
    _circleMap.clear();
    _selectedMarkerId = null;
    notifyListeners();
  }

  Future<void> init() async {
    await loadCustomIcon();
  }
}
