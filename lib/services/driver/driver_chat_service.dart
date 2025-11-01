import 'package:supabase_flutter/supabase_flutter.dart';

class DriverService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getActiveShipmentsForDriver(String? driverId) async {
    if (driverId == null) {
      throw Exception('Driver not authenticated or custom_user_id is missing.');
    }

    final response = await _client
        .from('shipment')
        .select('shipment_id, pickup, drop, assigned_agent')
        .eq('assigned_driver', driverId)
        .filter('booking_status', 'in', [
      'Accepted',
      'En Route to Pickup',
      'Arrived at Pickup',
      'In Transit',
    ]).order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAssociatedOwners(String? driverId) async {
    if (driverId == null) {
      throw Exception('Driver not authenticated or custom_user_id is missing.');
    }

    final relationResponse = await _client
        .from('driver_relation')
        .select('owner_custom_id')
        .eq('driver_custom_id', driverId);

    final ownerIds = relationResponse
        .map((relation) => relation['owner_custom_id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();

    if (ownerIds.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> profiles = [];
    for (final id in ownerIds) {
      try {
        final profileResponse = await _client
            .from('user_profiles')
            .select('name, custom_user_id')
            .eq('custom_user_id', id)
            .maybeSingle();

        if (profileResponse != null) {
          profiles.add(profileResponse);
        }
      } catch (e) {
        print('Error fetching profile for owner $id: $e');
      }
    }
    return profiles;
  }
}

