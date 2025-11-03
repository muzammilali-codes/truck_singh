import 'dart:async';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';
import 'package:flutter/foundation.dart'; // <-- 1. ADDED THIS IMPORT


class ChatService {
  final SupabaseClient _client = Supabase.instance.client;
  final _unreadCountController = StreamController<int>.broadcast();
  RealtimeChannel? _messagesChannel;

  // --- 2. ADDED A CACHE FOR THE USER PROFILE ---
  Map<String, String?>? _currentUserProfile;

  ChatService() {
    _initializeMessagesSubscription();
  }

  void dispose() {
    _unreadCountController.close();
    if (_messagesChannel != null) {
      _client.removeChannel(_messagesChannel!);
    }
  }

  Future<String?> getCurrentCustomUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      // Call the new database function
      final response = await _client.rpc('get_my_custom_id');

      return response as String?;
    } catch (e) {
      print('Could not fetch custom_user_id via RPC: $e');
      return null;
    }
  }



  // --- 3. ADDED THIS NEW HELPER FUNCTION ---
  /// Fetches the current user's ID and Name, caching it.
  Future<Map<String, String?>> _getCurrentUserProfile() async {
    // If cache exists, return it
    if (_currentUserProfile != null) {
      return _currentUserProfile!;
    }
    // If cache is empty, fetch profile
    try {
      final response = await _client
          .from('user_profiles')
          .select('custom_user_id, name')
          .eq('user_id', _client.auth.currentUser!.id)
          .single();

      _currentUserProfile = {
        'custom_user_id': response['custom_user_id'] as String?,
        'name': response['name'] as String?,
      };
      return _currentUserProfile!;
    } catch (e) {
      print('Error fetching user profile: $e');
      return {'custom_user_id': null, 'name': 'Unknown User'};
    }
  }



  Future<void> _fetchAndBroadcastUnreadCount() async {
    try {
      final count = await _client.rpc('get_unread_chat_rooms_count');
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(count as int);
      }
    } catch (e) {
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(0);
      }
    }
  }

  void _initializeMessagesSubscription() {
    _messagesChannel = _client.channel('public:chat_messages');
    _messagesChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chat_messages',
      callback: (payload) {
        _fetchAndBroadcastUnreadCount();
      },
    )
        .subscribe();
    _fetchAndBroadcastUnreadCount();
  }

  Stream<int> getUnreadCountStream() {
    return _unreadCountController.stream;
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    // --- 4. UPDATE THIS FUNCTION ---
    final userProfile = await _getCurrentUserProfile();
    final senderId = userProfile['custom_user_id'];
    final senderName = userProfile['name'];


    if (senderId == null) {
      throw Exception("User is not logged in");
    }
    final encryptedContent = EncryptionService.encryptMessage(content, roomId);
    await _client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': encryptedContent,
      'message_type': 'text',
    });

    // --- 5. ADD THE EDGE FUNCTION CALL ---
    try {
      await _client.functions.invoke('send-chat-notification', body: {
        'room_id': roomId,
        'sender_id': senderId,
        'sender_name': senderName ?? 'Unknown User', // Add null fallback
        'message_content': content, // Send unencrypted content for the notification
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send chat notification: $e');
      }
    }
  }

  // Updated: Uses the correct RPC 'authorize_attachment_upload'
  Future<void> sendAttachment({
    required String roomId,
    required File file,
    required String fileName,
    String? caption,
  }) async {
    // --- 6. UPDATE THIS FUNCTION ---
    final userProfile = await _getCurrentUserProfile();
    final senderId = userProfile['custom_user_id'];
    final senderName = userProfile['name'];

    if (senderId == null) throw Exception("User is not logged in");

    try {
      // 1. Authorize the upload by calling the correct RPC.
      await _client.rpc('authorize_attachment_upload', params: {
        'p_room_id': roomId,
      });

      // 2. If authorization succeeds, proceed with the direct upload.
      final fileExtension = p.extension(fileName);
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = '$roomId/$senderId/$uniqueFileName';
      final fileBytes = await file.readAsBytes();

      await _client.storage.from('chat_attachments').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType:
          lookupMimeType(fileName) ?? 'application/octet-stream',
          upsert: false,
        ),
      );

      // 3. Get the public URL of the successfully uploaded file
      final publicUrl =
      _client.storage.from('chat_attachments').getPublicUrl(filePath);

      // 4. Encrypt the caption or a placeholder text
      final String messageContent = caption != null && caption.isNotEmpty
          ? caption
          : 'Attachment: $fileName';
      final encryptedContent =
      EncryptionService.encryptMessage(messageContent, roomId);

      // 5. Insert a new message into the database with the file URL
      await _client.from('chat_messages').insert({
        'room_id': roomId,
        'sender_id': senderId,
        'content': encryptedContent,
        'message_type': 'attachment',
        'attachment_url': publicUrl,
      });

      // --- 7. ADD THE EDGE FUNCTION CALL (FOR ATTACHMENTS) ---
      try {
        await _client.functions.invoke('send-chat-notification', body: {
          'room_id': roomId,
          'sender_id': senderId,
          'sender_name': senderName ?? 'Unknown User',
          'message_content': messageContent, // Send the caption as the message
        });
      } catch (e) {
        if (kDebugMode) {
          print('Failed to send chat notification: $e');
        }
      }

    } catch (e) {
      print('Error sending attachment: $e');
      rethrow;
    }
  }

  Future<String> getShipmentChatRoom(String shipmentId) async {
    final response = await _client.rpc(
      'get_or_create_shipment_chat_room',
      params: {'p_shipment_id': shipmentId},
    );
    return response as String;
  }

  Future<String> getDriverOwnerChatRoom(String driverId, String ownerId) async {
    final response = await _client.rpc(
      'get_or_create_driver_owner_chat_room',
      params: {
        'p_driver_id': driverId,
        'p_owner_id': ownerId,
      },
    );
    return response as String;
  }

  Future<void> markRoomAsRead(String roomId) async {
    // --- THIS IS THE FIX FOR THE CRASH ---
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.rpc(
        'upsert_chat_read_status',
        params: {
          'p_room_id': roomId,
          'p_user_id': userId,
        },
      );
      _fetchAndBroadcastUnreadCount();
    } catch (e) {
      // Log the error but don't crash the app
      print('Failed to mark room as read: $e');
    }
    // --- END OF FIX ---
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    final profileCache = <String, Map<String, dynamic>>{};
    Future<Map<String, dynamic>> getProfile(String customUserId) async {
      if (profileCache.containsKey(customUserId)) {
        return profileCache[customUserId]!;
      }
      try {
        final response = await _client
            .from('user_profiles')
            .select('name, role, custom_user_id')
            .eq('custom_user_id', customUserId)
            .limit(1)
            .maybeSingle();
        if (response != null) {
          profileCache[customUserId] = response;
          return response;
        } else {
          return {'name': 'Unknown User', 'role': ''};
        }
      } catch (e) {
        return {'name': 'Unknown User', 'role': ''};
      }
    }

    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .asyncMap((messages) async {
      final enrichedMessages = <Map<String, dynamic>>[];
      for (final message in messages) {
        final decryptedContent =
        EncryptionService.decryptMessage(message['content'], roomId);
        enrichedMessages.add({
          ...message,
          'content': decryptedContent,
          'sender': await getProfile(message['sender_id']),
        });
      }
      return enrichedMessages;
    });
  }
}
