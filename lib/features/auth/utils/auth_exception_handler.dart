import 'package:supabase_flutter/supabase_flutter.dart';

class AuthExceptionHandler {
  static String getErrorMessage(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'The email or password is incorrect.';
      case 'User not found':
        return 'No account found with this email.';
      case 'Email rate limit exceeded':
        return 'Too many requests. Please try again later.';
      case 'For security purposes, you can only request this once every 60 seconds':
        return 'Too many requests. Please try again in a minute.';
      default:
        return error.message;
    }
  }
}