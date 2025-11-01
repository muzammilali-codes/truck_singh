import 'dart:async';
import 'dart:math' show sqrt, sin, cos, atan2, min, max;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logistics_toolkit/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverRouteTrackingPage extends StatefulWidget {
  final String driverId; // Pass current driver's custom_user_id
  const DriverRouteTrackingPage({super.key, required this.driverId});

  @override
  State<DriverRouteTrackingPage> createState() =>
      _DriverRouteTrackingPageState();
}

class _DriverRouteTrackingPageState extends State<DriverRouteTrackingPage> {
  GoogleMapController? _mapController;
  final Set<Polyline> _bluePolylines = {}; // pickup → drop
  final Set<Polyline> _redPolylines = {}; // driver → drop

  final Set<Marker> _markers = {};

  LatLng? _driverLocation;
  LatLng? pickupLocation;
  LatLng? dropLocation;

  double _distanceTraveled = 0.0; // km
  double _distanceRemaining = 0.0;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Load driver location + shipment data
  Future<void> _initTracking() async {
    try {
      await _loadShipmentLocations();
      await _loadLastDriverLocation();
      await _startDriverLocationTracking();
    } catch (e) {
      print('Tracking init error: $e');
    }
  }

  /// Start listening to driver location changes
  Future<void> _startDriverLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("Enable location services!");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar("Location permission denied!");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar("Location permission permanently denied!");
      return;
    }

    // Start listening to position updates
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen((position) {
          final currentLatLng = LatLng(position.latitude, position.longitude);
          setState(() {
            _driverLocation = currentLatLng;
          });
          _updateDriverLocationInDbFromLatLng(currentLatLng);
          _updateMapAndRoute();
        });
  }

  Future<void> _loadLastDriverLocation() async {
    final client = Supabase.instance.client;
    try {
      final response = await client
          .from('driver_locations')
          .select('last_latitude, last_longitude')
          .eq('custom_user_id', widget.driverId)
          .single();

      if (response != null) {
        setState(() {
          _driverLocation = LatLng(
            response['last_latitude'],
            response['last_longitude'],
          );
        });
      }
    } catch (e) {
      print('No previous driver location: $e');
      setState(() {
        _driverLocation = null;
      });
    }
  }

  /// Fetch shipment locations from Supabase
  Future<void> _loadShipmentLocations() async {
    try {
      final response = await Supabase.instance.client
          .from('shipment')
          .select(
        'pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude',
      )
          .eq('assigned_driver', widget.driverId)
          .neq('booking_status', 'Completed')// deleted track Only active shipment
          .single();

      setState(() {
        pickupLocation = LatLng(
          response['pickup_latitude'],
          response['pickup_longitude'],
        );
        dropLocation = LatLng(
          response['dropoff_latitude'],
          response['dropoff_longitude'],
        );
      });
    } catch (e) {
      // No active shipment or error
      print('Error loading shipment: $e');
      setState(() {
        pickupLocation = null;
        dropLocation = null;
      });
    }
  }

  Future<void> _updateDriverLocationInDbFromLatLng(
      LatLng driverLocation,
      ) async {
    final client = Supabase.instance.client;

    await client.from('driver_locations').upsert({
      'custom_user_id': widget.driverId,
      'last_latitude': driverLocation.latitude,
      'last_longitude': driverLocation.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'custom_user_id');
  }

  /// Update marker, route, and distances
  Future<void> _updateMapAndRoute() async {
    if (_driverLocation == null ||
        pickupLocation == null ||
        dropLocation == null)
      return;

    _setMarkers();
    await _drawRoute(); // Blue
    await _drawDriverRoute(); // Red
    _calculateDistances();
  }

  /// Set markers for driver, pickup, drop
  void _setMarkers() {
    _markers.clear();
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: _driverLocation!,
          infoWindow: const InfoWindow(title: "You (Driver)"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    if (pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: pickupLocation!,
          infoWindow: const InfoWindow(title: "Pickup"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (dropLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("drop"),
          position: dropLocation!,
          infoWindow: const InfoWindow(title: "Drop"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  /// Draw route from pickup → drop
  Future<void> _drawRoute() async {
    if (pickupLocation == null || dropLocation == null) return;

    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: AppConfig.googleMapsApiKey,
    );

    final request = PolylineRequest(
      origin: PointLatLng(pickupLocation!.latitude, pickupLocation!.longitude),
      destination: PointLatLng(dropLocation!.latitude, dropLocation!.longitude),
      mode: TravelMode.driving,
    );

    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoords = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      // If last driver location exists, shorten blue line from there
      if (_driverLocation != null) {
        polylineCoords = _getRemainingRoute(polylineCoords, _driverLocation!);
      }

      setState(() {
        _bluePolylines.clear();
        _bluePolylines.add(
          Polyline(
            polylineId: const PolylineId("route_blue"),
            color: Colors.blue,
            width: 5,
            points: polylineCoords,
          ),
        );
      });
    }
  }

  Future<void> _drawDriverRoute() async {
    if (_driverLocation == null || dropLocation == null) return;

    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: AppConfig.googleMapsApiKey,
    );

    final request = PolylineRequest(
      origin: PointLatLng(
        _driverLocation!.latitude,
        _driverLocation!.longitude,
      ),
      destination: PointLatLng(dropLocation!.latitude, dropLocation!.longitude),
      mode: TravelMode.driving,
    );

    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoords = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        _redPolylines.clear();
        _redPolylines.add(
          Polyline(
            polylineId: const PolylineId("route_red"),
            color: Colors.red,
            width: 5,
            points: polylineCoords,
          ),
        );
      });
    }
  }

  /// Helper: shorten route to only remaining part
  List<LatLng> _getRemainingRoute(List<LatLng> fullRoute, LatLng driverPos) {
    // Find closest point index to driver
    int closestIndex = 0;
    double minDist = double.infinity;
    for (int i = 0; i < fullRoute.length; i++) {
      double d = _calculateDistance(
        driverPos.latitude,
        driverPos.longitude,
        fullRoute[i].latitude,
        fullRoute[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        closestIndex = i;
      }
    }
    return fullRoute.sublist(closestIndex);
  }

  /// Calculate distances traveled & remaining
  void _calculateDistances() {
    if (_driverLocation == null ||
        dropLocation == null ||
        pickupLocation == null)
      return;

    double distanceToDrop = _calculateDistance(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      dropLocation!.latitude,
      dropLocation!.longitude,
    );

    double totalRoute = _calculateDistance(
      pickupLocation!.latitude,
      pickupLocation!.longitude,
      dropLocation!.latitude,
      dropLocation!.longitude,
    );

    setState(() {
      _distanceTraveled = totalRoute - distanceToDrop;
      _distanceRemaining = distanceToDrop;
    });
  }

  double _calculateDistance(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_deg2rad(lat1)) *
                cos(_deg2rad(lat2)) *
                (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180);

  void _showErrorSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Route Tracking")),
      body:
      _driverLocation == null ||
          pickupLocation == null ||
          dropLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverLocation!,
              zoom: 12,
            ),
            markers: _markers,
            polylines: {..._bluePolylines, ..._redPolylines},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.indigo,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Distance traveled: ${_distanceTraveled.toStringAsFixed(2)} km",
                    ),
                    Text(
                      "Distance remaining: ${_distanceRemaining.toStringAsFixed(2)} km",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.zoom_out_map),
        onPressed: () {
          if (_mapController != null &&
              pickupLocation != null &&
              dropLocation != null) {
            LatLngBounds bounds = LatLngBounds(
              southwest: LatLng(
                min(
                  min(pickupLocation!.latitude, dropLocation!.latitude),
                  _driverLocation!.latitude,
                ),
                min(
                  min(pickupLocation!.longitude, dropLocation!.longitude),
                  _driverLocation!.longitude,
                ),
              ),
              northeast: LatLng(
                max(
                  max(pickupLocation!.latitude, dropLocation!.latitude),
                  _driverLocation!.latitude,
                ),
                max(
                  max(pickupLocation!.longitude, dropLocation!.longitude),
                  _driverLocation!.longitude,
                ),
              ),
            );

            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50),
            );
          }
        },
      ),
    );
  }
}
