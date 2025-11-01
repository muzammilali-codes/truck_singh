import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class Rating extends StatefulWidget {
  final String shipmentId;
  final String? assignedDriver;
  final String? assignedCompany;
  final String? assignedShipper;
  final String? assignedAgent;
  final String userRole;

  const Rating({
    super.key,
    required this.shipmentId,
    required this.userRole,
    this.assignedAgent,
    this.assignedCompany,
    this.assignedShipper,
    this.assignedDriver,
  });

  @override
  State<Rating> createState() => _RatingState();
}

class _RatingState extends State<Rating> {
  DateTime? deliveryDate;
  bool isWithin3Days = false;
  String? bookingStatus;
  double rating1 = 0;
  double rating2 = 0;
  final feedback1 = TextEditingController();
  final feedback2 = TextEditingController();
  late String label1;
  late String label2;
  String? driverName;
  String? companyName;
  String? shipperName;
  String? agentName;
  int editCount = 0;

  @override
  void initState() {
    super.initState();

    switch (widget.userRole.toLowerCase()) {
      case 'shipper':
        label1 = "driver".tr();
        label2 = "agent".tr();
        break;
      case 'driver':
        label1 = "shipper".tr();
        label2 = "agent".tr();
        break;
      case 'agent':
        label1 = "shipper".tr();
        label2 = "driver".tr();
        break;
      default:
        label1 = "person1".tr();
        label2 = "person2".tr();
    }

    fetchAssignedName();
    fetchEditCount().then((_) {
      fetchExistingRating();
    });
    fetchDeliveryInfo();
  }

  Future<void> fetchAssignedName() async {
    final supabase = Supabase.instance.client;

    final shipment = await supabase
        .from('view_shipment_updates')
        .select('assigned_driver, assigned_agent, assigned_company')
        .eq('shipment_id', widget.shipmentId)
        .maybeSingle();

    final assignedDriverId = shipment?['assigned_driver']?.toString();
    final assignedShipperId = shipment?['assigned_driver']?.toString();
    final assignedAgentId = shipment?['assigned_agent']?.toString();
    final assignedCompanyId = shipment?['assigned_company']?.toString();

    Future<String> getNameFromCustomId(String? customId) async {
      if (customId == null || customId.trim().isEmpty) return 'N/A';

      final res = await supabase
          .from('user_profiles')
          .select('name')
          .eq('custom_user_id', customId.trim())
          .maybeSingle();

      return res != null && res['name'] != null
          ? res['name'] as String
          : 'Unknown';
    }

    final driver = await getNameFromCustomId(assignedDriverId);
    final shipper = await getNameFromCustomId(assignedShipperId);
    final agent = await getNameFromCustomId(assignedAgentId);
    final company = await getNameFromCustomId(assignedCompanyId);

    setState(() {
      driverName = driver;
      shipperName = shipper;
      agentName = agent;
      companyName = company;
    });
  }

  Future<void> fetchDeliveryInfo() async {
    final response = await Supabase.instance.client
        .from('view_shipment_updates')
        .select('delivery_date, booking_status')
        .eq('shipment_id', widget.shipmentId)
        .maybeSingle();

    if (response != null) {
      final delivery = response['delivery_date'];
      final status = response['booking_status'];
      setState(() {
        bookingStatus = status;
        if (delivery != null) {
          deliveryDate = DateTime.parse(delivery);
          final diff = DateTime.now().difference(deliveryDate!).inDays;
          isWithin3Days = diff < 3;
        }
      });
    }
  }

  Future<void> fetchExistingRating() async {
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('shipment_reviews')
        .select()
        .eq('shipment_id', widget.shipmentId)
        .maybeSingle();

    if (data == null) return;

    switch (widget.userRole.toLowerCase()) {
      case 'shipper':
        setState(() {
          rating1 = (data['driver_rating_by_shipper'] ?? 0).toDouble();
          feedback1.text = data['driver_feedback_by_shipper'] ?? '';
          rating2 = (data['agent_rating_by_shipper'] ?? 0).toDouble();
          feedback2.text = data['agent_feedback_by_shipper'] ?? '';
        });
        break;
      case 'driver':
        setState(() {
          rating1 = (data['shipper_rating_by_driver'] ?? 0).toDouble();
          feedback1.text = data['shipper_feedback_by_driver'] ?? '';
          rating2 = (data['agent_rating_by_driver'] ?? 0).toDouble();
          feedback2.text = data['agent_feedback_by_driver'] ?? '';
        });
        break;
      case 'agent':
        setState(() {
          rating1 = (data['shipper_rating_by_agent'] ?? 0).toDouble();
          feedback1.text = data['shipper_feedback_by_agent'] ?? '';
          rating2 = (data['driver_rating_by_agent'] ?? 0).toDouble();
          feedback2.text = data['driver_feedback_by_agent'] ?? '';
        });
        break;
    }
  }

