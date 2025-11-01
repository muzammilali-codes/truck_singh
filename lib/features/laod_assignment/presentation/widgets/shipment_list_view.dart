import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/shipment_cubit.dart'; // Import Cubit to call methods
import 'shipment_card.dart'; // Import the card widget
import 'package:easy_localization/easy_localization.dart';
class ShipmentListView extends StatelessWidget {
  final List<Map<String, dynamic>> shipments;
  final String searchQuery;

  const ShipmentListView({
    super.key,
    required this.shipments,
    required this.searchQuery,
  });

  void showAcceptConfirmationDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('confirm_shipment'.tr()),
      content: Text('confirm_accept_message'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(), // Cancel
          child:  Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop(); // Close the dialog
            onConfirm(); // Proceed with accepting the shipment
          },
          child:  Text('yes_accept'.tr()),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredList = searchQuery.isEmpty
        ? shipments
        : shipments.where((trip) {
            final id = (trip['shipment_id'] ?? '').toString().toLowerCase();
            final source = (trip['pickup'] ?? '').toString().toLowerCase();
            final dest = (trip['drop'] ?? '').toString().toLowerCase();
            final shipperName = (trip['user_profiles']?['name'] ?? '')
                .toString()
                .toLowerCase();

            return id.contains(searchQuery) ||
                source.contains(searchQuery) ||
                dest.contains(searchQuery) ||
                shipperName.contains(searchQuery);
          }).toList();

    if (filteredList.isEmpty) {
      return  Center(child: Text('no_shipments_match'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final trip = filteredList[index];
        return ShipmentCard(
          trip: trip,
          onAccept: () {
            // Show confirmation dialog
            showAcceptConfirmationDialog(context, () {
              // Proceed to accept shipment if user confirms
              context.read<ShipmentCubit>().acceptShipment(
                shipmentId: trip['shipment_id'],
              );

              // Optionally show Snackbar after accepting
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('shipment accepted'.tr())),
              );
            });
          },
        );
      },
    );
  }
}
