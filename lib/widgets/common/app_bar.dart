import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logistics_toolkit/features/notifications/presentation/screen/notification_center.dart';
import 'package:logistics_toolkit/features/notifications/real_time_notification_service.dart';
import 'package:logistics_toolkit/features/settings/presentation/screen/settings_page.dart';
import 'package:logistics_toolkit/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/services/supabase_service.dart';
import '../../features/chat/agent_chat_list_page.dart';
import '../../features/chat/driver_chat_list_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? pageTitle;
  final bool showProfile;
  final bool showNotifications;
  final bool showMessages;
  final List<Widget>? customActions;
  final VoidCallback? onProfileTap;
  final Map<String, dynamic>? userProfile;
  final bool isLoading;
  final Map<String, dynamic>? shipment;

  const CustomAppBar({
    super.key,
    this.pageTitle,
    this.showProfile = false,
    this.showNotifications = true,
    this.showMessages = true,
    this.customActions,
    this.onProfileTap,
    this.userProfile,
    this.isLoading = false,
    this.shipment,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final RealTimeNotificationService _notificationService =
  RealTimeNotificationService();
  // final ChatService _chatService = ChatService();
  StreamSubscription? _notificationSubscription;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showNotifications) {
      _initializeNotifications();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationService.dispose();
    // _chatService.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      _notificationService.startListening(user.id);
      _notificationSubscription = _notificationService.notificationStream
          .listen((_) {
        _fetchUnreadCount();
      });
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) return;
      final count = await SupabaseService.client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', user.id)
          .eq('read', false);
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    } catch (e) {
      print("Error fetching unread count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor:
      theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      foregroundColor:
      theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
      leading: widget.pageTitle != null
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      title: widget.showProfile
          ? _buildProfileTitle(context)
          : _buildPageTitle(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildProfileTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isLoading) {
      return _buildLoadingTitle();
    }

    if (widget.userProfile == null) {
      return Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.errorContainer,
            child: Icon(Icons.error, color: colorScheme.onErrorContainer),
          ),
          const SizedBox(width: 12),
          Text('Error loading profile', style: theme.textTheme.titleMedium),
        ],
      );
    }

    final profile = widget.userProfile!;
    return GestureDetector(
      onTap:
      widget.onProfileTap ??
              () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          ),
      child: Row(
        children: [
          profile['profile_picture'] != null &&
              profile['profile_picture'].isNotEmpty
              ? CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: NetworkImage(profile['profile_picture']),
          )
              : CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hello, ${profile['name']?.split(' ').first ?? 'User'}',
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${profile['custom_user_id'] ?? 'N/A'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle(BuildContext context) {
    return Text(
      widget.pageTitle ?? '',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildLoadingTitle() {
    return Row(
      children: [
        const CircleAvatar(backgroundColor: Colors.black12),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];

    if (widget.customActions != null) {
      actions.addAll(widget.customActions!);
    }
    if (widget.showNotifications) {
      actions.add(_buildNotificationButton());
    }
    return actions;
  }

  Widget _buildNotificationButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
            );
            _fetchUnreadCount();
          },
        ),
        if (_unreadNotifications > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_unreadNotifications',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}