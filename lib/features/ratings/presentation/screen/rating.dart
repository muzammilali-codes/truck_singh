import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class Rating extends StatefulWidget {
  final String shipmentId;
  const Rating({super.key, required this.shipmentId});

  @override
  State<Rating> createState() => _RatingState();
}

class _RatingState extends State<Rating> {
  double ratingDriver = 0;
  double ratingAgent = 0;
  TextEditingController feedbackDriver = TextEditingController();
  TextEditingController feedbackAgent = TextEditingController();
  bool isLoading = true;

  final _client = Supabase.instance.client;

  //Submit rating part below
  Future<int> submitRating({
    required String shipmentId,
    required String person1Id,
    required String person2Id,
    required double rating1,
    required double rating2,
    required String feedback1,
    required String feedback2,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception(tr("error_user_not_authenticated"));
    }

    final profileResponse = await _client
        .from('user_profiles')
        .select('role, custom_user_id')
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception(tr("error_user_profile_not_found"));
    }

    final currentUserRole =
    (profileResponse['role'] as String?)?.trim().toLowerCase();
    final currentUserCustomId = profileResponse['custom_user_id'] as String?;

    final shipmentResponse = await _client
        .from('shipment')
        .select('assigned_driver, assigned_agent, shipper_id')
        .eq('shipment_id', shipmentId)
        .maybeSingle();

    if (shipmentResponse == null) {
      throw Exception(tr("error_shipment_not_found"));
    }

    final driverId = shipmentResponse['assigned_driver'] as String?;
    final agentId = shipmentResponse['assigned_agent'] as String?;
    final shipperId = shipmentResponse['shipper_id'] as String?;

    final List<Map<String, dynamic>> ratingsToSubmit = [];

    switch (currentUserRole) {
      case 'shipper':
        if (driverId != null) {
          ratingsToSubmit.add({
            'shipment_id': shipmentId,
            'rater_id': currentUserCustomId,
            'ratee_id': driverId,
            'rater_role': 'Shipper',
            'ratee_role': 'Driver',
            'rating': rating1.round(),
            'feedback': feedback1.isNotEmpty ? feedback1 : null,
          });
        }
        if (agentId != null) {
          ratingsToSubmit.add({
            'shipment_id': shipmentId,
            'rater_id': currentUserCustomId,
            'ratee_id': agentId,
            'rater_role': 'Shipper',
            'ratee_role': 'Agent',
            'rating': rating2.round(),
            'feedback': feedback2.isNotEmpty ? feedback2 : null,
          });
        }
        break;
      case 'driver':
        if (shipperId != null) {
          ratingsToSubmit.add({
            'shipment_id': shipmentId,
            'rater_id': currentUserCustomId,
            'ratee_id': shipperId,
            'rater_role': 'Driver',
            'ratee_role': 'Shipper',
            'rating': rating1.round(),
            'feedback': feedback1.isNotEmpty ? feedback1 : null,
          });
        }
        break;
      case 'agent':
        if (shipperId != null) {
          ratingsToSubmit.add({
            'shipment_id': shipmentId,
            'rater_id': currentUserCustomId,
            'ratee_id': shipperId,
            'rater_role': 'Agent',
            'ratee_role': 'Shipper',
            'rating': rating1.round(),
            'feedback': feedback1.isNotEmpty ? feedback1 : null,
          });
        }
        break;
      default:
        throw Exception("${tr("error_invalid_role")}: $currentUserRole");
    }

    if (ratingsToSubmit.isEmpty) {
      throw Exception(tr("error_no_ratings_to_submit"));
    }

    int finalEditCount = 0;
    for (final rating in ratingsToSubmit) {
      final existingRating = await _client
          .from('ratings')
          .select('edit_count')
          .eq('shipment_id', rating['shipment_id'])
          .eq('rater_id', rating['rater_id'])
          .eq('ratee_id', rating['ratee_id'])
          .maybeSingle();

      int currentEditCount = existingRating?['edit_count'] as int? ?? 0;

      final newEditCount = currentEditCount + 1;
      finalEditCount = newEditCount;

      if (newEditCount > 3) {
        throw Exception(tr("error_edit_limit_reached"));
      }

      rating['edit_count'] = newEditCount;

      final upsertResponse = await _client
          .from('ratings')
          .upsert(rating, onConflict: 'shipment_id, rater_id, ratee_id')
          .select();

      debugPrint("Upsert result: $upsertResponse");
    }

