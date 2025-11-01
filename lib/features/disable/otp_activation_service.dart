import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifications/notification_manager.dart';

// Make sure this line exists only once in the file
final _supabase = Supabase.instance.client;

/// Service for handling OTP-based account activation
class OtpActivationService {
  static final supabase = Supabase.instance.client;

  /// Sends OTP to user's email for account activation
  static Future<Map<String, dynamic>> sendActivationOtp({
    required String email,
  }) async {
    try {
      print('Attempting to send OTP to: $email');
      // Step 0: Check if the account is disabled by admin/agent before sending OTP
      // Get custom_user_id from email first
      final profileCheck = await supabase
          .from('user_profiles')
          .select('custom_user_id, account_disable')
          .eq('email', email)
          .maybeSingle();

      if (profileCheck != null && profileCheck['account_disable'] == true) {
        // Check if disabled by admin/agent using account_status_logs
        final disableLog = await supabase
            .from('account_status_logs')
            .select('performed_by_custom_id')
            .eq('target_custom_id', profileCheck['custom_user_id'])
            .eq('action_type', 'account_disabled')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (disableLog != null &&
            disableLog['performed_by_custom_id'] !=
                profileCheck['custom_user_id']) {
          // Account was disabled by someone else (admin/agent)
          return {
            'ok': false,
            'error':
            'Your account has been disabled by an admin/agent. Please use the "Request Access" option.',
          };
        }
      }
      // Try to send OTP with shouldCreateUser: true first with timeout
      await supabase.auth
          .signInWithOtp(
        email: email,
        shouldCreateUser: true, // Allow creating auth user for OTP
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
        throw Exception('Request timeout after 15 seconds'),
      );

      print('OTP sent successfully to: $email');
      return {'ok': true, 'message': 'OTP sent successfully to $email'};
    } catch (e) {
      print('First attempt failed: $e');

      // If that fails, try the original approach with timeout
      try {
        print('Trying second attempt with shouldCreateUser: false');
        await supabase.auth
            .signInWithOtp(email: email, shouldCreateUser: false)
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
          throw Exception('Second attempt timeout after 15 seconds'),
        );

        print('Second attempt successful for: $email');
        return {'ok': true, 'message': 'OTP sent successfully to $email'};
      } catch (e2) {
        print('Both attempts failed: $e2');

        // Check if it's a timeout or server error
        String errorMessage = e2.toString();
        if (errorMessage.contains('timeout') || errorMessage.contains('504')) {
          errorMessage =
          'Server timeout - please check your internet connection and try again';
        } else if (errorMessage.contains('otp_disabled')) {
          errorMessage = 'OTP is disabled in Supabase settings';
        } else if (errorMessage.contains('rate_limit')) {
          errorMessage =
          'Too many requests - please wait a moment and try again';
        }

        return {'ok': false, 'error': errorMessage};
      }
    }
  }

  /// Verifies OTP and activates the account
  static Future<Map<String, dynamic>> verifyOtpAndActivate({
    required String email,
    required String otpCode,
    required String customUserId,
  }) async {
    try {
      print('Verifying OTP for email: $email, customUserId: $customUserId');

      // Step 1: Verify the OTP
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: OtpType.email,
      );

      if (response.user == null) {
        return {'ok': false, 'error': 'Invalid OTP code'};
      }

      print('OTP verified successfully, activating account...');
      // Step 1.5: Prevent reactivation if admin/agent disabled the account
      final profileCheck = await supabase
          .from('user_profiles')
          .select('account_disable')
          .eq('custom_user_id', customUserId)
          .maybeSingle();

      if (profileCheck != null && profileCheck['account_disable'] == true) {
        // Check if disabled by admin/agent using account_status_logs
        final disableLog = await supabase
            .from('account_status_logs')
            .select('performed_by_custom_id')
            .eq('target_custom_id', customUserId)
            .eq('action_type', 'account_disabled')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (disableLog != null &&
            disableLog['performed_by_custom_id'] != customUserId) {
          // Account was disabled by someone else (admin/agent)
          return {
            'ok': false,
            'error':
            'This account was disabled by an admin/agent and cannot be reactivated via OTP. Please use the "Request Access" option.',
          };
        }
      }

      // Step 2: Update account_disable to false with additional logging
      final updateResult = await supabase
          .from('user_profiles')
          .update({
        'account_disable': false,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('custom_user_id', customUserId)
          .select();

      print('Account update result: $updateResult');

      // Verify the update was successful
      final verifyUpdate = await supabase
          .from('user_profiles')
          .select('account_disable, custom_user_id')
          .eq('custom_user_id', customUserId)
          .single();

      print(
        'Account disable status after update: ${verifyUpdate['account_disable']} for user: ${verifyUpdate['custom_user_id']}',
      );

      // Step 3: Add entry to account_status_logs
      await supabase.from('account_status_logs').insert({
        'target_custom_id': customUserId,
        'performed_by_custom_id': customUserId,
        'action_type': 'account_enabled',
        'reason': 'self_activation_via_otp',
        'metadata': {
          'activation_method': 'email_otp',
          'timestamp': DateTime.now().toIso8601String(),
          'email_used': email,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      // Step 4: Send notification to agent/truck owner if driver has relationship
      await _notifyOwnerAboutAccountActivation(customUserId);

      print(
        'Account disabled updated and logged for customUserId: $customUserId',
      );

      return {
        'ok': true,
        'message': 'Account activated successfully',
        'user_id': customUserId,
      };
    } catch (e) {
      print('Verification/activation failed: $e');
      return {'ok': false, 'error': 'Verification failed: ${e.toString()}'};
    }
  }

  /// Signs out the user (used after successful activation)
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      // Ignore signout errors
      print('SignOut error: $e');
    }
  }

  /// Send notification to agent/truck owner about account activation
  static Future<void> _notifyOwnerAboutAccountActivation(
      String customUserId,
      ) async {
    try {
      // Check if driver has relationship with agent or truck owner
      // First, let's check what columns actually exist in driver_relation table
      final relationshipResponse = await supabase
          .from('driver_relation')
          .select('*')
          .eq('driver_custom_id', customUserId)
          .maybeSingle();

      if (relationshipResponse == null) {
        print('No driver relation found for: $customUserId');
        return;
      }

      // Log the actual structure to see what columns exist
      print('Driver relation data: $relationshipResponse');

      // Try to get owner ID from available columns
      String? ownerId =
          relationshipResponse['owner_custom_id'] ??
              relationshipResponse['agent_custom_id'] ??
              relationshipResponse['truck_owner_custom_id'];

      if (ownerId == null) {
        print('No owner ID found in relation data');
        return;
      }

      // Get driver's name for the notification
      final driverResponse = await supabase
          .from('user_profiles')
          .select('name')
          .eq('custom_user_id', customUserId)
          .single();

      String driverName = driverResponse['name'] ?? 'Driver';

      // Send notification using NotificationManager
      await NotificationManager().createNotification(
        userId: ownerId,
        title: 'Driver Account Activated',
        message: '$driverName has activated their account.',
        type: 'account_status',
        sourceType: 'account_management',
        sourceId: customUserId,
      );

      print('Account activation notification sent to owner: $ownerId');
    } catch (e) {
      print('Error sending activation notification: $e');
      // Don't throw error as this is not critical for the main flow
    }
  }
}
// --- Add this at the very bottom of otp_activation_service.dart --- //

/// Call the backend RPC to toggle account status and add a log entry
Future<void> toggleAccountStatusRpc({
  required String customUserId,
  required bool disabled,
  required String changedBy,
  required String changedByRole, // 'admin' | 'agent' | 'user'
}) async {
  try {
    // Get the custom_user_id of the person performing the action
    String performedByCustomId = customUserId; // Default to self

    try {
      // Get the current authenticated user's custom_user_id
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final performerProfile = await _supabase
            .from('user_profiles')
            .select('custom_user_id')
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (performerProfile != null) {
          performedByCustomId = performerProfile['custom_user_id'];
          print('✅ Performer custom_id: $performedByCustomId');
        }
      }
    } catch (e) {
      print('Warning: Could not determine performer custom_id: $e');
    }

    // Determine if this is an admin action (performer != target)
    final isAdminAction = performedByCustomId != customUserId;

    print('🔍 Toggle Status Details:');
    print('   - Target: $customUserId');
    print('   - Performer: $performedByCustomId');
    print('   - Is Admin Action: $isAdminAction');
    print('   - Disabled: $disabled');
    print('   - Changed By Role: $changedByRole');

    // Update the user_profiles table with tracking columns
    final updateData = {
      'account_disable': disabled,
      'disabled_by_admin':
      isAdminAction && disabled, // Set to true only if admin is disabling
      'account_disabled_by_role': disabled ? changedByRole : null,
      'last_changed_by': performedByCustomId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    print('🔍 Update Data: $updateData');

    try {
      final result = await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('custom_user_id', customUserId)
          .select();

      print('✅ User profile updated successfully');
      print('🔍 Update Result: $result');
    } catch (updateError) {
      print('❌ Error updating user profile: $updateError');
      print('❌ Error type: ${updateError.runtimeType}');

      // Try to get more details if it's a PostgrestException
      if (updateError is PostgrestException) {
        print('❌ Postgrest Error Details:');
        print('   - Message: ${updateError.message}');
        print('   - Code: ${updateError.code}');
        print('   - Details: ${updateError.details}');
        print('   - Hint: ${updateError.hint}');
      }
      rethrow;
    }

    // Log the status change in account_status_logs table
    await _supabase.from('account_status_logs').insert({
      'target_custom_id': customUserId,
      'performed_by_custom_id': performedByCustomId,
      'action_type': disabled ? 'account_disabled' : 'account_enabled',
      'reason': disabled
          ? 'Account disabled by $changedByRole'
          : 'Account enabled by $changedByRole',
      'metadata': {
        'changed_by': changedBy,
        'changed_by_role': changedByRole,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'created_at': DateTime.now().toIso8601String(),
    });

    print('✅ Account status toggled and logged successfully');
  } catch (e) {
    print('❌ Error in toggleAccountStatusRpc: $e');
    rethrow;
  }
}