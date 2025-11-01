import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class RealTimeNotificationService {
  static final RealTimeNotificationService _instance =
  RealTimeNotificationService._internal();
  factory RealTimeNotificationService() => _instance;
  RealTimeNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  RealtimeChannel? _notificationChannel;
  bool _isInitialized = false;
  String? _currentUserId;
  bool _isAppInForeground = true;

  final Set<String> _processedNotificationIds = <String>{};
  final Map<String, DateTime> _notificationTimestamps = <String, DateTime>{};

  final StreamController<Map<String, dynamic>> _notificationController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped);
    _isInitialized = true;
  }

  void onAppLifecycleChanged(AppLifecycleState state) {
    _isAppInForeground = (state == AppLifecycleState.resumed);
    if (_isAppInForeground) {
      _startRealtimeListening();
    } else {
      _stopRealtimeListening();
    }
  }

  void _startRealtimeListening() {
    if (_currentUserId != null) {
      _startRealtimeConnection();
    }
  }

  void _stopRealtimeListening() {
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
      _notificationChannel = null;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> startListening(String userId) async {
    if (_currentUserId == userId && _notificationChannel != null) return;

    stopListening();
    _currentUserId = userId;
    _processedNotificationIds.clear();

    if (_isAppInForeground) {
      _startRealtimeConnection();
    }
  }

  void _startRealtimeConnection() {
    if (_currentUserId == null) return;
    try {
      final supabase = Supabase.instance.client;
      _notificationChannel = supabase
          .channel('public:notifications:user_id=eq.$_currentUserId')
          .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: _handleNewNotificationPayload,
      );
      _notificationChannel!.subscribe();
    } catch (e) {
      debugPrint('Error starting realtime connection: $e');
    }
  }

  void stopListening() {
    _stopRealtimeListening();
    _currentUserId = null;
  }

  void _handleNewNotificationPayload(PostgresChangePayload payload) {
    _processNotification(payload.newRecord);
  }

  void _processNotification(Map<String, dynamic> notification) {
    try {
      final notificationId = notification['id'] as String?;
      if (notificationId == null ||
          _processedNotificationIds.contains(notificationId)) {
        return;
      }

      final now = DateTime.now();
      final lastProcessed = _notificationTimestamps[notificationId];
      if (lastProcessed != null &&
          now.difference(lastProcessed).inSeconds < 10) {
        return;
      }

      _processedNotificationIds.add(notificationId);
      _notificationTimestamps[notificationId] = now;

      _notificationController.add(notification);

      _showLocalNotification(notification);
    } catch (e) {
      debugPrint('Error processing notification: $e');
    }
  }

  Future<void> checkForNewNotifications({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString('last_notification_check_$userId');
      final now = DateTime.now().toIso8601String();

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .gte(
        'created_at',
        lastCheck ??
            DateTime.now()
                .subtract(const Duration(minutes: 20))
                .toIso8601String(),
      );

      if (response.isNotEmpty) {
        for (final notification in response) {
          _processNotification(notification);
        }
      }

      await prefs.setString('last_notification_check_$userId', now);
    } catch (e) {
      debugPrint('Error checking for new notifications: $e');
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'alerts_channel',
        'shipment_alerts_title', // localized with tr()
        channelDescription: 'shipment_alerts_description', // localized with tr()
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );
      const details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        notification['id'].hashCode,
        notification['title'] as String? ?? tr('new_notification'),
        notification['message'] as String? ?? tr('empty_message'),
        details,
        payload: notification['id']?.toString(),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  void dispose() {
    stopListening();
    _notificationController.close();
  }
}
