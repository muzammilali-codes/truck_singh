import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static String? _cachedCustomUserId;
  static const _prefsKey = 'custom_user_id';

  static Future<String?> getCustomUserId() async {
    if (_cachedCustomUserId != null) {
      return _cachedCustomUserId;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_prefsKey);
    if (storedId != null) {
      _cachedCustomUserId = storedId;
      return storedId;
    }
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('UserDataService: Cannot get custom ID because user is not logged in.');
      return null;
    }

    try {
      final response = await supabase
          .from('user_profiles')
          .select('custom_user_id')
          .eq('user_id', user.id)
          .single();

      final customId = response['custom_user_id'] as String?;

      if (customId != null) {
        _cachedCustomUserId = customId;
        await prefs.setString(_prefsKey, customId); // save to local storage
      }

      return customId;
    } catch (e) {
      print('UserDataService: Error fetching custom user ID - $e');
      return null;
    }
  }
  static Future<void> clearCache() async {
    _cachedCustomUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
