import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notifications/real_time_notification_service.dart';
import 'location_tracking_manager.dart';
import 'shipment_monitor.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  _runServiceLogic(service);
}

void _runServiceLogic(ServiceInstance service) async {
  LocationTrackingManager? locationTracker;
  ShipmentMonitor? shipmentMonitor;
  final notificationService = RealTimeNotificationService();
  service.on('stopService').listen((event) {
    locationTracker?.stop();
    shipmentMonitor?.stop();
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final supabaseUrl = prefs.getString('supabaseUrl');
    final supabaseAnonKey = prefs.getString('supabaseAnonKey');
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception("Supabase credentials not found in SharedPreferences.");
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final supabaseClient = Supabase.instance.client;
    await notificationService.initialize();
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      final userId = prefs.getString('current_user_id');
      if (userId != null) {
        await notificationService.checkForNewNotifications(userId: userId);
      }
    });

    final user = await _awaitUserSession(supabaseClient.auth);
    if (user != null) {
      final driverProfile = await _fetchDriverProfile(supabaseClient, user.id);
      if (driverProfile != null) {
        final customUserId = driverProfile['custom_user_id'];

        locationTracker = LocationTrackingManager(
          serviceInstance: service,
          supabaseClient: supabaseClient,
          userId: user.id,
          customUserId: customUserId,
        );
        locationTracker.start();

        shipmentMonitor = ShipmentMonitor(
          supabaseClient: supabaseClient,
          customUserId: customUserId,
          onShipmentUpdate: (shipment) {
            locationTracker?.setActiveShipment(shipment);
          },
        );
        shipmentMonitor.start();
      } else {
        throw Exception("Driver profile not found.");
      }
    } else {
      throw Exception("User not signed in.");
    }
  } catch (e) {
    print("Error during background service startup: $e");
    service.stopSelf();
  }
}

Future<User?> _awaitUserSession(GoTrueClient auth) async {
  final completer = Completer<User?>();
  if (auth.currentUser != null) {
    return auth.currentUser;
  }
  final subscription = auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn && data.session?.user != null) {
      if (!completer.isCompleted) completer.complete(data.session!.user);
    }
  });
  Future.delayed(const Duration(seconds: 15), () {
    if (!completer.isCompleted) completer.complete(auth.currentUser);
  });
  completer.future.whenComplete(() => subscription.cancel());
  return completer.future;
}

Future<Map<String, dynamic>?> _fetchDriverProfile(
  SupabaseClient client,
  String userId,
) async {
  try {
    return await client
        .from('user_profiles')
        .select('custom_user_id, truck_owner_id')
        .eq('user_id', userId)
        .single();
  } catch (e) {
    print('Error fetching driver profile in background: $e');
    return null;
  }
}
