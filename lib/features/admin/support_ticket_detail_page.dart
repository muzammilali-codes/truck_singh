import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhancedSupportTicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const EnhancedSupportTicketDetailPage({super.key, required this.ticket});

  @override
  State<EnhancedSupportTicketDetailPage> createState() =>
      _EnhancedSupportTicketDetailPageState();
}

class _EnhancedSupportTicketDetailPageState
    extends State<EnhancedSupportTicketDetailPage> {
  late String _currentStatus;
  bool _isUpdating = false;
  final _responseController = TextEditingController();
  bool _isSubmittingResponse = false;
  List<Map<String, dynamic>> _responses = [];
  bool _isLoadingResponses = true;
  String _currentUserRole = '';
  bool _canChangeStatus = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket['status'];
    _loadResponses();
    _checkUserRole();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('role')
            .eq('user_id', user.id)
            .single();

        setState(() {
          _currentUserRole = userProfile['role'] ?? '';
          _canChangeStatus = _currentUserRole == 'Admin';
        });
      }
    } catch (e) {
      setState(() {
        _canChangeStatus = false;
      });
    }
  }

  Future<void> _loadResponses() async {
    try {
      final ticket = await Supabase.instance.client
          .from('support_tickets')
          .select('chat_messages')
          .eq('id', widget.ticket['id'])
          .single();

      final chatMessages = ticket['chat_messages'] as List<dynamic>? ?? [];

      setState(() {
        _responses =
            chatMessages.map((msg) => Map<String, dynamic>.from(msg)).toList();
        _isLoadingResponses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResponses = false;
      });
      _showSnackBar('Error loading responses: $e', Colors.red);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await Supabase.instance.client.from('support_tickets').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.ticket['id']);

      setState(() => _currentStatus = newStatus);
      _showSnackBar('Status updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to update status: $e', Colors.red);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      _showSnackBar('Please enter a response', Colors.orange);
      return;
    }

    setState(() => _isSubmittingResponse = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showSnackBar('Authentication error', Colors.red);
        return;
      }

      // Get admin user info
      final adminProfile = await Supabase.instance.client
          .from('user_profiles')
          .select('name, custom_user_id')
          .eq('user_id', user.id)
          .single();

      // Add message using the JSON chat function
      await Supabase.instance.client.rpc(
        'add_chat_message',
        params: {
          'ticket_id_param': widget.ticket['id'],
          'responder_id_param': user.id,
          'responder_name_param': adminProfile['name'] ?? 'Admin',
          'responder_type_param': 'admin',
          'message_text': _responseController.text.trim(),
        },
      );

      // Update ticket status to In Progress if it's Pending
      if (_currentStatus == 'Pending') {
        await _updateStatus('In Progress');
      }

      _responseController.clear();
      _loadResponses();
      _showSnackBar('Response sent successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error sending response: $e', Colors.red);
    } finally {
      setState(() => _isSubmittingResponse = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Support Ticket #${widget.ticket['id']}"),
        leading: BackButton(onPressed: () => Navigator.pop(context, true)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResponses,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTicketInfoCard(),
                  const SizedBox(height: 16),
                  _buildOriginalMessageCard(),
                  const SizedBox(height: 16),
                  if (widget.ticket['screenshot_url'] != null)
                    _buildScreenshotCard(),
                  const SizedBox(height: 16),
                  _buildResponsesSection(),
                ],
              ),
            ),
          ),
          _buildResponseInputSection(),
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard() {
    final createdAt = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.parse(widget.ticket['created_at']));

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ticket['subject'] ?? 'No Subject',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${widget.ticket['category'] ?? 'General'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Priority: ${widget.ticket['priority'] ?? 'Medium'}',
                        style: TextStyle(
                          color: _getPriorityColor(
                            widget.ticket['priority'] ?? 'Medium',
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getStatusColor(_currentStatus)),
                  ),
                  child: Text(
                    _currentStatus,
                    style: TextStyle(
                      color: _getStatusColor(_currentStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.person,
              "user".tr(),
              widget.ticket['user_name'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.badge,
              "user_id".tr(),
              widget.ticket['user_custom_id'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.email,
              "email".tr(),
              widget.ticket['user_email'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.work,
              "role".tr(),
              widget.ticket['user_role'] ?? 'N/A',
            ),
            _buildInfoRow(Icons.access_time, "Created".tr(), createdAt),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  "status:".tr(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isUpdating
                      ? const LinearProgressIndicator()
                      : _canChangeStatus
                      ? DropdownButton<String>(
                    value: _currentStatus,
                    isExpanded: true,
                    items:
                    ['pending'.tr(), 'in_progress'.tr(), 'resolved'.tr()].map((
                        String value,
                        ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newStatus) {
                      if (newStatus != null &&
                          newStatus != _currentStatus) {
                        _updateStatus(newStatus);
                      }
                    },
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      //color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      _currentStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        //color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalMessageCard() {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "original_message".tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            SelectableText(
              widget.ticket['message'] ?? 'no_message'.tr(),
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotCard() {
    final screenshotUrl = widget.ticket['screenshot_url'];
    return Card(
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(screenshotUrl))) {
            await launchUrl(
              Uri.parse(screenshotUrl),
              mode: LaunchMode.externalApplication,
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.image, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "attached_screenshot".tr(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  screenshotUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      alignment: Alignment.center,
                      child:  Text("could_not_load_image".tr()),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                "tap_to_view".tr(),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "conversation".tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingResponses)
              const Center(child: CircularProgressIndicator())
            else if (_responses.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "no_responses".tr(),
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._responses
                  .map((response) => _buildResponseBubble(response))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseBubble(Map<String, dynamic> response) {
    final isAdmin = response['responder_type'] == 'admin';
    final createdAt = DateFormat(
      'dd MMM, hh:mm a',
    ).format(DateTime.parse(response['timestamp']));

    return Container(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isAdmin ? Colors.blue : Colors.green,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 16,
              //color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAdmin
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        response['responder_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    response['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseInputSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        //color: Colors.grey[50],
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _responseController,
                  maxLines: 3,
                  decoration:  InputDecoration(
                    hintText: 'type_response_hint'.tr(),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSubmittingResponse ? null : _submitResponse,
                    icon: _isSubmittingResponse
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send, size: 16),
                    label:  Text('send'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
