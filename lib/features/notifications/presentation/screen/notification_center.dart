import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  String? error;
  bool showReadNotifications = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query =
      supabase.from('notifications').select().eq('user_id', user.id);

      if (!showReadNotifications) {
        query = query.eq('read', false);
      }

      final response = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(response);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);

      if (!showReadNotifications) {
        await fetchNotifications();
      } else {
        if (mounted) {
          setState(() {
            final index = notifications.indexWhere(
                  (n) => n['id'] == notificationId,
            );
            if (index != -1) {
              notifications[index]['read'] = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', user.id)
          .eq('read', false);

      await fetchNotifications();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  void toggleShowReadNotifications() {
    setState(() {
      showReadNotifications = !showReadNotifications;
    });
    fetchNotifications();
  }

  IconData _getNotificationIconData(String type) {
    switch (type) {
      case 'complaint':
        return Icons.report_problem_outlined;
      case 'shipment':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  IconData getStatusIcon(String status) {
    final lower = status.toLowerCase();

    switch (true) {
      case var _ when lower.contains('pending'):
        return Icons.pending;
      case var _ when lower.contains('confirmed'):
        return Icons.check_circle;
      case var _ when lower.contains('dispatched'):
        return Icons.local_shipping;
      case var _ when lower.contains('route to pickup'):
        return Icons.local_shipping_outlined;
      case var _ when lower.contains('arrived at pickup'):
        return Icons.location_on;
      case var _ when lower.contains('loading'):
        return Icons.upload;
      case var _ when lower.contains('picked up'):
        return Icons.done;
      case var _ when lower.contains('in transit'):
        return Icons.directions_bus;
      case var _ when lower.contains('arrived at drop'):
        return Icons.place;
      case var _ when lower.contains('unloading'):
        return Icons.download;
      case var _ when lower.contains('delivered'):
        return Icons.done_all;
      case var _ when lower.contains('completed'):
        return Icons.verified;
      case var _ when lower.contains('cancelled'):
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // Parse shipment details from the message string
  Map<String, String> _parseShipmentDetails(String message) {
    try {
      // Extract status
      final statusMatch = RegExp(r'updated to (.*?)\.').firstMatch(message);
      final status = statusMatch?.group(1) ?? 'Unknown Status';

      // Extract shipment ID
      final idMatch = RegExp(r'Shipment ID: (.*?) \|').firstMatch(message);
      final id = idMatch?.group(1)?.trim() ?? 'Unknown ID';

      // Extract from location
      final fromMatch = RegExp(r'From: (.*?), (.*?), India').firstMatch(message);
      final fromCity = fromMatch?.group(1)?.trim() ?? 'Unknown City';
      final fromState = fromMatch?.group(2)?.trim() ?? 'Unknown State';
      final from = '$fromCity, $fromState';

      // Extract to location
      final toMatch = RegExp(r'To: (.*?), India').firstMatch(message);
      final toCity = toMatch?.group(1)?.trim() ?? 'Unknown City';
      final to = toCity;

      return {
        'status': status,
        'id': id,
        'from': from,
        'to': to,
      };
    } catch (e) {
      return {
        'status': 'Unknown Status',
        'id': 'Unknown ID',
        'from': 'Unknown Location',
        'to': 'Unknown Location',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications.where((n) => !(n['read'] ?? false)).length;
    Theme.of(context);

    return Scaffold(
      body: Container(
        child: Column(
          children: [
            AppBar(
              //backgroundColor: Colors.teal.shade600,
              elevation: 4,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: const Text(
                "Notifications",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    showReadNotifications
                        ? Icons.visibility
                        : Icons.visibility_off,
                    //color: Colors.white,
                  ),
                  onPressed: toggleShowReadNotifications,
                  tooltip: showReadNotifications ? 'Hide Read' : 'Show All',
                ),
                if (unreadCount > 0)
                  IconButton(
                    icon: const Icon(Icons.done_all),
                    onPressed: markAllAsRead,
                    tooltip: 'Mark All as Read',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: fetchNotifications,
                ),
              ],
            ),
            Expanded(
              child: loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              )
                  : error != null
                  ? Center(child: Text('Error: $error'))
                  : notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: fetchNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.all(7.0),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _buildNotificationCard(n);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            //color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            showReadNotifications
                ? 'No Notifications Found'
                : 'You are all caught up!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.grey),
          ),
          if (!showReadNotifications) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: toggleShowReadNotifications,
              child: const Text('Show Read Notifications'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final read = notification['read'] ?? false;
    // add 5:30 hours to get indian time
    // final date = DateTime.tryParse(notification['created_at'] ?? '')!.add(const Duration(hours: 5, minutes: 30));
    final date = DateTime.tryParse(notification['created_at'] ?? '')?.toLocal();

    final type = notification['type'] ?? 'general';
    final theme = Theme.of(context);

    // Parse shipment details if this is a shipment notification
    final Map<String, String> shipmentDetails =
    (type == 'shipment') ? _parseShipmentDetails(notification['message'] ?? '') : {};

    return Card(
      //color: const Color(0xFF86CBBF),
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),        // Card size configurations
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          if (!read) {
            await markAsRead(notification['id']);
          }
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (dialogContext) => _buildNotificationDialog(notification),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getNotificationIconData(type),
                color: read ? Colors.grey : AppColors.orange,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Show parsed shipment details if available, otherwise show full message
                    if (type == 'shipment' && shipmentDetails.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Status: ${shipmentDetails['status']}",
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),textAlign: TextAlign.center
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            "ID: ${shipmentDetails['id']}",
                            style: const TextStyle(fontSize: 15.3),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            "From: ${shipmentDetails['from']}",
                            style: const TextStyle(fontSize: 15.3),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            "To: ${shipmentDetails['to']}",
                            style: const TextStyle(fontSize: 15.3),
                          ),
                        ],
                      )
                    else
                      Text(
                        notification['message'] ?? 'No message',
                        style: const TextStyle(fontSize: 15.3),
                      ),

                    if (date != null) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        "Updated At: ${DateFormat('MMM dd, yyyy - hh:mm a').format(date)}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTimeAgo(notification['created_at']),
                        style: TextStyle(
                          fontSize: 13,
                          //color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                getStatusIcon(notification['message'] ?? ""),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationDialog(Map<String, dynamic> notification) {
    final date = DateTime.tryParse(notification['created_at'] ?? '');
    final type = notification['type'] ?? 'general';

    // Parse shipment details if this is a shipment notification
    final Map<String, String> shipmentDetails =
    (type == 'shipment') ? _parseShipmentDetails(notification['message'] ?? '') : {};

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(_getNotificationIconData(type)),
          const SizedBox(width: 12),
          Expanded(child: Text(notification['title'] ?? 'No Title',style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show parsed shipment details if available, otherwise show full message
          if (type == 'shipment' && shipmentDetails.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: ${shipmentDetails['status']}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  "ID: ${shipmentDetails['id']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "From: ${shipmentDetails['from']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "To: ${shipmentDetails['to']}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            )
          else
            Text(
              notification['message'] ?? 'No message',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

          if (date != null) ...[
            const SizedBox(height: 24),
            Text(
              //DateFormat('MMM dd, yyyy - hh:mm a').format(date),
              DateFormat('MMM dd, yyyy - hh:mm a').format(date.toLocal()),

              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months == 1 ? '' : 's'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years == 1 ? '' : 's'} ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}