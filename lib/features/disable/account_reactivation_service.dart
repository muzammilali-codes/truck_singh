import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifications/notification_manager.dart';

/// Service for handling account reactivation requests
class AccountReactivationService {
  static final supabase = Supabase.instance.client;

  /// Check who disabled the account and return the disable info
  /// Uses only user_profiles table for simplicity and reliability
  static Future<Map<String, dynamic>?> getAccountDisableInfo({
    required String customUserId,
  }) async {
    try {
      // Get user profile with disable info
      final profileResponse = await supabase
          .from('user_profiles')
          .select(
        'account_disable, disabled_by_admin, account_disabled_by_role, last_changed_by',
      )
          .eq('custom_user_id', customUserId)
          .maybeSingle();

      if (profileResponse == null ||
          profileResponse['account_disable'] != true) {
        return null; // Account is not disabled
      }

      print('🔍 ProfileResponse for $customUserId: $profileResponse');

      final disabledByAdmin =
          profileResponse['disabled_by_admin'] as bool? ?? false;
      final lastChangedBy = profileResponse['last_changed_by'] as String?;
      final disabledByRole =
      profileResponse['account_disabled_by_role'] as String?;

      print('🔍 disabledByAdmin: $disabledByAdmin');
      print('🔍 lastChangedBy: $lastChangedBy');
      print('🔍 customUserId: $customUserId');
      print(
        '🔍 Check: lastChangedBy != customUserId = ${lastChangedBy != customUserId}',
      );

      // If disabled_by_admin flag is true, it was disabled by admin/agent/truckowner
      if (disabledByAdmin &&
          lastChangedBy != null &&
          lastChangedBy != customUserId) {
        print('🔍 Fetching disabler profile for: $lastChangedBy');

        // Get the admin/agent/truckowner profile who disabled the account
        final disablerProfile = await supabase
            .from('user_profiles')
            .select('custom_user_id, name, role, email, mobile_number')
            .eq('custom_user_id', lastChangedBy)
            .maybeSingle();

        print('🔍 Disabler Profile: $disablerProfile');

        final disablerRole =
            disablerProfile?['role'] ?? disabledByRole ?? 'admin';

        print('🔍 Disabler Role: $disablerRole');

        // Verify the disabler has authority (admin, agent, or truckowner)
        // Convert to lowercase for case-insensitive comparison and handle variations
        final roleLower = disablerRole.toString().toLowerCase();
        final hasAuthority = [
          'admin',
          'agent',
          'truckowner',
          'truck_owner', // Handle underscore variant
          'company', // Some places use 'company' for truckowner
        ].contains(roleLower);

        print('🔍 Has Authority: $hasAuthority');

        if (hasAuthority) {
          return {
            'is_self_disabled': false,
            'disabled_by': lastChangedBy,
            'disabler_name': disablerProfile?['name'] ?? 'Administrator',
            'disabler_role': disablerRole,
            'disabler_email': disablerProfile?['email'],
            'disabler_phone': disablerProfile?['mobile_number'],
            'reason': 'Account disabled by $disablerRole',
          };
        } else {
          print('⚠️ Disabler does not have authority, role: $disablerRole');
        }
      } else {
        print('⚠️ Conditions not met for admin disable:');
        print('   - disabledByAdmin: $disabledByAdmin');
        print('   - lastChangedBy != null: ${lastChangedBy != null}');
        print(
          '   - lastChangedBy != customUserId: ${lastChangedBy != customUserId}',
        );
      }

      // Self-disabled (or disabled_by_admin is false)
      return {
        'is_self_disabled': true,
        'disabled_by': customUserId,
        'reason': 'Self-disabled account',
      };
    } catch (e) {
      print('Error getting account disable info: $e');
      return null;
    }
  }

  /// Send reactivation request to the admin/agent who disabled the account
  static Future<Map<String, dynamic>> sendReactivationRequest({
    required String requesterId,
    required String requesterName,
    required String disablerId,
    required String requestMessage,
  }) async {
    try {
      // Get disabler's user_id for notification
      final disablerProfile = await supabase
          .from('user_profiles')
          .select('user_id, name, role')
          .eq('custom_user_id', disablerId)
          .maybeSingle();

      if (disablerProfile == null) {
        return {
          'ok': false,
          'error': 'Could not find the admin/agent who disabled your account',
        };
      }

      // Create notification for the disabler
      await NotificationManager().createNotification(
        userId: disablerProfile['user_id'],
        title: 'Account Reactivation Request',
        message:
        '$requesterName is requesting to reactivate their account. Message: "$requestMessage"',
        type: 'account_reactivation_request',
        sourceType: 'account_management',
        sourceId: requesterId,
      );

      // Log the reactivation request in account_status_logs
      await supabase.from('account_status_logs').insert({
        'target_custom_id': requesterId,
        'performed_by_custom_id': requesterId,
        'action_type': 'reactivation_requested',
        'reason': 'User requested reactivation from disabler',
        'metadata': {
          'request_message': requestMessage,
          'sent_to': disablerId,
          'disabler_name': disablerProfile['name'],
          'timestamp': DateTime.now().toIso8601String(),
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'ok': true,
        'message': 'Reactivation request sent successfully',
        'disabler_name': disablerProfile['name'],
        'disabler_role': disablerProfile['role'],
      };
    } catch (e) {
      print('Error sending reactivation request: $e');
      return {
        'ok': false,
        'error': 'Failed to send reactivation request: ${e.toString()}',
      };
    }
  }

  /// Enable an account (called by admin/agent who disabled it)
  static Future<Map<String, dynamic>> enableAccount({
    required String targetCustomId,
    required String performedByCustomId,
    String? reason,
  }) async {
    try {
      // Update account_disable to false
      await supabase
          .from('user_profiles')
          .update({
        'account_disable': false,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('custom_user_id', targetCustomId);

      // Log the enable action
      await supabase.from('account_status_logs').insert({
        'target_custom_id': targetCustomId,
        'performed_by_custom_id': performedByCustomId,
        'action_type': 'account_enabled',
        'reason': reason ?? 'Enabled by admin/agent',
        'metadata': {
          'enabled_method': 'admin_approval',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to the user whose account was enabled
      final targetProfile = await supabase
          .from('user_profiles')
          .select('user_id, name')
          .eq('custom_user_id', targetCustomId)
          .maybeSingle();

      if (targetProfile != null) {
        await NotificationManager().createNotification(
          userId: targetProfile['user_id'],
          title: 'Account Reactivated',
          message: 'Your account has been reactivated. You can now log in.',
          type: 'account_status',
          sourceType: 'account_management',
          sourceId: performedByCustomId,
        );
      }

      return {'ok': true, 'message': 'Account enabled successfully'};
    } catch (e) {
      print('Error enabling account: $e');
      return {
        'ok': false,
        'error': 'Failed to enable account: ${e.toString()}',
      };
    }
  }

  /// Check if there's a pending reactivation request
  static Future<bool> hasPendingReactivationRequest({
    required String customUserId,
  }) async {
    try {
      final recentRequest = await supabase
          .from('account_status_logs')
          .select('created_at')
          .eq('target_custom_id', customUserId)
          .eq('action_type', 'reactivation_requested')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (recentRequest == null) return false;

      // Check if request was made in the last 24 hours
      final requestTime = DateTime.parse(recentRequest['created_at']);
      final now = DateTime.now();
      final difference = now.difference(requestTime);

      return difference.inHours < 24;
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }
}