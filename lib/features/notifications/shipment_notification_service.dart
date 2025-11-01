import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'notification_manager.dart';

class ShipmentNotificationService {
  static final ShipmentNotificationService _instance =
  ShipmentNotificationService._internal();
  factory ShipmentNotificationService() => _instance;
  ShipmentNotificationService._internal();

  final NotificationManager _notificationManager = NotificationManager();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Updates a shipment's status and triggers notifications for all relevant parties.
  Future<void> updateShipmentStatus({
    required String shipmentId,
    required String newStatus,
    String? notes,
    String? location,
  }) async {
    try {
      final shipment = await _supabase
          .from('shipment')
          .select('shipper_id, assigned_driver, assigned_agent, pickup, drop')
          .eq('shipment_id', shipmentId)
          .single();

      // Update the main shipment record
      await _supabase
          .from('shipment')
          .update({'booking_status': newStatus})
          .eq('shipment_id', shipmentId);

      // ADD THIS LINE
      debugPrint(">>> Inserting shipment update. Driver ID from fetched data: ${shipment?['assigned_driver']}");

      // Create a log entry in the updates table
      await _supabase.from('shipment_updates').insert({
        'shipment_id': shipmentId,
        'status': newStatus,
        'notes': notes ?? 'Status updated to $newStatus',
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
        // --- START FIX ---
        'assigned_driver': shipment['assigned_driver'], // Pass the driver ID
        'updated_by_user_id': _supabase.auth.currentUser!.id // Pass the current user's ID
        // --- END FIX ---
      });

      // Send notifications to all involved users
      await _createShipmentStatusNotifications(shipment, newStatus, shipmentId);

      debugPrint('✅ Shipment status updated: $shipmentId -> $newStatus');
    } catch (e) {
      debugPrint('❌ Error updating shipment status: $e');
      rethrow;
    }
  }

  /// Gathers all relevant user IDs and sends them a status update notification.
  Future<void> _createShipmentStatusNotifications(
      Map<String, dynamic> shipment,
      String newStatus,
      String shipmentId,
      ) async {
    try {
      final pickup = shipment['pickup'] ?? 'origin';
      final drop = shipment['drop'] ?? 'destination';

      // Collect all custom user IDs associated with the shipment
      final customUserIds = <String>{
        if (shipment['shipper_id'] != null) shipment['shipper_id'],
        if (shipment['assigned_driver'] != null) shipment['assigned_driver'],
        if (shipment['assigned_agent'] != null) shipment['assigned_agent'],
      }.toList();

      if (customUserIds.isEmpty) return;

      // Fetch all user profiles in a single query for efficiency
      final profiles = await _supabase
          .from('user_profiles')
          .select('user_id')
          .inFilter('custom_user_id', customUserIds);

      // Create notifications for each fetched user
      for (final profile in profiles) {
        final userId = profile['user_id'];
        if (userId != null) {
          await _notificationManager.createShipmentNotification(
            userId: userId,
            shipmentId: shipmentId,
            status: newStatus,
            pickup: pickup,
            drop: drop,
          );
        }
      }
      debugPrint(
        '✅ Created status notifications for ${profiles.length} users for shipment $shipmentId',
      );
    } catch (e) {
      debugPrint('❌ Error creating shipment status notifications: $e');
    }
  }

  /// Assigns a driver to a shipment and notifies relevant parties.
  Future<void> assignDriverToShipment({
    required String shipmentId,
    required String driverCustomId,
  }) async {
    try {
      await _supabase
          .from('shipment')
          .update({'assigned_driver': driverCustomId})
          .eq('shipment_id', shipmentId);

      // Fetch shipment details needed for the notification message
      final shipment = await _supabase
          .from('shipment')
          .select('assigned_agent, pickup, drop')
          .eq('shipment_id', shipmentId)
          .single();

      await _createDriverAssignmentNotifications(
        shipment,
        driverCustomId,
        shipmentId,
      );

      debugPrint('✅ Driver $driverCustomId assigned to shipment $shipmentId');
    } catch (e) {
      debugPrint('❌ Error assigning driver: $e');
      rethrow;
    }
  }

  /// Creates notifications after a driver has been assigned to a shipment.
  Future<void> _createDriverAssignmentNotifications(
      Map<String, dynamic> shipment,
      String driverCustomId,
      String shipmentId,
      ) async {
    try {
      final pickup = shipment['pickup'] ?? 'origin';
      final drop = shipment['drop'] ?? 'destination';

      // Get profiles for the driver and the agent (if any)
      final profiles = await _supabase
          .from('user_profiles')
          .select('user_id, name, custom_user_id')
          .inFilter('custom_user_id', [
        driverCustomId,
        shipment['assigned_agent'],
      ]);

      String driverName = driverCustomId;

      // Notify the driver they have a new shipment
      final driverProfile = profiles.firstWhere(
            (p) => p['custom_user_id'] == driverCustomId,
        orElse: () => {},
      );
      if (driverProfile.isNotEmpty) {
        driverName = driverProfile['name'] ?? driverCustomId;
        await _notificationManager.createNotification(
          userId: driverProfile['user_id'],
          title: 'New Shipment Assignment',
          message:
          'You have been assigned to shipment $shipmentId from $pickup to $drop.',
          type: 'shipment',
          sourceId: shipmentId,
        );
      }

      // Notify the agent that a driver was assigned
      final agentProfile = profiles.firstWhere(
            (p) => p['custom_user_id'] == shipment['assigned_agent'],
        orElse: () => {},
      );
      if (agentProfile.isNotEmpty) {
        await _notificationManager.createNotification(
          userId: agentProfile['user_id'],
          title: 'Driver Assigned to Shipment',
          message:
          'Driver $driverName has been assigned to shipment $shipmentId.',
          type: 'shipment',
          sourceId: shipmentId,
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating driver assignment notifications: $e');
    }
  }
}
