import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'support_ticket_detail_page.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({Key? key}) : super(key: key);

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Pending', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("support_tickets".tr()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // color for selected tab text
          //unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((key) => Tab(text: key.tr())).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((String status) {
          return TicketList(status: status);
        }).toList(),
      ),
    );
  }
}

class TicketList extends StatefulWidget {
  final String status;
  const TicketList({Key? key, required this.status}) : super(key: key);

  @override
  State<TicketList> createState() => _TicketListState();
}

class _TicketListState extends State<TicketList> {
  late Future<List<Map<String, dynamic>>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _fetchTickets();
  }

  Future<List<Map<String, dynamic>>> _fetchTickets() async {
    final response = await Supabase.instance.client
        .from('support_tickets')
        .select()
        .eq('status', widget.status)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refresh() async {
    setState(() {
      _ticketsFuture = _fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ticketsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final tickets = snapshot.data!;
        if (tickets.isEmpty) {
          return Center(
            child: Text(
              "No ${widget.status.toLowerCase()} tickets found.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final createdAt = DateTime.parse(ticket['created_at']);

              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.teal),
                  title: Text(
                    ticket['user_name'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    ticket['message'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat('dd MMM, hh:mm a').format(createdAt),
                  ),
                  onTap: () async {
                    // Navigate to detail page and wait for a result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnhancedSupportTicketDetailPage(ticket: ticket),
                      ),
                    );
                    // If the status was updated on the detail page, refresh the list
                    if (result == true) {
                      _refresh();
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
