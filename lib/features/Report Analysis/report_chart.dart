import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

// Utility functions
class ShipmentUtils {
  static String monthName(String? iso) {
    if (iso == null) return '';
    return DateFormat('MMMM').format(DateTime.parse(iso));
  }

  static String formattedDate(String? iso) {
    if (iso == null) return '';
    return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
  }

  static String extractCity(String? address) {
    if (address == null) return '';
    List<String> parts = address.split(',');
    if (parts.length < 2) return address.trim();
    List<String> trimmed = parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (trimmed.length < 2) return trimmed.first;
    return trimmed[trimmed.length - 2];
  }
}

// Reusable card for one shipment row
class ShipmentListItem extends StatelessWidget {
  final Map<String, dynamic> shipment;
  final Color statusColor;
  const ShipmentListItem({super.key, required this.shipment, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: statusColor.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: statusColor, radius: 8),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  shipment['booking_status'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                shipment['shipment_id']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Text('Shipper: ${shipment['user_name'] ?? ""}', style: const TextStyle(fontSize: 14)),
              //Text('Shipper: ${shipment['user_profiles']?['name'] ?? ""}', style: const TextStyle(fontSize: 14)),
              Text('Driver: ${shipment['assigned_driver'] ?? ""}', overflow: TextOverflow.ellipsis),
              Text('Route: ${shipment['pickup'] ?? "?"} → ${ShipmentUtils.extractCity(shipment['drop'])}', overflow: TextOverflow.ellipsis),
              Text('Date: ${ShipmentUtils.formattedDate(shipment['updated_at'])}', overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportAnalysisPage extends StatefulWidget {
  const ReportAnalysisPage({super.key});
  @override
  State<ReportAnalysisPage> createState() => _ReportAnalysisPageState();
}

class _ReportAnalysisPageState extends State<ReportAnalysisPage> {
  String selectedStatus = 'All';
  String selectedMonth = 'All';
  String selectedLocation = 'All';
  String activeChartFilter = '';
  String searchQuery = '';
  bool showBarChart = false;
  bool isLoading = true;
  bool hasError = false;
  int shipmentLimit = 30; // pagination
  List<Map<String, dynamic>> shipments = [];
  final ScrollController _scrollController = ScrollController();

  final List<String> shipmentStatuses = [
    'Pending', 'Accepted', 'En Route to Pickup', 'Arrived at Pickup', 'Loading',
    'Picked Up', 'In Transit', 'Arrived at Drop', 'Unloading',
    'Delivered', 'Completed', 'Returned',
  ];
  final Map<String, Color> statusColors = {
    'Pending': Colors.orange,
    'Accepted': Colors.blue,
    'En Route to Pickup': Colors.deepPurple,
    'Arrived at Pickup': Colors.indigo,
    'Loading': Colors.amber,
    'Picked Up': Colors.purple,
    'In Transit': Colors.pink,
    'Arrived at Drop': Colors.brown,
    'Unloading': Colors.grey,
    'Delivered': Colors.teal,
    'Completed': Colors.green,
    'Returned': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    fetchAgentShipment();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchAgentShipment({bool loadMore = false}) async {
    setState(() { isLoading = true; hasError = false; });
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() { isLoading = false; hasError = true; });
      return;
    }

    try {
      final userProfile = await supabase
          .from('user_profiles')
          .select('custom_user_id, name, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (userProfile == null || userProfile['custom_user_id'] == null) {
        setState(() { isLoading = false; hasError = true; });
        return;
      }

      final customUserId = userProfile['custom_user_id'].toString();

      final start = loadMore ? shipments.length : 0;
      final end = start + shipmentLimit - 1;

      final raw = await supabase
          .from('shipment')
          .select('shipment_id, pickup, drop, booking_status, assigned_driver, updated_at, delivery_date')
          .eq('assigned_agent', customUserId)
          .order('updated_at', ascending: false)
          .range(start, end);

      final List<Map<String, dynamic>> newItems = (raw is List)
          ? (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];

      setState(() {
        if (loadMore) {
          shipments.addAll(newItems);
        } else {
          shipments = newItems;
        }
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() { isLoading = false; hasError = true; });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading shipments: $e"))
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !isLoading && shipments.length >= shipmentLimit) {
      fetchAgentShipment(loadMore: true);
    }
  }

  List<String> get months {
    final mSet = <String>{};
    for (var s in shipments) {
      if (s['updated_at'] != null) {
        mSet.add(ShipmentUtils.monthName(s['updated_at']));
      }
    }
    return ['All', ...mSet];
  }

  List<String> get locations {
    final locSet = <String>{};
    for (var s in shipments) {
      final city = ShipmentUtils.extractCity(s['drop']);
      if (city.isNotEmpty) locSet.add(city);
    }
    return ['All', ...locSet];
  }

  List<Map<String, dynamic>> _filterShipments() {
    return shipments.where((shipment) {
      final mStatus = selectedStatus == 'All' || shipment['booking_status'] == selectedStatus;
      final mMonth = selectedMonth == 'All' || (shipment['updated_at'] != null && ShipmentUtils.monthName(shipment['updated_at']) == selectedMonth);
      final mLocation = selectedLocation == 'All' || ShipmentUtils.extractCity(shipment['drop']) == selectedLocation;
      final mChart = activeChartFilter.isEmpty || shipment['booking_status'] == activeChartFilter;
      final mSearch = searchQuery.isEmpty || shipment.entries.any((entry) => entry.value != null && entry.value.toString().toLowerCase().contains(searchQuery.toLowerCase()));
      return mStatus && mMonth && mLocation && mChart && mSearch;
    }).toList();
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: Text('Status: $selectedStatus'),
          selected: selectedStatus != 'All',
          onSelected: (_) => _selectStatus(),
        ),
        FilterChip(
          label: Text('Month: $selectedMonth'),
          selected: selectedMonth != 'All',
          onSelected: (_) => _selectMonth(),
        ),
        FilterChip(
          label: Text('Location: $selectedLocation'),
          selected: selectedLocation != 'All',
          onSelected: (_) => _selectLocation(),
        ),
        if (selectedStatus != 'All' || selectedMonth != 'All' || selectedLocation != 'All' || searchQuery.isNotEmpty)
          ActionChip(
            label: Text('reset'.tr()),
            avatar: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                selectedStatus = 'All';
                selectedMonth = 'All';
                selectedLocation = 'All';
                searchQuery = '';
                activeChartFilter = '';
              });
            },
          ),
      ],
    );
  }

  Future<void> _selectStatus() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('select_status'.tr()),
        children: ['All', ...shipmentStatuses].map((status) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, status),
          child: Text(status),
        )).toList(),
      ),
    );
    if (result != null) setState(() => selectedStatus = result);
  }

  Future<void> _selectMonth() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('select_month'.tr()),
        children: months.map((m) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, m),
          child: Text(m),
        )).toList(),
      ),
    );
    if (result != null) setState(() => selectedMonth = result);
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('select_city'.tr()),
        children: locations.map((loc) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, loc),
          child: Text(loc),
        )).toList(),
      ),
    );
    if (result != null) setState(() => selectedLocation = result);
  }

  Widget _buildPieChart(List<Map<String, dynamic>> filteredShipments) {
    final statusCounts = <String, int>{ for (var status in shipmentStatuses) status: 0 };
    for (var s in filteredShipments) {
      final status = s['booking_status'];
      if (statusCounts.containsKey(status)) statusCounts[status] = statusCounts[status]! + 1;
    }
    final total = statusCounts.values.fold(0, (sum, val) => sum + val);

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          width: MediaQuery.of(context).size.width * 0.7,
          child: PieChart(
            PieChartData(
              sections: statusCounts.entries.where((e) => e.value > 0).map((entry) {
                final percent = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
                final isActive = activeChartFilter == entry.key;
                return PieChartSectionData(
                  title: '$percent%',
                  value: entry.value.toDouble(),
                  color: statusColors[entry.key],
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  radius: isActive ? 80 : 65,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (response != null && response.touchedSection != null) {
                    setState(() {
                      final label = statusCounts.keys.elementAt(response.touchedSection!.touchedSectionIndex);
                      activeChartFilter = label == activeChartFilter ? '' : label;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: statusCounts.entries.where((e) => e.value > 0).map((entry) {
            return FilterChip(
              label: Text('${entry.key} (${entry.value})'),
              selected: activeChartFilter == entry.key,
              backgroundColor: statusColors[entry.key]!.withOpacity(0.18),
              selectedColor: statusColors[entry.key],
              onSelected: (_) => setState(() => activeChartFilter = activeChartFilter == entry.key ? '' : entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> filteredShipments) {
    final Map<String, int> monthCounts = {};
    for (var shipment in filteredShipments) {
      final dt = shipment['updated_at'] != null ? DateTime.parse(shipment['updated_at']) : DateTime.now();
      final month = DateFormat('MMM').format(dt);
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
    }
    final monthsList = monthCounts.keys.toList();
    final barGroups = monthsList.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [BarChartRodData(toY: monthCounts[entry.value]?.toDouble() ?? 0, color: Colors.blueAccent)],
      );
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      width: MediaQuery.of(context).size.width * 0.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= monthsList.length) return const Text('');
              return Text(monthsList[index], style: const TextStyle(fontSize: 10));
            })),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1)),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildShipmentList(List<Map<String, dynamic>> filteredShipments) {
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text("something_went_wrong".tr(), style: const TextStyle(fontSize: 16, color: Colors.red))),
      );
    }
    if (filteredShipments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, color: Colors.grey, size: 48),
              const SizedBox(height: 10),
              Text('no_shipments'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
              TextButton.icon(
                onPressed: fetchAgentShipment,
                icon: const Icon(Icons.refresh),
                label: Text('reload'.tr()),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredShipments.length,
      itemBuilder: (context, i) {
        final s = filteredShipments[i];
        return ShipmentListItem(
          shipment: s,
          statusColor: statusColors[s['booking_status']] ?? Colors.grey,
        );
      },
    );
  }

  Widget _buildChartSwitcher() {
    return IconButton(
      icon: Icon(showBarChart ? Icons.pie_chart : Icons.bar_chart),
      tooltip: showBarChart ? 'show_pie_chart'.tr() : 'show_bar_chart'.tr(),
      onPressed: () => setState(() => showBarChart = !showBarChart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredShipments = _filterShipments();
    final colorScheme = Theme.of(context).colorScheme;
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('report_analysis'.tr()),
          backgroundColor: Colors.blueAccent,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
              onPressed: fetchAgentShipment,
              tooltip: 'refresh_all'.tr(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => fetchAgentShipment(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterChips(),
                const SizedBox(height: 16),
                Text(
                  'shipment_summary'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: showBarChart ? _buildBarChart(filteredShipments) : _buildPieChart(filteredShipments),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: _buildChartSwitcher(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Shipments (${filteredShipments.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.primary),
                      ),
                    ),
                    Flexible(
                      flex: 4,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 350 : MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'search'.tr(),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (val) => setState(() => searchQuery = val),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildShipmentList(filteredShipments),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
