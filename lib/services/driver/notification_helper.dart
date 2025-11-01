import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const _notificationId = 888;
  static const _channelId = 'location_channel';
  static const _channelName = 'Location Tracking';

  static Future<void> initialize() async {
    if (_isInitialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(settings);
    _isInitialized = true;
  }

  static void updateNotification(String title, String content) {
    _localNotifications.show(
      _notificationId,
      title,
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              'Persistent notification for the location service.',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
        ),
      ),
    );
  }
}
