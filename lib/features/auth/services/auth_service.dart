import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../utils/user_role.dart';

class AuthService {
  final Logger _logger = Logger('AuthService');
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<UserRole> fetchUserRole(String userId) async {
    try {
      _logger.info('Fetching user role for user: $userId');

      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        throw AuthException('User profile not found');
      }

      final roleString = response['role'] as String?;

      if (roleString == null) {
        throw AuthException('User role not set');
      }

      return _mapStringToUserRole(roleString);
    } on PostgrestException catch (e) {
      _logger.severe('Database error while fetching user role', e);
      throw AuthException('Database error: ${e.message}');
    } catch (e) {
      _logger.severe('Unexpected error while fetching user role', e);
      throw AuthException('Failed to fetch user role: ${e.toString()}');
    }
  }

  /// Map string role to UserRole enum
  UserRole _mapStringToUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'driverindividual':
      case 'driver_individual':
        return UserRole.driver;
      case 'drivercompany':
      case 'driver_company':
        return UserRole.driver;
      case 'driver':
        return UserRole.driver;
      case 'truckowner':
      case 'truck_owner':
        return UserRole.truckOwner;
      case 'shipper':
        return UserRole.shipper;
      case 'agent':
        return UserRole.agent;
      default:
        _logger.warning('Unknown user role: $roleString');
        throw AuthException('Unknown user role: $roleString');
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      _logger.info('Updating user role for user: $userId to ${role.name}');

      await _supabase
          .from('user_profiles')
          .update({'role': role.name})
          .eq('id', userId);

      _logger.info('User role updated successfully');
    } on PostgrestException catch (e) {
      _logger.severe('Database error while updating user role', e);
      throw AuthException('Database error: ${e.message}');
    } catch (e) {
      _logger.severe('Unexpected error while updating user role', e);
      throw AuthException('Failed to update user role: ${e.toString()}');
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.warning('Error checking user profile existence', e);
      return false;
    }
  }

  /// Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _logger.info('Creating user profile for user: $userId');

      final profileData = {
        'id': userId,
        'email': email,
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      await _supabase.from('user_profiles').insert(profileData);

      _logger.info('User profile created successfully');
    } on PostgrestException catch (e) {
      _logger.severe('Database error while creating user profile', e);
      throw AuthException('Database error: ${e.message}');
    } catch (e) {
      _logger.severe('Unexpected error while creating user profile', e);
      throw AuthException('Failed to create user profile: ${e.toString()}');
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