    return finalEditCount;
  }

  String? shipperName;
  String? driverName;
  String? agentName;
  String? driverId;
  String? agentId;
  String? shipperId;

  @override
  void initState() {
    super.initState();
    _fetchNames().then((_) {
      fetchExistingRating();
    });
  }

  Future<void> _fetchNames() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception(tr("error_no_logged_in_user"));

      final currentProfile = await _client
          .from('user_profiles')
          .select('custom_user_id,name,role')
          .eq('user_id', userId)
          .single();

      shipperId = currentProfile['custom_user_id'];
      shipperName = currentProfile['name'];

      final shipment = await _client
          .from('shipment')
          .select('assigned_driver,assigned_agent')
          .eq('shipment_id', widget.shipmentId)
          .single();

      driverId = shipment['assigned_driver'];
      agentId = shipment['assigned_agent'];

      if (driverId != null) {
        final driverProfile = await _client
            .from('user_profiles')
            .select('name')
            .eq('custom_user_id', driverId!)
            .maybeSingle();

        driverName = driverProfile?['name'] ?? tr("default_driver");
      }
      if (agentId != null) {
        final agentProfile = await _client
            .from('user_profiles')
            .select('name')
            .eq('custom_user_id', agentId!)
            .maybeSingle();

        agentName = agentProfile?['name'] ?? tr("default_agent");
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error fetching name: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchExistingRating() async {
    try {
      final supabase = Supabase.instance.client;

      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final profile = await supabase
          .from('user_profiles')
          .select('custom_user_id')
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (profile == null) return;
      final currentUserCustomId = profile['custom_user_id'];

      final existingRatings = await supabase
          .from('ratings')
          .select('ratee_id,rating,feedback')
          .eq('shipment_id', widget.shipmentId)
          .eq('rater_id', currentUserCustomId);

      for (var r in existingRatings) {
        if (r['ratee_id'] == driverId) {
          ratingDriver = (r['rating'] as num?)?.toDouble() ?? 0;
          feedbackDriver.text = r['feedback'] ?? '';
        } else if (r['ratee_id'] == agentId) {
          ratingAgent = (r['rating'] as num?)?.toDouble() ?? 0;
          feedbackAgent.text = r['feedback'] ?? '';
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint("Error fetching existing ratings: $e");
    }
  }

  void _handleSubmitRating() async {
    try {
      final updatedEditCount = await submitRating(
        shipmentId: widget.shipmentId,
        person1Id: driverId ?? '',
        person2Id: agentId ?? '',
        rating1: ratingDriver,
        rating2: ratingAgent,
        feedback1: feedbackDriver.text,
        feedback2: feedbackAgent.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("ratings_submitted_successfully"))),
      );
      Navigator.pop(context, updatedEditCount);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr("error")}: $e')));
    }
  }

  Widget buildShimmerSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        shimmerBox(
          height: 28,
          width: 200,
          margin: const EdgeInsets.only(bottom: 18),
        ),
        shimmerBox(
          height: 60,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
        ),
        const SizedBox(height: 10),
        shimmerBox(
          height: 20,
          width: 150,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        shimmerStars(),
        shimmerBox(
          height: 70,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
        ),
        const SizedBox(height: 20),
        shimmerBox(
          height: 20,
          width: 150,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        shimmerStars(),
        shimmerBox(
          height: 70,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
        ),
        const SizedBox(height: 10),
        shimmerBox(
          height: 48,
          width: double.infinity,
          margin: EdgeInsets.zero,
          borderRadius: 24,
        ),
      ],
    );
  }

  Widget shimmerBox({
    required double height,
    required double width,
    required EdgeInsets margin,
    double borderRadius = 8.0,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget shimmerStars() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: List.generate(5, (_) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: shimmerBox(
              height: 24,
              width: 24,
              margin: EdgeInsets.zero,
              borderRadius: 12,
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    feedbackDriver.dispose();
    feedbackAgent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr("rate_shipment"))),
        body: buildShimmerSkeleton(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr("rate_shipment"))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${tr("hello")} ${shipperName ?? ''},",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "${tr("assigned_driver")}: $driverName",
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              "${tr("assigned_agent")}: $agentName",
              style: const TextStyle(fontSize: 15),
            ),
            const Divider(),
            const SizedBox(height: 20),
            if (driverName != null) ...[
              Text("${tr("rate")} $driverName",
                  style: const TextStyle(fontSize: 16)),
              RatingBar.builder(
                initialRating: ratingDriver,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) =>
                    setState(() => ratingDriver = rating),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackDriver,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: tr("feedback_for_driver"),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (agentName != null) ...[
              Text("${tr("rate")} $agentName",
                  style: const TextStyle(fontSize: 16)),
              RatingBar.builder(
                initialRating: ratingAgent,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) =>
                    setState(() => ratingAgent = rating),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackAgent,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: tr("feedback_for_agent"),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
            ],
            Center(
              child: ElevatedButton.icon(
                onPressed: _handleSubmitRating,
                icon: const Icon(Icons.send),
                label: Text(tr("submit_ratings")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
