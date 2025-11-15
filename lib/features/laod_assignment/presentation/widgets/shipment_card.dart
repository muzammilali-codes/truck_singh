import 'package:flutter/material.dart';
import '../invoice/services/invoice_pdf_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../ratings/presentation/screen/rating.dart';

class ShipmentCard extends StatefulWidget {
  final Map<String, dynamic> shipment;
  final VoidCallback? onPreviewInvoice;
  final VoidCallback? onDownloadInvoice;
  final VoidCallback? onRequestInvoice;
  final VoidCallback? onGenerateInvoice;
  final VoidCallback? onDeleteInvoice;
  final VoidCallback? onShareInvoice;
  final VoidCallback? onTap;
  final String? customUserId;
  final String? role;
  final Map<String, PdfState> pdfStates;

  const ShipmentCard({
    super.key,
    required this.shipment,
    this.onPreviewInvoice,
    this.onDownloadInvoice,
    this.onRequestInvoice,
    this.onGenerateInvoice,
    this.onDeleteInvoice,
    this.onShareInvoice,
    this.onTap,
    required this.pdfStates,
    required this.role,
    required this.customUserId,
  });

  @override
  State<ShipmentCard> createState() => _ShipmentCardState();
}

class _ShipmentCardState extends State<ShipmentCard> {
  // function to full trim address
  String trimAddress(String address) {
    // Remove common redundant words
    String cleaned = address
        .replaceAll(
      RegExp(
        r'\b(At Post|Post|Tal|Taluka|Dist|District|Po)\b',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(RegExp(r'\s+'), ' ') // normalize spaces
        .trim();

    List<String> parts = cleaned.split(',');
    parts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    if (parts.length >= 3) {
      String first = parts[0]; // village/area
      String city = parts[parts.length - 2];
      //String state = parts[parts.length - 1];
      return "$first,$city";
    } else if (parts.length == 2) {
      return "${parts[0]}, ${parts[1]}";
    } else {
      // fallback: just shorten
      return cleaned.length > 50 ? "${cleaned.substring(0, 50)}..." : cleaned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipmentId = widget.shipment['shipment_id'] ?? 'Unknown';
    final completedAt = widget.shipment['delivery_date'] ?? '';

    return InkWell(
      onTap: widget.onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row : ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$shipmentId",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // completed date
              Text(
                "completed : $completedAt".tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // pickup and drop address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'PICKUP: ${trimAddress(widget.shipment['pickup'] ?? '')}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'DROP: ${trimAddress(widget.shipment['drop'] ?? '')}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              buildActionButtons(
                widget.shipment,
                context,
                widget.customUserId,
                widget.role,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButtons(
      Map<String, dynamic> shipment,
      BuildContext context,
      String? customUserId,
      String? role,
      ) {
    final shipperId = shipment['shipper_id']?.toString();
    final shipmentId = shipment['shipment_id'].toString();
    final assignCompanyId = shipment['assigned_agent']?.toString();
    final driverId = shipment['assigned_driver']?.toString();
    final invoicePath = shipment['Invoice_link'];
    final hasInvoice =
        invoicePath != null && invoicePath.toString().trim().isNotEmpty;
    final state = widget.pdfStates[shipmentId] ?? PdfState.notGenerated;

    print("buildActionButtons: role=$role, customUserId=$customUserId, shipperId=$shipperId, assignedCompanyId=$assignCompanyId, hasInvoice=$hasInvoice, state=$state");
// And optionally:
    print("Shipment: ${shipment['shipment_id']}, assigned_agent=${shipment['assigned_agent']}, shipper_id=${shipment['shipper_id']}");


    // Case 1: Shipper
    if (role == 'shipper' && customUserId == shipperId.toString()) {
      if (hasInvoice) {
        return Wrap(
          spacing: 8,
          children: [
            SizedBox(
              //width: 130,
              child: ElevatedButton.icon(
                onPressed: state == PdfState.downloaded
                    ? null
                    : widget.onDownloadInvoice,
                icon: const Icon(Icons.download),
                label: Text(
                  state == PdfState.downloaded ? "downloaded".tr() : "download".tr(),
                ),
              ),
            ),
            IconButton(
              onPressed:
              state == PdfState.downloaded ? widget.onPreviewInvoice : null,
              icon: const Icon(Icons.visibility),
              tooltip: 'preview_pdf'.tr(),
            ),
          ],
        );
      } else {
        return SizedBox(
          //width: 160,
          child: ElevatedButton.icon(
            onPressed: widget.onRequestInvoice,
            icon: const Icon(Icons.receipt_rounded),
            label:  Text("request_invoice".tr()),
          ),
        );
      }
    }

    // Case 2: Assigned Company
    if ((role == 'company' ||
        role == 'agent' && customUserId == assignCompanyId.toString())) {
      /*final isCompleted =
      (shipment['delivery_date'] != null &&
          shipment['delivery_date'].toString().isNotEmpty);*/
      if (hasInvoice) {
        return Wrap(
          spacing: 8,
          children: [
            SizedBox(
              //width: 130,
              child: ElevatedButton.icon(
                onPressed: state == PdfState.downloaded
                    ? null
                    : widget.onDownloadInvoice,
                icon: const Icon(Icons.download),
                label: Text(
                  state == PdfState.downloaded ? "downloaded".tr() : "download".tr(),
                ),
              ),
            ),
            IconButton(
              onPressed:
              state == PdfState.downloaded ? widget.onPreviewInvoice : null,
              icon: const Icon(Icons.visibility),
              tooltip: 'preview_pdf'.tr(),
            ),
            IconButton(
              onPressed:
              state == PdfState.downloaded ? widget.onShareInvoice : null,
              icon: const Icon(Icons.share),
              tooltip: 'share_invoice'.tr(),
            ),
            IconButton(
              onPressed:
              state == PdfState.downloaded ? widget.onDeleteInvoice : null,
              icon: const Icon(Icons.delete),
              tooltip: 'delete_pdf'.tr(),
            ),
          ],
        );
      } else /*if (isCompleted)*/ {
        return SizedBox(
          //width: 160,
          child: ElevatedButton.icon(
            onPressed: widget.onGenerateInvoice,
            icon: const Icon(Icons.receipt),
            label:  Text("generate_invoice".tr()),
          ),
        );
      }
    }

    // Case 3: driver
    if (role == 'driver' && customUserId == driverId) {
      return Wrap(
        spacing: 8,
        children: [
          SizedBox(
            //width: 130,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Rating(
                      shipmentId: shipmentId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.star),
              label: Text(
                "rate".tr(),
              ),
            ),
          ),
        ],
      );
    }

    else {
      return const SizedBox();
    }
  }
}