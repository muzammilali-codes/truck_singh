import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
// A model to represent a driver's document
class DriverDocument {
  final String type;
  final String? fileUrl;
  final String status;

  DriverDocument({required this.type, this.fileUrl, required this.status});
}

class DocumentVaultPage extends StatefulWidget {
  const DocumentVaultPage({super.key});

  @override
  State<DocumentVaultPage> createState() => _DocumentVaultPageState();
}

class _DocumentVaultPageState extends State<DocumentVaultPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _customUserId; // To store the user's custom ID
  List<DriverDocument> _documents = [];

  // Define the list of required documents for a driver
  final List<String> _requiredDocTypes = [
    'Drivers License',
    'Vehicle Registration',
    'Vehicle Insurance',
    'Aadhaar Card',
    'PAN Card',
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _fetchCustomUserId();
    await _fetchDriverDocuments();
  }

  /// Fetches the user's custom_user_id from their profile.
  Future<void> _fetchCustomUserId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated.");

      final response = await _supabase
          .from('user_profiles')
          .select('custom_user_id')
          .eq('user_id', userId)
          .single();

      if (mounted) {
        setState(() {
          _customUserId = response['custom_user_id'];
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Could not load user profile ID.");
      }
    }
  }

  /// Fetches the driver's uploaded documents from the database.
  Future<void> _fetchDriverDocuments() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not authenticated.");
      }

      final response = await _supabase
          .from('driver_documents')
          .select()
          .eq('user_id', userId);

      final uploadedDocs = (response as List)
          .map(
            (doc) => DriverDocument(
              type: doc['document_type'],
              fileUrl: doc['file_url'],
              status: doc['status'],
            ),
          )
          .toList();

      // Create a full list of documents, showing the status for required ones
      final allDocs = _requiredDocTypes.map((type) {
        final existingDoc = uploadedDocs.firstWhere(
          (doc) => doc.type == type,
          orElse: () => DriverDocument(type: type, status: 'not_uploaded'.tr()),
        );
        return existingDoc;
      }).toList();

      if (mounted) {
        setState(() {
          _documents = allDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Error fetching documents: ${e.toString()}");
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles the file picking and uploading process for a specific document type.
  Future<void> _uploadDocument(String docType) async {
    if (_customUserId == null) {
      _showErrorSnackBar("User ID not loaded. Cannot upload document.");
      return;
    }

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final file = File(imageFile.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';

      // MODIFIED: Use custom_user_id for the folder path
      final folderPath = '$_customUserId/$docType';
      final filePath = '$folderPath/$fileName';

      // --- NEW LOGIC: Delete previous file if it exists ---
      final existingFiles = await _supabase.storage
          .from('driver-documents')
          .list(path: folderPath);
      if (existingFiles.isNotEmpty) {
        final filesToDelete =
            existingFiles.map((file) => '$folderPath/${file.name}').toList();
        await _supabase.storage.from('driver-documents').remove(filesToDelete);
        print("Removed ${filesToDelete.length} old file(s).");
      }
      // ----------------------------------------------------

      // Upload the new file to Supabase Storage
      await _supabase.storage.from('driver-documents').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the public URL of the uploaded file
      final fileUrl =
          _supabase.storage.from('driver-documents').getPublicUrl(filePath);

      // Upsert the document metadata into the database table
      await _supabase.from('driver_documents').upsert({
        'user_id': userId,
        'document_type': docType,
        'file_url': fileUrl,
        'status': 'uploaded',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, document_type');

      _showSuccessSnackBar("document_uploaded_successfully".tr());
    } catch (e) {
      _showErrorSnackBar("Upload failed: ${e.toString()}");
    } finally {
      // Refresh the document list after upload
      await _fetchDriverDocuments();
    }
  }

  /// Opens the document URL in a browser.
  Future<void> _viewDocument(String? url) async {
    if (url == null) {
      _showErrorSnackBar("no_file_url".tr());
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar("could_not_open_document".tr());
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("document_vault".tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDriverDocuments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  return _buildDocumentCard(doc);
                },
              ),
            ),
    );
  }

  Widget _buildDocumentCard(DriverDocument doc) {
    final bool isUploaded = doc.status != 'Not Uploaded';
    IconData statusIcon;
    Color statusColor;

    switch (doc.status.toLowerCase()) {
      case 'verified':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      case 'uploaded':
        statusIcon = Icons.hourglass_top;
        statusColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.cloud_off;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.type,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  doc.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUploaded)
                  TextButton(
                    onPressed: () => _viewDocument(doc.fileUrl),
                    child:  Text("view".tr()),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _uploadDocument(doc.type),
                  child: Text(isUploaded ? "re_upload".tr() : "upload".tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
