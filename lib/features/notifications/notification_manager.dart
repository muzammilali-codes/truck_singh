import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';

/// Central notification management service for the shipment app.
/// Handles all notification creation, delivery, and management.
/// NOTE: Complaint notifications are currently disabled - only shipment notifications are active.
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ===== CORE NOTIFICATION METHODS =====

  /// Creates a new notification in the database
  /// Returns the notification ID if successful, null otherwise
  Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String sourceType = 'app',
    String? sourceId,
  }) async {
    try {
      final result = await _supabase.rpc('create_smart_notification', params: {
        'p_user_id': userId,
        'p_title': title,
        'p_message': message,
        'p_type': type,
        'p_source_type': sourceType,
        'p_source_id': sourceId,
      });

      if (kDebugMode) {
        debugPrint('✅ ${tr("notification_created_for_user")}: $userId: $title');
      }

      return result as String?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${tr("error_creating_notification")}: $e');
      }
      return null;
    }
  }

  /// Marks a notification as processed
  Future<void> markNotificationProcessed(String notificationId) async {
    try {
      await _supabase.rpc('mark_notification_processed', params: {
        'notification_id': notificationId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${tr("error_marking_notification_processed")}: $e');
      }
    }
  }

  /// Marks a notification as delivered
  Future<void> markNotificationDelivered(String notificationId) async {
    try {
      await _supabase.rpc('mark_notification_delivered', params: {
        'notification_id': notificationId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${tr("error_marking_notification_delivered")}: $e');
      }
    }
  }

  /// Retrieves unprocessed notifications for a user
  Future<List<Map<String, dynamic>>> getUnprocessedNotifications(String userId, {int limit = 10}) async {
    try {
      final result = await _supabase.rpc('get_unprocessed_notifications', params: {
        'p_user_id': userId,
        'p_limit': limit,
      });

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${tr("error_getting_unprocessed_notifications")}: $e');
      }
      return [];
    }
  }

  // ===== COMPLAINT NOTIFICATIONS =====

  /// Creates notifications when a complaint is filed
  /// Notifies both the complainer and the target user
  Future<void> createComplaintNotification({
    required String complainerId,
    required String complaintSubject,
    String? targetUserId,
    String? complaintId,
  }) async {
    try {
      // Notify complainer
      await createNotification(
        userId: complainerId,
        title: tr("complaint_filed_successfully"),
        message: tr("complaint_filed_message", args: [complaintSubject]),
        type: 'complaint',
        sourceType: 'app',
        sourceId: complaintId,
      );

      // Notify target user if exists
      if (targetUserId != null && targetUserId.isNotEmpty) {
        try {
          final targetUserProfile = await _supabase
              .from('user_profiles')
              .select('user_id')
              .eq('custom_user_id', targetUserId)
              .maybeSingle();

          if (targetUserProfile != null && targetUserProfile['user_id'] != null) {
            await createNotification(
              userId: targetUserProfile['user_id'],
              title: tr("new_complaint_filed_against_you"),
              message: tr("complaint_against_you", args: [complaintSubject]),
              type: 'complaint',
              sourceType: 'app',
              sourceId: complaintId,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ ${tr("error_notifying_target_user")}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${tr("error_creating_complaint_notification")}: $e');
      }
    }
  }

  /// Creates status-specific complaint notifications
  Future<void> createComplaintStatusNotification({
    required String userId,
    required String complaintSubject,
    required String status,
    String? complaintId,
  }) async {
    String message;
    switch (status.toLowerCase()) {
      case 'justified':
        message = tr("complaint_justified", args: [complaintSubject]);
        break;
      case 'resolved':
        message = tr("complaint_resolved", args: [complaintSubject]);
        break;
      case 'rejected':
        message = tr("complaint_rejected", args: [complaintSubject]);
        break;
      case 'reverted':
        message = tr("complaint_reverted", args: [complaintSubject]);
        break;
      case 'resolved & accepted':
        message = tr("complaint_resolved_accepted", args: [complaintSubject]);
        break;
      case 'auto-resolved':
        message = tr("complaint_auto_resolved", args: [complaintSubject]);
        break;
      default:
        message = tr("complaint_status_updated", args: [complaintSubject, status]);
    }

    await createNotification(
      userId: userId,
      title: tr("complaint_status_updated_title"),
      message: message,
      type: 'complaint',
      sourceType: 'app',
      sourceId: complaintId,
    );
  }

  /// Creates notifications for complaint status updates
  /// Automatically notifies both complainer and target user
  Future<void> createStatusUpdateNotification(
      String complaintId,
      String status,
      String justification,
      ) async {
    try {
      final complaint = await _supabase
          .from('complaints')
          .select('user_id, target_user_id, subject')
          .eq('id', complaintId)
          .maybeSingle();

      if (complaint == null) {
        if (kDebugMode) {
          debugPrint('❌ ${tr("complaint_not_found")}: $complaintId');
        }
        return;
      }

      // Notify complainer
      await createComplaintStatusNotification(
        userId: complaint['user_id'],
        complaintSubject: complaint['subject'],
        status: status,
        complaintId: complaintId,
      );

      // Notify target user if exists
      if (complaint['target_user_id'] != null && complaint['target_user_id'].toString().isNotEmpty) {
        final targetUserProfile = await _supabase
            .from('user_profiles')
            .select('user_id')
            .eq('custom_user_id', complaint['target_user_id'])
            .maybeSingle();

        if (targetUserProfile != null && targetUserProfile['user_id'] != null) {
          await createComplaintStatusNotification(
            userId: targetUserProfile['user_id'],
            complaintSubject: complaint['subject'],
            status: status,
            complaintId: complaintId,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${tr("error_creating_status_update_notification")}: $e');
      }
    }
  }

  // ===== SHIPMENT NOTIFICATIONS (ACTIVE) =====

  /// Creates notifications for shipment status updates
  Future<void> createShipmentNotification({
    required String userId,
    required String shipmentId,
    required String status,
    String? pickup,
    String? drop,
  }) async {
    String message;
    switch (status.toLowerCase()) {
      case 'accepted':
        message = tr("shipment_accepted", args: [shipmentId, pickup ?? 'pickup', drop ?? 'drop']);
        break;
      case 'in-transit':
        message = tr("shipment_in_transit", args: [shipmentId, pickup ?? 'pickup', drop ?? 'drop']);
        break;
      case 'delivered':
        message = tr("shipment_delivered", args: [shipmentId, drop ?? 'drop']);
        break;
      case 'cancelled':
        message = tr("shipment_cancelled", args: [shipmentId]);
        break;
      default:
        message = tr("shipment_status_updated", args: [shipmentId, status]);
    }

    await createNotification(
      userId: userId,
      title: tr("shipment_status_updated_title"),
      message: message,
      type: 'shipment',
      sourceType: 'app',
      sourceId: shipmentId,
    );
  }

  // ===== UTILITY METHODS =====

  /// Creates a custom notification with specified parameters
  Future<void> createCustomNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'custom',
    String? sourceId,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      sourceType: 'app',
      sourceId: sourceId,
    );
  }

  /// Creates the same notification for multiple users
  Future<void> createBulkNotification({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'bulk',
    String? sourceId,
  }) async {
    for (final userId in userIds) {
      await createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        sourceType: 'app',
        sourceId: sourceId,
      );
    }
  }
}
