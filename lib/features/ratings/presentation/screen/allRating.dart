import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TripRatingsPage1 extends StatelessWidget {
  final List<Map<String, dynamic>> trips = [
    {
      'tripId': 'SHP-20250612-0006',
      'shipper': 'ABC Logistics',
      'from': 'Mumbai',
      'to': 'Pune',
      'rating': 5,
      'Date': '12/06/2025',
      'feedback': 'Smooth delivery and professional driver.',
    },
    {
      'tripId': 'SHP-20250612-0002',
      'shipper': 'QuickShip Pvt Ltd',
      'from': 'Delhi',
      'to': 'Chandigarh',
      'rating': 4,
      'Date': '12/05/2025',
      'feedback': 'Good service but arrived slightly late.',
    },
    {
      'tripId': 'SHP-20250612-0003',
      'shipper': 'Mega Movers',
      'from': 'Bangalore',
      'to': 'Hyderabad',
      'rating': 3,
      'Date': '12/04/2025',
      'feedback': 'Driver was polite but vehicle needed maintenance.',
    },
  ];

  void showTripDetailsPopup(BuildContext context, Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('trip_details'.tr(),
            style: TextStyle(color: Colors.blueAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.numbers, color: Colors.blueAccent, size: 20),
                SizedBox(width: 3),
                infoRow('trip_id'.tr(), trip['tripId']),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blueAccent, size: 20),
                SizedBox(width: 5),
                infoRow('shipper'.tr(), trip['shipper']),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.blueAccent, size: 20),
                SizedBox(width: 5),
                infoRow('date'.tr(), trip['Date']),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.route, color: Colors.blueAccent, size: 20),
                SizedBox(width: 5),
                infoRow('route'.tr(),
                    '${trip['from']} → ${trip['to']}'),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.feedback, color: Colors.blueAccent, size: 20),
                SizedBox(width: 5),
                Text(
                  'feedback'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 4),
            Container(
              constraints: BoxConstraints(maxHeight: 100),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                child: Text(
                  trip['feedback'],
                  style: TextStyle(color: Colors.black87, fontSize: 15),
                ),
              ),
            ),
            Divider(thickness: 1, color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < trip['rating'] ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(),
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  static Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_performance'.tr()),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: trips.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            double avgRating =
                trips.map((t) => t['rating'] as int).reduce((a, b) => a + b) /
                    trips.length;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("overall_performance".tr(),
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Text("average_rating".tr(),
                          style: TextStyle(fontSize: 16)),
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    "total_trips".tr(args: [trips.length.toString()]),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text("tap_trip_feedback".tr(),
                      style:
                      TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final trip = trips[index - 1];
          return GestureDetector(
            onTap: () => showTripDetailsPopup(context, trip),
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: EdgeInsets.all(12),
                height: 170,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        trip['tripId'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 5),
                            Text(
                              '${'shipper'.tr()}: ${trip['shipper']}',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.my_location,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 5),
                            Text(
                              '${'origin'.tr()}: ${trip['from']}',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.black87),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 5),
                            Text(
                              '${'destination'.tr()}: ${trip['to']}',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.black87),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.date_range,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 5),
                            Text(
                              '${'date'.tr()}: ${trip['Date']}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: List.generate(5, (star) {
                            return Icon(
                              star < trip['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 22,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
