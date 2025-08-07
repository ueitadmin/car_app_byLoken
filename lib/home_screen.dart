
// home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  Location location = Location();

  bool _isTracking = false;
  double _distance = 0.0;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    location.onLocationChanged.listen((LocationData newLoc) {
      if (_isTracking) {
        LatLng newPoint = LatLng(newLoc.latitude!, newLoc.longitude!);
        if (_routePoints.isNotEmpty) {
          _distance += _calculateDistance(_routePoints.last, newPoint);
        }
        setState(() {
          _routePoints.add(newPoint);
        });
      }

      setState(() {
        _currentLocation = newLoc;
      });
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // in km
    double dLat = _deg2rad(end.latitude - start.latitude);
    double dLng = _deg2rad(end.longitude - start.longitude);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(start.latitude)) *
            cos(_deg2rad(end.latitude)) *
            (sin(dLng / 2) * sin(dLng / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (3.1415926535897932 / 180.0);

  void _startTrip() {
    setState(() {
      _routePoints.clear();
      _distance = 0.0;
      _isTracking = true;
    });
  }

  void _stopTrip() async {
    setState(() {
      _isTracking = false;
    });

    if (_routePoints.isNotEmpty) {
      await FirebaseFirestore.instance.collection('trips').add({
        'timestamp': DateTime.now(),
        'distance_km': _distance,
        'route': _routePoints
            .map((point) => {'lat': point.latitude, 'lng': point.longitude})
            .toList(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Car KM Tracker')),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                  polylines: {
                    Polyline(
                      polylineId: PolylineId("route"),
                      points: _routePoints,
                      color: Colors.green,
                      width: 5,
                    ),
                  },
                ),
                Positioned(
                  bottom: 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Distance Travelled: ${_distance.toStringAsFixed(2)} km",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isTracking ? null : _startTrip,
                              child: Text("Start Trip"),
                            ),
                            ElevatedButton(
                              onPressed: _isTracking ? _stopTrip : null,
                              child: Text("Stop Trip"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
