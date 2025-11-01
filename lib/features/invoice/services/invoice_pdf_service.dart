import 'dart:typed_data';
import 'package:intl/intl.dart';
// import 'package:new_test1/models/address_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/model/address_model.dart';

enum PdfState { notGenerated, uploaded, downloaded }

Future<String> generateInvoicePDF({
  required Map<String, dynamic> shipment,
  required String price,
  required String companyName,
  required String companyAddress,
  required String companyMobile,
  required String customerName,
  required String customerAddress,
  required BillingAddress? billingAddress,
  required String customerMobile,
  required String invoiceNo,
  CompanyAddress? companySelectedAddress,
  required String bankName,
  required String accountNumber,
  required String ifscCode,
  required String branch,
  required String accountHolder,
  required String gstNumber,
  required String taxPercentage,
  required String taxAmount,
  required String totalAmount,
  required String taxType,
}) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final PdfColor primaryColor = PdfColors.blue800;
  final PdfColor secondaryColor = PdfColors.blueGrey600;
  final PdfColor tableHeaderColor = PdfColors.blue100;
  final PdfColor borderColor = PdfColors.blueGrey300;

  String formatAddress(String address) => address.replaceAll(", ", ",\n");

  String finalCompanyAddress = companyAddress.isNotEmpty
      ? companyAddress
      : (companySelectedAddress != null
      ? '${companySelectedAddress.flatNo}, ${companySelectedAddress.streetName}, ${companySelectedAddress.cityName}, ${companySelectedAddress.district}, ${companySelectedAddress.zipCode}'
      : '');

  String finalCustomerAddress = customerAddress.isNotEmpty
      ? customerAddress
      : (billingAddress != null
      ? '${billingAddress.flatNo}, ${billingAddress.streetName}, ${billingAddress.cityName}, ${billingAddress.district}, ${billingAddress.zipCode}'
      : '');

  String shiptoAddress = shipment['drop'] ?? 'N/A';

  String numberToWords(String number) {
    try {
      final n = double.tryParse(number) ?? 0.0;
      return "${n.toStringAsFixed(2)} Rupees only";
    } catch (_) {
      return "$number Rupees only";
    }
  }

  pw.Widget sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      color: tableHeaderColor,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),

      build: (context) => [
        // Header row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(companyName,
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor)),
                pw.SizedBox(height: 6),
                pw.Text(formatAddress(finalCompanyAddress),
                    style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                pw.Text('Phone: $companyMobile',
                    style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                pw.Text("GSTIN: $gstNumber",
                    style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
              ],
            ),
            pw.Container(
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: primaryColor, width: 2),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: primaryColor),
              padding:
              const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: pw.Text("TAX INVOICE",
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            )
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: borderColor, thickness: 2),

        // Address and invoice info
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.8)),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionHeader('Bill To'),
                    pw.SizedBox(height: 6),
                    pw.Text(customerName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text(formatAddress(finalCustomerAddress),
                        style: pw.TextStyle(fontSize: 10)),
                    pw.Text('Mobile: $customerMobile',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.8)),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionHeader('Ship To'),
                    pw.SizedBox(height: 6),
                    pw.Text(shiptoAddress,
                        style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                    pw.Text('Mobile: $customerMobile',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.8)),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionHeader('Invoice Details'),
                    pw.SizedBox(height: 6),
                    pw.Text("Invoice No: $invoiceNo",
                        style: pw.TextStyle(fontSize: 11)),
                    pw.Text("Date: ${DateFormat('dd-MM-yyyy').format(now)}",
                        style: pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 24),

        // Items table header
        pw.Container(
          color: tableHeaderColor,
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 1, child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 4, child: pw.Text('Item name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              //pw.Expanded(flex: 3, child: pw.Text('HSN/SAC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 2, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 3, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 2, child: pw.Text('Taxable amt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

              if (taxType == "CGST+SGST") ...[
                pw.Expanded(flex: 2, child: pw.Text('CGST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('SGST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ] else ...[
                pw.Expanded(flex: 2, child: pw.Text('IGST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],

              pw.Expanded(flex: 3, child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),

        // Item row
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200))),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 1, child: pw.Text('1')),
              pw.Expanded(flex: 4, child: pw.Text(shipment['shipping_item'] ?? 'Logistic SERVICES')),
              //pw.Expanded(flex: 3, child: pw.Text('999312')),
              /*pw.Expanded(flex: 2, child: pw.Text('${shipment['weight'] ?? '1'} Ton')),*/
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '${shipment['weight'] != null && shipment['weight'].toString().trim().isNotEmpty ? '${shipment['weight']} Ton' : (shipment['unit'] ?? '')}',
                ),
              ),

              pw.Expanded(flex: 3, child: pw.Text('${shipment['material_inside'] ?? 'null'}')),
              pw.Expanded(flex: 2, child: pw.Text('$price')),
              pw.Expanded(flex: 2, child: pw.Text('$taxAmount')),

              if (taxType == "CGST+SGST") ...[
                pw.Expanded(flex: 2, child: pw.Text('${(double.tryParse(taxAmount) ?? 0) / 2} (${(double.tryParse(taxPercentage) ?? 0) / 2}%)')),
                pw.Expanded(flex: 2, child: pw.Text('${(double.tryParse(taxAmount) ?? 0) / 2} (${(double.tryParse(taxPercentage) ?? 0) / 2}%)')),
              ] else ...[
                pw.Expanded(flex: 2, child: pw.Text('$taxPercentage%')),
              ],

              pw.Expanded(flex: 3, child: pw.Text('$totalAmount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sub Total: $price', style: pw.TextStyle(fontSize: 11)),

                if (taxType == "CGST+SGST") ...[
                  pw.Text('CGST: ${(double.tryParse(taxAmount) ?? 0) / 2}', style: pw.TextStyle(fontSize: 11)),
                  pw.Text('SGST: ${(double.tryParse(taxAmount) ?? 0) / 2}', style: pw.TextStyle(fontSize: 11)),
                ] else ...[
                  pw.Text('IGST: $taxAmount', style: pw.TextStyle(fontSize: 11)),
                ],

                pw.Text('Total: $totalAmount',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        color: primaryColor)),
              ],
            )
          ],
        ),

        pw.SizedBox(height: 12),

        pw.Divider(height: 30, color: borderColor),

        // Bank Details
        sectionHeader('Bank Details'),
        pw.SizedBox(height: 6),
        pw.Text('Bank Name: $bankName', style: pw.TextStyle(fontSize: 10)),
        pw.Text('Branch: $branch', style: pw.TextStyle(fontSize: 10)),
        pw.Text('Account Number: $accountNumber', style: pw.TextStyle(fontSize: 10)),
        pw.Text('IFSC Code: $ifscCode', style: pw.TextStyle(fontSize: 10)),
        pw.Text('Account Holder\'s Name: $accountHolder', style: pw.TextStyle(fontSize: 10)),

        pw.SizedBox(height: 24),

        // Footer
        pw.Text('Terms and Conditions:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.Text('This is computer generated invoice',
            style: pw.TextStyle(fontSize: 10, color: secondaryColor)),

        pw.SizedBox(height: 40),
      ],
    ),
  );

  Uint8List pdfBytes = await pdf.save();

  final userId = Supabase.instance.client.auth.currentUser!.id;
  final profile = await Supabase.instance.client
      .from('user_profiles')
      .select('custom_user_id')
      .eq('user_id', userId)
      .maybeSingle();

  final shipperId = profile?['custom_user_id'];
  final fileName = '$shipperId/${shipment['shipment_id']}.pdf';

  try {
    await Supabase.instance.client.storage
        .from('invoices')
        .uploadBinary(fileName, pdfBytes, fileOptions: const FileOptions(upsert: true));
  } catch (e) {
    throw Exception('Upload failed: $e');
  }

  final publicUrl =
  Supabase.instance.client.storage.from('invoices').getPublicUrl(fileName);

  await Printing.layoutPdf(onLayout: (format) async => pdfBytes);

  return publicUrl;
}
