import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ShipmentManager {
  static final supabase = Supabase.instance.client;
  static Future<void> updateShipmentStatus(
    String shipmentId,
    String newStatus,
  ) async {
    try {
      await supabase
          .from('shipment')
          .update({'booking_status': newStatus}).eq('shipment_id', shipmentId);

      debugPrint(
          "✅ Shipment $shipmentId status updated to $newStatus. Webhook will trigger notification.");
    } catch (e) {
      debugPrint('❌ Error in updateShipmentStatus: $e');
      rethrow;
    }
  }
}
