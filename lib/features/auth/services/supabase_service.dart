import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/user_role.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static SupabaseClient get client => _client;

  static Future<bool> saveUserProfile({
    required String customUserId,
    required String userId,
    required UserRole role,
    required String name,
    required String dateOfBirth,
    required String mobileNumber,
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _client
          .from('user_profiles')
          .upsert({
        'user_id': userId,
        'custom_user_id': customUserId,
        'role': role.dbValue,
        'name': name,
        'date_of_birth': dateOfBirth,
        'mobile_number': mobileNumber,
        'email': email,
        'profile_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
        if (additionalData != null) ...additionalData,
      });
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  static Future<UserRole?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      final roleString = response['role'] as String?;
      if (roleString == null) return null;

      return UserRole.values.firstWhere(
            (role) => role.dbValue == roleString,
        // orElse: () => UserRole.driverIndividual,
        orElse: () => UserRole.driver,
      );
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<bool> isProfileCompleted(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('profile_completed')
          .eq('user_id', userId)
          .single();
      return response['profile_completed'] ?? false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<String?> getCustomUserId(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('custom_user_id')
          .eq('user_id', userId)
          .single();

      return response['custom_user_id'] as String?;
    } catch (e) {
      print('Error getting custom user ID: $e');
      return null;
    }
  }
}