import 'package:supabase_flutter/supabase_flutter.dart';

class AgentService {
  final SupabaseClient _client = Supabase.instance.client;

  // Helper to get the current user's custom ID
  String? get _currentAgentId {
    return _client.auth.currentUser?.userMetadata?['custom_user_id'];
  }

  // Fetches all active shipments assigned to the current agent
  Future<List<Map<String, dynamic>>> getActiveShipmentsForAgent() async {
    final agentId = _currentAgentId;
    if (agentId == null) {
      throw Exception('Agent not authenticated or custom_user_id is missing.');
    }

    // Query the shipment table for active shipments assigned to this agent
    final response = await _client
        .from('shipment')
        .select('shipment_id, pickup, drop, assigned_driver')
        .eq('assigned_agent', agentId)
        .filter('booking_status', 'in', [
      'Accepted',
      'En Route to Pickup',
      'Arrived at Pickup',
      'In Transit',
    ]).order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // New: Fetches all drivers related to the current agent
  Future<List<Map<String, dynamic>>> getRelatedDrivers() async {
    final agentId = _currentAgentId;
    if (agentId == null) {
      throw Exception('Agent not authenticated or custom_user_id is missing.');
    }

    // 1. Find all driver IDs related to the agent
    final relationsResponse = await _client
        .from('driver_relation')
        .select('driver_custom_id')
        .eq('owner_custom_id', agentId);

    final driverIds = relationsResponse
        .map((relation) => relation['driver_custom_id'] as String)
        .toList();

    if (driverIds.isEmpty) {
      return []; // Return an empty list if no drivers are found
    }

    // 2. Fetch the full profiles for those driver IDs
    final profilesResponse = await _client
        .from('user_profiles')
        .select('name, custom_user_id')
        .inFilter('custom_user_id', driverIds);

    return List<Map<String, dynamic>>.from(profilesResponse);
  }
}
