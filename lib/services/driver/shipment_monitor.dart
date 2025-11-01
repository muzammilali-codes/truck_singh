import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShipmentMonitor {
  final SupabaseClient supabaseClient;
  final String customUserId;
  final Function(Map<String, dynamic>?) onShipmentUpdate;

  Timer? _shipmentCheckTimer;

  ShipmentMonitor({
    required this.supabaseClient,
    required this.customUserId,
    required this.onShipmentUpdate,
  });

  void start() {
    _checkForShipment();
    _shipmentCheckTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkForShipment(),
    );
  }

  void stop() {
    _shipmentCheckTimer?.cancel();
  }

  Future<void> _checkForShipment() async {
    print('[ShipmentMonitor] Checking for new active shipment...');
    try {
      final activeStatuses = [
        'Accepted',
        'En Route to Pickup',
        'Arrived at Pickup',
        'In Transit',
      ];
      final response = await supabaseClient
          .from('shipment')
          .select()
          .eq('assigned_driver', customUserId)
          .inFilter(
            'booking_status',
            activeStatuses,
          )
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      onShipmentUpdate(response);
    } catch (e) {
      print('[ShipmentMonitor] Error fetching active shipment: $e');
    }
  }
}
