import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapWithLocationPage extends StatefulWidget {
  @override
  _MapWithLocationPageState createState() => _MapWithLocationPageState();
}

class _MapWithLocationPageState extends State<MapWithLocationPage> {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isCentered = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // todo get this from constructor
  late List<LatLng> _searchLocations = [
    LatLng(52.399523, 13.394568),
    LatLng(52.399123, 13.392168),
  ];

  late List<Marker> _searchLocationsMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeMarkers();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;

    try {
      final position = await _geolocatorPlatform.getCurrentPosition();
      _updateLocation(LatLng(position.latitude, position.longitude),
          shouldCenter: true);
    } catch (e) {
      debugPrint('Error getting current position: $e');
    }

    _positionStreamSubscription = _geolocatorPlatform
        .getPositionStream(locationSettings: const LocationSettings())
        .listen((Position position) {
      _updateLocation(LatLng(position.latitude, position.longitude));
    });
  }

  void _initializeMarkers() {
    setState(() {
      _searchLocationsMarkers = _searchLocations.map((location) {
        return Marker(
          point: location,
          width: 30,
          height: 30,
          child: Icon(
            Icons.circle_outlined,
            color: Colors.red,
            size: 190,
          ),
        );
      }).toList();
    });
  }

  void _updateLocation(LatLng newLocation, {bool shouldCenter = false}) {
    setState(() {
      _currentLocation = newLocation;
    });

    if (shouldCenter || _isCentered) {
      _mapController.move(newLocation, 15.0);
    }
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are turned off.')),
      );
      return false;
    }

    LocationPermission permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geolocation permission denied.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Geolocation permission is permanently blocked. Change your settings.'),
        ),
      );
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation ?? LatLng(0, 0),
          initialZoom: _currentLocation != null ? 15.0 : 2.0,
          onMapEvent: (event) {
            if (event is MapEventMove &&
                event.source != MapEventSource.mapController) {
              setState(() {
                _isCentered = false;
              });
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // todo
            userAgentPackageName: 'com.example.app',
          ),
          if (_currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                ..._searchLocationsMarkers
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 15.0);
            setState(() {
              _isCentered = true;
            });
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
