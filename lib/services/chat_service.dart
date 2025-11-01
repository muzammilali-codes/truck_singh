import 'dart:async';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;
  final _unreadCountController = StreamController<int>.broadcast();
  RealtimeChannel? _messagesChannel;

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
    final senderId = await getCurrentCustomUserId();
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
  }

  // Updated: Uses the correct RPC 'authorize_attachment_upload'
  Future<void> sendAttachment({
    required String roomId,
    required File file,
    required String fileName,
    String? caption,
  }) async {
    final senderId = await getCurrentCustomUserId();
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
    final userId = await getCurrentCustomUserId();
    if (userId == null) return;
    await _client.from('chat_read_status').upsert({
      'room_id': roomId,
      'user_id': userId,
      'last_read_at': DateTime.now().toIso8601String(),
    });
    _fetchAndBroadcastUnreadCount();
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