  Future<void> fetchEditCount() async {
    final response = await Supabase.instance.client
        .from('shipment_reviews')
        .select('edit_count')
        .eq('shipment_id', widget.shipmentId)
        .maybeSingle();

    setState(() {
      editCount = (response?['edit_count'] ?? 0) as int;
    });
  }

  Future<void> submitRating() async {
    if (editCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("edit_limit".tr())),
      );
      return;
    }

    final supabase = Supabase.instance.client;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final Map<String, dynamic> ratingData = {
      'shipment_id': widget.shipmentId,
      'date': today,
      'shipper_id': shipperName,
      'agent_id': agentName,
      'driver_id': driverName,
      'company_id': companyName,
      'edit_count': editCount + 1,
    };

    switch (widget.userRole.toLowerCase()) {
      case 'shipper':
        ratingData['driver_rating_by_shipper'] = rating1.toInt();
        ratingData['driver_feedback_by_shipper'] = feedback1.text;
        ratingData['agent_rating_by_shipper'] = rating2.toInt();
        ratingData['agent_feedback_by_shipper'] = feedback2.text;
        break;
      case 'driver':
        ratingData['shipper_rating_by_driver'] = rating1.toInt();
        ratingData['shipper_feedback_by_driver'] = feedback1.text;
        ratingData['agent_rating_by_driver'] = rating2.toInt();
        ratingData['agent_feedback_by_driver'] = feedback2.text;
        break;
      case 'agent':
        ratingData['shipper_rating_by_agent'] = rating1.toInt();
        ratingData['shipper_feedback_by_agent'] = feedback1.text;
        ratingData['driver_rating_by_agent'] = rating2.toInt();
        ratingData['driver_feedback_by_agent'] = feedback2.text;
        break;
    }

    try {
      await supabase.from('shipment_reviews').upsert(ratingData);

      if (context.mounted) {
        Navigator.pop(context, editCount + 1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("rating_saved".tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error_occurred".tr(args: [e.toString()]))),
      );
    }
  }

  @override
  void dispose() {
    feedback1.dispose();
    feedback2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditDisabled = editCount >= 3;

    final name1 = widget.userRole.toLowerCase() == 'shipper'
        ? driverName
        : (widget.userRole.toLowerCase() == 'manager'
        ? shipperName
        : shipperName);

    final name2 = widget.userRole.toLowerCase() == 'shipper'
        ? agentName
        : (widget.userRole.toLowerCase() == 'driver'
        ? agentName
        : driverName);

    return Scaffold(
      appBar: AppBar(
        title: Text("ratings".tr()),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: (deliveryDate != null && isWithin3Days)
            ? ListView(
          children: [
            Text("hello_user".tr(args: [widget.userRole]),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("shipment_id".tr(args: [widget.shipmentId])),
            Text("assigned_driver"
                .tr(args: [driverName ?? widget.assignedDriver ?? 'N/A'])),
            Text("assigned_agent"
                .tr(args: [agentName ?? widget.assignedAgent ?? 'N/A'])),
            Text("assigned_company"
                .tr(args: [companyName ?? widget.assignedCompany ?? 'N/A'])),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 24),
            Text("rate_person".tr(args: [name1 ?? label1]),
                style: const TextStyle(fontSize: 18)),
            RatingBar.builder(
              initialRating: rating1,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) =>
                  setState(() => rating1 = rating),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: feedback1,
              decoration: InputDecoration(
                labelText: "feedback_for".tr(args: [name1 ?? label1]),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            Text("rate_person".tr(args: [name2 ?? label2]),
                style: const TextStyle(fontSize: 18)),
            RatingBar.builder(
              initialRating: rating2,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) =>
                  setState(() => rating2 = rating),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: feedback2,
              decoration: InputDecoration(
                labelText: "feedback_for".tr(args: [name2 ?? label2]),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isEditDisabled ? null : submitRating,
              child: Text(isEditDisabled
                  ? "edit_limit".tr()
                  : (editCount > 0
                  ? "edit_rating".tr()
                  : "submit".tr())),
            ),
          ],
        )
            : Center(
          child: Text(
            deliveryDate == null
                ? "delivery_not_available".tr()
                : "rating_expired".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
