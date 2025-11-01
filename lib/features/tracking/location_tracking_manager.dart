import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/driver/geofence_service.dart';
import '../../services/driver/local_database_helper.dart';
import '../../services/driver/notification_helper.dart';

class LocationTrackingManager {
  final ServiceInstance serviceInstance;
  final SupabaseClient supabaseClient;
  final String userId;
  final String customUserId;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _syncTimer;
  Map<String, dynamic>? _activeShipment;

  LocationTrackingManager({
    required this.serviceInstance,
    required this.supabaseClient,
    required this.userId,
    required this.customUserId,
  });

  void setActiveShipment(Map<String, dynamic>? shipment) {
    _activeShipment = shipment;
  }

  void start() {
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _syncOfflineLocations(),
    );

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "Tracking Service",
        notificationText: "Location is being tracked in the background",
      ),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onLocationUpdate, onError: _onLocationError);
  }

  void stop() {
    _positionStreamSubscription?.cancel();
    _syncTimer?.cancel();
  }

  Future<void> _onLocationUpdate(Position position) async {
    final payload = {
      'custom_user_id': customUserId,
      'user_id': userId,
      'location_lat': position.latitude,
      'location_lng': position.longitude,
      'last_updated_at': DateTime.now().toIso8601String(),
    };

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await LocalDatabaseHelper.instance.insertLocation(payload);
      NotificationHelper.updateNotification(
        'Tracking Active (Offline)',
        'Location saved locally.',
      );
    } else {

      // --- START: REPLACE the old try...catch block with this ---
      await _syncOfflineLocations(); // Syncs old data first
      try {
        // Call the database function instead of using upsert
        await supabaseClient.rpc(
          'update_driver_loc',
          params: {
            'user_id_input': userId,
            'custom_user_id_input': customUserId,
            'longitude_input': position.longitude,
            'latitude_input': position.latitude,
            'heading_input': position.heading,
            'speed_input': position.speed,
            'shipment_id_input': _activeShipment?['shipment_id'], // Pass shipment ID if available
          },
        );

        // If successful, show this notification:
        final currentTime = DateFormat('HH:mm').format(DateTime.now());
        NotificationHelper.updateNotification(
          'Tracking Active',
          'Location updated at $currentTime',
        );

      } catch (e) {
        // If the RPC call fails, show this notification and print the error
        print(">>> DATABASE UPDATE FAILED <<< Error calling RPC: $e");

        // --- THIS IS THE MODIFIED LINE ---
        NotificationHelper.updateNotification(
          'Upload Failed again',
          'Error: ${e.toString()}', // Show the actual error message
        );
        // --- END OF MODIFICATION ---
      }
// --- END: Replacement ---
    }

    if (_activeShipment != null) {
      final newStatus = await GeofenceService.checkGeofences(
        position,
        _activeShipment!,
      );
      if (newStatus != null) {
        _activeShipment!['booking_status'] = newStatus;
      }
    }

    serviceInstance.invoke('update', {
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  void _onLocationError(error) {
    NotificationHelper.updateNotification(
      'Tracking Error',
      'Could not get location.',
    );
  }

  Future<void> _syncOfflineLocations() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    final dbHelper = LocalDatabaseHelper.instance;
    final offlineLocations = await dbHelper.getAllLocations();
    if (offlineLocations.isNotEmpty) {
      try {
        await supabaseClient
            .from('driver_locations')
            .upsert(offlineLocations, onConflict: 'user_id');
        await dbHelper.clearAllLocations();
      } catch (e) {
        print("Error during offline sync: $e");
      }
    }
  }
}
