import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Debug function to check current user admin status
  static Future<Map<String, dynamic>> debugCurrentUserStatus() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'logged_in': false, 'error': 'No user logged in'};
      }

      final profile = await _supabase
          .from('user_profiles')
          .select('custom_user_id, role, email, name')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      return {
        'logged_in': true,
        'user_id': currentUser.id,
        'email': currentUser.email,
        'profile': profile,
        'is_admin': profile?['role']?.toString().toLowerCase() == 'admin',
      };
    } catch (e) {
      return {'logged_in': false, 'error': e.toString()};
    }
  }

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('🐛 Admin Check: No current user');
        return false;
      }

      final profile = await _supabase
          .from('user_profiles')
          .select('role, custom_user_id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      print('🔍 Admin Check Profile: $profile');

      final role = profile?['role']?.toString().toLowerCase();
      final customId = profile?['custom_user_id']?.toString();

      // Check if user is admin or agent with admin permissions
      final isAdmin = role == 'admin';
      final isAgentWithAdminPerms =
          role == 'agent' && customId?.startsWith('AGNT') == true;

      print(
        '🔍 Admin Check Result: isAdmin=$isAdmin, isAgentWithPerms=$isAgentWithAdminPerms',
      );

      return isAdmin || isAgentWithAdminPerms;
    } catch (e) {
      print('🐛 Admin Check: Error checking admin status: $e');
      return false;
    }
  }

  /// Create admin user - CONSOLIDATED VERSION
  /// Attempts to keep the creator logged in using multiple strategies
  /// Compatible with both String and int parameter types
  static Future<Map<String, dynamic>> createAdminUser({
    required String email,
    required String password,
    String? name,
    required dynamic dateOfBirth, // Can be String or int
    required dynamic mobileNumber, // Can be String or int
  }) async {
    try {
      // Handle type conversions for compatibility
      final String dateOfBirthStr = dateOfBirth is String
          ? dateOfBirth
          : (dateOfBirth is int
          ? DateTime.fromMillisecondsSinceEpoch(
        dateOfBirth,
      ).toIso8601String()
          : DateTime(1990, 1, 1).toIso8601String());

      final String mobileNumberStr = mobileNumber is String
          ? mobileNumber
          : mobileNumber.toString();

      // Verify current user is admin FIRST
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception(
          'No user is currently logged in. Please log in as an admin first.',
        );
      }

      final currentUserId = currentUser.id;
      final currentUserEmail = currentUser.email;
      print('🔍 CREATOR: $currentUserEmail (ID: $currentUserId)');

      // Get creator's admin profile and verify permissions
      final creatorProfile = await _supabase
          .from('user_profiles')
          .select('custom_user_id, role')
          .eq('user_id', currentUserId)
          .maybeSingle();

      print('🔍 CREATOR PROFILE: $creatorProfile');

      String? creatorAdminId = creatorProfile?['custom_user_id'];
      final creatorRole = creatorProfile?['role']?.toString();

      // Verify admin status
      final isAdmin = creatorRole?.toLowerCase() == 'admin';
      final isAgentWithAdminPerms =
          creatorRole?.toLowerCase() == 'agent' &&
              creatorAdminId?.startsWith('AGNT') == true;

      if (!isAdmin && !isAgentWithAdminPerms) {
        throw Exception(
          'Access denied: Only admins can create admin users. Your role: $creatorRole',
        );
      }

      // Fallback for main admin
      if (creatorAdminId == null && currentUserEmail == 'admin@gmail.com') {
        creatorAdminId = 'ADM5478';
      }

      if (creatorAdminId == null) {
        throw Exception(
          'Creator admin profile not found. Please ensure you are logged in as a valid admin.',
        );
      }

      print('✅ CREATOR ADMIN ID: $creatorAdminId');

      // Check for duplicate email
      final existingUser = await _supabase
          .from('user_profiles')
          .select('email, custom_user_id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception(
          'User with email $email already exists (ID: ${existingUser['custom_user_id']})',
        );
      }

      // Generate unique admin ID
      String customUserId;
      int attempts = 0;
      do {
        final random =
            DateTime.now().millisecond +
                DateTime.now().second * 1000 +
                attempts;
        final shortId = (random % 10000).toString().padLeft(4, '0');
        customUserId = 'ADM$shortId';

        final existingId = await _supabase
            .from('user_profiles')
            .select('custom_user_id')
            .eq('custom_user_id', customUserId)
            .maybeSingle();

        if (existingId == null) break;
        attempts++;
      } while (attempts < 10);

      if (attempts >= 10) {
        throw Exception('Failed to generate unique admin ID after 10 attempts');
      }

      print('🆔 NEW ADMIN ID: $customUserId');

      // STRATEGY 1: Try Admin API first (keeps session intact)
      try {
        print('🔄 Attempting Admin API method...');

        final adminResponse = await _supabase.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
            userMetadata: {
              'name': name ?? 'Admin User',
              'role': 'Admin',
              'custom_user_id': customUserId,
            },
          ),
        );

        if (adminResponse.user != null) {
          final newUserId = adminResponse.user!.id;
          print('✅ USER CREATED VIA ADMIN API: $newUserId');

          // Create profile
          await _createUserProfile(
            userId: newUserId,
            customUserId: customUserId,
            email: email,
            name: name,
            creatorAdminId: creatorAdminId,
            dateOfBirth: dateOfBirthStr,
            mobileNumber: mobileNumberStr,
          );

          // Verify admin is still logged in
          final stillLoggedIn =
              _supabase.auth.currentUser?.email?.toLowerCase() ==
                  currentUserEmail?.toLowerCase();
          print('✅ ADMIN STILL LOGGED IN: $stillLoggedIn');

          return {
            'success': true,
            'admin_id': customUserId,
            'creator_id': creatorAdminId,
            'message':
            'Admin $customUserId created successfully! You remain logged in.',
            'requires_reauth': false,
            'method': 'admin_api',
          };
        }
      } catch (adminApiError) {
        print('⚠️ Admin API failed: $adminApiError');
      }

      // STRATEGY 2: Session preservation method
      print('🔄 Using session preservation method...');
      return await _createWithSessionPreservation(
        email: email,
        password: password,
        name: name,
        customUserId: customUserId,
        creatorAdminId: creatorAdminId,
        currentUserEmail: currentUserEmail,
        dateOfBirth: dateOfBirthStr,
        mobileNumber: mobileNumberStr,
      );
    } catch (e) {
      print('🚨 ERROR in createAdminUser: $e');
      return {
        'success': false,
        'error': e.toString(),
        'requires_reauth': false,
      };
    }
  }

  /// Helper method to create user profile
  static Future<void> _createUserProfile({
    required String userId,
    required String customUserId,
    required String email,
    String? name,
    required String creatorAdminId,
    String? dateOfBirth,
    String? mobileNumber,
  }) async {
    final profileData = {
      'user_id': userId,
      'custom_user_id': customUserId,
      'email': email,
      'role': 'Admin',
      'name': name ?? 'Admin User',
      'date_of_birth': dateOfBirth ?? DateTime(1990, 1, 1).toIso8601String(),
      'mobile_number': mobileNumber ?? '0000000000',
      'account_disable': false,
      'profile_completed': true,
      'created_by_admin_id': creatorAdminId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('user_profiles').insert(profileData);
    print('✅ PROFILE CREATED WITH CREATOR: $creatorAdminId');
  }

  /// Session preservation fallback method
  static Future<Map<String, dynamic>> _createWithSessionPreservation({
    required String email,
    required String password,
    String? name,
    required String customUserId,
    required String creatorAdminId,
    required String? currentUserEmail,
    required String dateOfBirth,
    required String mobileNumber,
  }) async {
    // Store current session
    final currentSession = _supabase.auth.currentSession;
    if (currentSession == null) {
      throw Exception('No active session to preserve');
    }

    final refreshToken = currentSession.refreshToken;
    print('🔍 Storing session for: ${currentSession.user.email}');

    try {
      // Create user with signUp (this will auto-login the new user)
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }

      final newUserId = authResponse.user!.id;
      print('✅ AUTH USER CREATED: $newUserId');

      // Create profile while signed in as new user
      await _createUserProfile(
        userId: newUserId,
        customUserId: customUserId,
        email: email,
        name: name,
        creatorAdminId: creatorAdminId,
        dateOfBirth: dateOfBirth,
        mobileNumber: mobileNumber,
      );

      // Sign out new user
      await _supabase.auth.signOut();
      print('🔄 New user signed out, restoring original session...');

      // Restore original session using refresh token
      if (refreshToken != null) {
        final restoreResponse = await _supabase.auth.setSession(refreshToken);
        if (restoreResponse.session?.user.email?.toLowerCase() ==
            currentUserEmail?.toLowerCase()) {
          print('✅ ORIGINAL SESSION RESTORED SUCCESSFULLY');
          return {
            'success': true,
            'admin_id': customUserId,
            'creator_id': creatorAdminId,
            'message':
            'Admin $customUserId created successfully! You remain logged in.',
            'requires_reauth': false,
            'method': 'session_restore',
          };
        }
      }

      // Session restore failed
      print('⚠️ Session restore failed, but admin was created');
      return {
        'success': true,
        'admin_id': customUserId,
        'creator_id': creatorAdminId,
        'message':
        'Admin $customUserId created successfully, but you were logged out. Please log back in.',
        'requires_reauth': true,
        'method': 'session_restore_failed',
      };
    } catch (e) {
      print('🚨 Session preservation error: $e');
      throw Exception('Failed to create admin with session preservation: $e');
    }
  }

  /// Get all users that the current admin created
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔍 Fetching users for: ${currentUser.email}');

      // Get current admin's custom_user_id
      final adminProfile = await _supabase
          .from('user_profiles')
          .select('custom_user_id, role')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (adminProfile == null) {
        throw Exception('Admin profile not found');
      }

      final adminCustomId = adminProfile['custom_user_id'];
      print('🔍 Admin Custom ID: $adminCustomId');

      // Fetch users created by this admin
      final users = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('created_by_admin_id', adminCustomId)
          .eq('role', 'Admin') // Only show admin users
          .order('created_at', ascending: false);

      print('🔍 Found ${users.length} admin users created by $adminCustomId');

      if (users.isEmpty) {
        print('⚠️ WARNING: No admin users found! This might indicate:');
        print('  - No admins have been created yet');
        print('  - Database issues with created_by_admin_id field');
        print('  - RLS policy blocking the query');
      }

      // Deduplicate by email (keep latest)
      final Map<String, Map<String, dynamic>> uniqueUsers = {};
      for (final user in users) {
        final email = user['email']?.toString().toLowerCase();
        if (email != null) {
          if (!uniqueUsers.containsKey(email) ||
              DateTime.parse(
                user['created_at'],
              ).isAfter(DateTime.parse(uniqueUsers[email]!['created_at']))) {
            uniqueUsers[email] = user;
          }
        }
      }

      final deduplicatedUsers = uniqueUsers.values.toList();
      print(
        '🔍 After deduplication: ${deduplicatedUsers.length} unique admin users',
      );

      return deduplicatedUsers;
    } catch (e) {
      print('🚨 ERROR in getAllUsers: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }
}
