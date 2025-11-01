import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

import '../../services/driver/background_location_service.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final supabase = Supabase.instance.client;
  GoogleMapController? mapController;
  Marker? _driverMarker;
  BitmapDescriptor? _truckIcon;
  bool _isTrackingEnabled = false;
  bool _isLoading = true;
  String? _customUserId;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(19.0330, 73.0297), // Navi Mumbai
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Load UI assets and user data in parallel for faster startup.
    await Future.wait([_loadTruckIcon(), _loadCustomUserId()]);

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    service.on('update').listen((event) {
      if (event != null && event['lat'] != null && event['lng'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateLocationOnMap(event['lat'], event['lng'],heading: event['heading']??0);
          }
        });
      }
    });

    if (mounted) {
      setState(() {
        _isTrackingEnabled = isRunning;
        _isLoading = false;
      });
    }
  }

  /// Fetches the custom user ID from the user_profiles table.
  Future<void> _loadCustomUserId() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _showErrorSnackBar("User not authenticated.");
        return;
      }
      final response = await supabase
          .from('user_profiles')
          .select('custom_user_id')
          .eq('user_id', userId)
          .single();

      if (mounted) {
        setState(() {
          _customUserId = response['custom_user_id'];
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Could not load user profile.");
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTruckIcon();
  }

  Future<void> _loadTruckIcon() async {
    try {
      final config = createLocalImageConfiguration(context); // Safer cross-device.
      _truckIcon = await BitmapDescriptor.fromAssetImage(
        config,
        'assets/cargo-truck.png',
      );
      setState(() {}); // Refresh with the loaded icon!
    } catch (e) {
      print("Error loading truck icon: $e");
      _truckIcon = BitmapDescriptor.defaultMarker;
      setState(() {});
    }
  }



  @override
  void dispose() {
    super.dispose();
  }

  /// Toggles the background tracking service on or off.
  Future<void> _toggleTracking() async {
    // First, ensure all necessary permissions are granted.
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      // The _handleLocationPermission function shows its own error messages.
      if (mounted) setState(() => _isTrackingEnabled = false);
      return;
    }

    // If permissions are granted, toggle the state and the service.
    setState(() => _isTrackingEnabled = !_isTrackingEnabled);

    if (_isTrackingEnabled) {
      await BackgroundLocationService.startService();
      _showSnackBar("Live tracking service started.");
    } else {
      BackgroundLocationService.stopService();
      _showSnackBar("Live tracking service stopped.");
    }
  }

  /// Handles the complete, multi-step permission flow for background location.
  Future<bool> _handleLocationPermission() async {
    // 1. Request Notification permission (required for Android 13+).
    if (await handler.Permission.notification.request().isDenied) {
      _showErrorSnackBar(
        "Notification permission is required for the tracking service.",
      );
      return false;
    }

    // 2. Check if the device's location services are enabled using permission_handler.
    final serviceStatus = await handler.Permission.location.serviceStatus;
    if (serviceStatus.isDisabled) {
      _showErrorSnackBar(
        "Please enable location services in your device settings.",
      );
      // This opens the general app settings page.
      await handler.openAppSettings();
      return false;
    }

    // 3. Request "While in Use" location permission.
    var permissionStatus = await handler.Permission.location.request();
    if (permissionStatus.isDenied) {
      _showErrorSnackBar("Location permission is required to start tracking.");
      return false;
    }

    if (permissionStatus.isPermanentlyDenied) {
      _showErrorSnackBar(
        "Location permission is permanently denied. Please enable it in your phone's settings.",
      );
      await handler.openAppSettings();
      return false;
    }

    // 4. If we have "While in Use", check if we need to upgrade to "Always".
    if (await handler.Permission.locationAlways.isDenied) {
      // Show a dialog explaining why we need the "Always" permission.
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Background Location Required"),
          content: const Text(
            "To track your location when the app is closed, please upgrade the permission to 'Allow all the time'.\n\n"
                "1. Tap 'Go to Settings'.\n"
                "2. Tap 'Permissions', then 'Location'.\n"
                "3. Select 'Allow all the time'.\n\n"
                "Afterward, please return to the app and tap the tracking switch again.",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Go to Settings"),
              onPressed: () {
                handler.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      // After the dialog, the user must manually change the setting.
      // We return false because they need to tap the switch again.
      return false;
    }

    // 5. If we reach here, we have "Always" permission.
    return true;
  }

  /// Updates the driver's marker on the map.
  void _updateLocationOnMap(double lat, double lng,{double heading =0}) {
    if (!mounted) return;
    final newLatLng = LatLng(lat, lng);
    setState(() {
      _driverMarker = Marker(
        markerId: const MarkerId("driver"),
        position: newLatLng,
        icon: _truckIcon ?? BitmapDescriptor.defaultMarker,
        rotation:heading,
        anchor: const Offset(0.5, 0.5),
      );
    });
    mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Switch(
                value: _isTrackingEnabled,
                onChanged: (value) => _toggleTracking(),
                activeTrackColor: Colors.green.shade200,
                activeColor: Colors.green,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: _kInitialPosition,
        markers: _driverMarker != null ? {_driverMarker!} : {},
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}