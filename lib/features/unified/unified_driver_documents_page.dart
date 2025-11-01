import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:logistics_toolkit/config/theme.dart';
import 'package:intl/intl.dart';
import '../../config/document_types_config.dart';
import '../../services/user_data_service.dart';

enum UserRole { agent, truckOwner, driver }

class UnifiedDriverDocumentsPage extends StatefulWidget {
  const UnifiedDriverDocumentsPage({super.key});

  @override
  State<UnifiedDriverDocumentsPage> createState() =>
      _UnifiedDriverDocumentsPageState();
}

class _UnifiedDriverDocumentsPageState extends State<UnifiedDriverDocumentsPage>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _uploadingDriverId;
  String? _uploadingDocType;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _filteredDrivers = [];
  String? _loggedInUserId;
  UserRole? _userRole;
  late AnimationController _animationController;
  String _selectedStatusFilter = 'All';
  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  // Use centralized document types configuration
  Map<String, Map<String, dynamic>> get _documentTypes =>
      DocumentTypes.allDocuments;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializePage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    try {
      final userId = await UserDataService.getCustomUserId();
      if (!mounted) return;

      if (userId == null) {
        _showErrorSnackBar('auth_required'.tr());
        setState(() => _isLoading = false);
        return;
      }

      _loggedInUserId = userId;

      // Detect user role automatically
      await _detectUserRole();

      // Debug: Show detected role
      print('Detected role for user $_loggedInUserId: $_userRole');

      await _fetchDriversWithDocStatus();
      _animationController.forward();
    } catch (e) {
      _showErrorSnackBar('Failed to initialize page: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _detectUserRole() async {
    if (_loggedInUserId == null) return;

    try {
      // Check user role from user_profiles table first
      final userProfileCheck = await supabase
          .from('user_profiles')
          .select('role')
          .eq('custom_user_id', _loggedInUserId!)
          .limit(1);

      if (userProfileCheck.isNotEmpty) {
        final role = userProfileCheck.first['role'];
        if (role == 'driver') {
          _userRole = UserRole.driver;
          return;
        } else if (role == 'truck_owner' ||
            role.toString().toLowerCase().contains('truck')) {
          _userRole = UserRole.truckOwner;
          return;
        } else if (role == 'agent' ||
            role.toString().toLowerCase().contains('agent')) {
          _userRole = UserRole.agent;
          return;
        }
      }

      // Fallback: Check if user exists in driver_relation (agent)
      final agentRelations = await supabase
          .from('driver_relation')
          .select('owner_custom_id')
          .eq('owner_custom_id', _loggedInUserId!)
          .limit(1);

      if (agentRelations.isNotEmpty) {
        _userRole = UserRole.agent;
        return;
      }

      // Fallback: Check if user exists in truck_owner_driver_relation (truck owner)
      final truckOwnerRelations = await supabase
          .from('truck_owner_driver_relation')
          .select('truck_owner_custom_id')
          .eq('truck_owner_custom_id', _loggedInUserId!)
          .limit(1);

      if (truckOwnerRelations.isNotEmpty) {
        _userRole = UserRole.truckOwner;
        return;
      }

      // If no role found, default to driver (safest option - no approve/reject permissions)
      _userRole = UserRole.driver;
      print(
        'Warning: Could not determine user role for $_loggedInUserId, defaulting to driver',
      );
    } catch (e) {
      // Default to driver on error (safest option - no approve/reject permissions)
      _userRole = UserRole.driver;
      print('Error detecting user role: $e, defaulting to driver');
    }
  }

  Future<void> _fetchDriversWithDocStatus() async {
    if (_loggedInUserId == null || _userRole == null) return;

    try {
      List<dynamic> relations;

      // Get drivers based on user role
      if (_userRole == UserRole.agent || _userRole == UserRole.truckOwner) {
        // Both agents and truck owners use the same driver_relation table
        relations = await supabase
            .from('driver_relation')
            .select('driver_custom_id')
            .eq('owner_custom_id', _loggedInUserId!);
      } else if (_userRole == UserRole.driver) {
        // For drivers, show all drivers' documents (can view all, but upload restrictions apply)
        // First get the owner ID for this driver
        final driverOwnerRelation = await supabase
            .from('driver_relation')
            .select('owner_custom_id')
            .eq('driver_custom_id', _loggedInUserId!);

        if (driverOwnerRelation.isNotEmpty) {
          final ownerId = driverOwnerRelation.first['owner_custom_id'];
          // Get all drivers under the same owner (including self)
          relations = await supabase
              .from('driver_relation')
              .select('driver_custom_id')
              .eq('owner_custom_id', ownerId);
        } else {
          // Fallback: show only their own documents if no owner relation found
          relations = [
            {'driver_custom_id': _loggedInUserId},
          ];
        }
      } else {
        relations = [];
      }

      // Debug: Show what relations were found
      print('User role: $_userRole, User ID: $_loggedInUserId');
      print('Found relations: ${relations.length} - $relations');

      if (relations.isEmpty) {
        print(
          'No relations found for user $_loggedInUserId with role $_userRole',
        );
        if (mounted) setState(() => _drivers = []);
        return;
      }

      final driverIds = relations
          .map((r) => r['driver_custom_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (driverIds.isEmpty) {
        if (mounted) setState(() => _drivers = []);
        return;
      }

      final driverProfiles = await supabase
          .from('user_profiles')
          .select('custom_user_id, name, email, mobile_number')
          .inFilter('custom_user_id', driverIds);

      // Debug: Show what driver profiles were found
      print('Driver IDs to fetch: $driverIds');
      print(
        'Found driver profiles: ${driverProfiles.length} - $driverProfiles',
      );

      // Get all documents for these drivers
      final uploadedDocs = await supabase
          .from('driver_documents')
          .select(
            'driver_custom_id, document_type, updated_at, file_url, status, file_path, rejection_reason, submitted_at, reviewed_at, reviewed_by, uploaded_by_role, owner_custom_id, truck_owner_id, document_category',
          )
          .inFilter('driver_custom_id', driverIds);

      final driversWithStatus = driverProfiles
          .map((driver) {
            final driverId = driver['custom_user_id'];
            if (driverId == null || driverId.isEmpty) return null;

            final docsForThisDriver = uploadedDocs
                .where((doc) => doc['driver_custom_id'] == driverId)
                .toList();

            final docStatus = <String, Map<String, dynamic>>{};
            for (var type in _documentTypes.keys) {
              final doc = docsForThisDriver.firstWhere(
                (d) => d['document_type'] == type,
                orElse: () => {},
              );

              docStatus[type] = {
                'uploaded': doc.isNotEmpty,
                'status': doc['status'] ?? 'Not Uploaded',
                'uploadedAt': doc['updated_at'],
                'file_path': doc['file_path'],
                'file_url': doc['file_url'],
                'uploaded_by_role': doc['uploaded_by_role'],
                'owner_custom_id': doc['owner_custom_id'],
                'truck_owner_id': doc['truck_owner_id'],
                'document_category': doc['document_category'],
                'rejection_reason': doc['rejection_reason'],
                'submitted_at': doc['submitted_at'],
                'reviewed_at': doc['reviewed_at'],
                'reviewed_by': doc['reviewed_by'],
              };
            }

            return {
              ...driver,
              'doc_status': docStatus,
              'total_docs': docStatus.values
                  .where((doc) => doc['uploaded'])
                  .length,
              'completion_percentage':
                  (docStatus.values.where((doc) => doc['uploaded']).length /
                          _documentTypes.length *
                          100)
                      .round(),
            };
          })
          .where((driver) => driver != null)
          .cast<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() {
          _drivers = driversWithStatus;
          _applyStatusFilter();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading driver data: ${e.toString()}');
    }
  }

  void _applyStatusFilter() {
    if (_selectedStatusFilter == 'All') {
      _filteredDrivers = List.from(_drivers);
    } else {
      _filteredDrivers = _drivers.where((driver) {
        final docStatus = driver['doc_status'] as Map<String, dynamic>;
        return docStatus.values.any(
          (doc) =>
              doc['status'].toString().toLowerCase() ==
              _selectedStatusFilter.toLowerCase(),
        );
      }).toList();
    }
  }

  Future<void> _uploadDocument(String driverId, String docType) async {
    if (_loggedInUserId == null || _userRole == null) {
      _showErrorSnackBar('auth_error'.tr());
      return;
    }

    // Check upload permissions based on role and document type
    final docInfo = DocumentTypes.getDocumentInfo(docType);
    if (docInfo == null) {
      _showErrorSnackBar('Invalid document type');
      return;
    }

    final documentCategory = docInfo['category'];

    // Role-based upload permissions
    if (_userRole == UserRole.truckOwner && documentCategory != 'vehicle') {
      _showErrorSnackBar('Truck owners can only upload vehicle documents');
      return;
    }

    if (_userRole == UserRole.driver && documentCategory != 'personal') {
      _showErrorSnackBar('Drivers can only upload personal documents');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.single;
      if (platformFile.path == null) {
        _showErrorSnackBar('file_access_error'.tr());
        return;
      }

      final file = File(platformFile.path!);

      setState(() {
        _uploadingDriverId = driverId;
        _uploadingDocType = docType;
      });

      // Upload to storage
      final sanitizedDocType = docType.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final categoryFolder = documentCategory == 'vehicle'
          ? 'vehicle_docs'
          : 'personal_docs';
      final folderPath = '$driverId/$categoryFolder/$sanitizedDocType';

      // Remove existing files
      final existingFiles = await supabase.storage
          .from('driver-documents')
          .list(path: folderPath);
      if (existingFiles.isNotEmpty) {
        final filesToDelete = existingFiles
            .map((file) => '$folderPath/${file.name}')
            .toList();
        await supabase.storage.from('driver-documents').remove(filesToDelete);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = platformFile.extension ?? 'jpg';
      final filePath = '$folderPath/${timestamp}.$fileExtension';

      await supabase.storage.from('driver-documents').upload(filePath, file);
      final fileUrl = supabase.storage
          .from('driver-documents')
          .getPublicUrl(filePath);

      // Delete existing record to avoid conflicts
      await supabase
          .from('driver_documents')
          .delete()
          .eq('driver_custom_id', driverId)
          .eq('document_type', docType);

      // Insert new record with role-specific data
      final insertData = {
        'driver_custom_id': driverId,
        'document_type': docType,
        'file_path': filePath,
        'file_url': fileUrl,
        'status': 'pending',
        'document_category': documentCategory,
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Define driver-specific documents for category determination
      final driverOnlyDocuments = {
        'Drivers License',
        'Aadhaar Card',
        'PAN Card',
        'Profile Photo',
      };

      if (_userRole == UserRole.agent) {
        insertData['uploaded_by_role'] = 'agent';
        insertData['owner_custom_id'] = _loggedInUserId;
        // Agents can upload both categories - determine based on document type
        insertData['document_category'] = driverOnlyDocuments.contains(docType)
            ? 'personal'
            : 'vehicle';
      } else if (_userRole == UserRole.truckOwner) {
        insertData['uploaded_by_role'] = 'truck_owner';
        insertData['truck_owner_id'] = _loggedInUserId;
        // Truck owners can upload both categories - determine based on document type
        insertData['document_category'] = driverOnlyDocuments.contains(docType)
            ? 'personal'
            : 'vehicle';
      } else if (_userRole == UserRole.driver) {
        insertData['uploaded_by_role'] = 'driver';
        insertData['document_category'] = 'personal';
        // Note: driver_custom_id is already set to driverId above
      }

      await supabase.from('driver_documents').insert(insertData);

      _showSuccessSnackBar('✅ Document uploaded successfully!');
      await _fetchDriversWithDocStatus();
    } catch (e) {
      _showErrorSnackBar('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingDriverId = null;
          _uploadingDocType = null;
        });
      }
    }
  }

  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) {
      _showErrorSnackBar("No file URL available");
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar("Could not open document");
    }
  }

  Future<void> _approveDocument(String driverId, String docType) async {
    if (_userRole != UserRole.agent) {
      _showErrorSnackBar('Only agents can approve documents');
      return;
    }

    try {
      await supabase
          .from('driver_documents')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': _loggedInUserId,
            'rejection_reason': null,
          })
          .eq('driver_custom_id', driverId)
          .eq('document_type', docType);

      _showSuccessSnackBar('✅ Document approved!');
      await _fetchDriversWithDocStatus();
    } catch (e) {
      _showErrorSnackBar('Failed to approve document: ${e.toString()}');
    }
  }

  Future<void> _rejectDocument(
    String driverId,
    String docType,
    String reason,
  ) async {
    if (_userRole != UserRole.agent) {
      _showErrorSnackBar('Only agents can reject documents');
      return;
    }

    try {
      await supabase
          .from('driver_documents')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': _loggedInUserId,
            'rejection_reason': reason,
          })
          .eq('driver_custom_id', driverId)
          .eq('document_type', docType);

      _showSuccessSnackBar('Document rejected');
      await _fetchDriversWithDocStatus();
    } catch (e) {
      _showErrorSnackBar('Failed to reject document: ${e.toString()}');
    }
  }

  Future<void> _deleteDocument(String driverId, String docType) async {
    if (_userRole != UserRole.agent) {
      _showErrorSnackBar('Only agents can delete documents');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete this $docType document?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get the document to find the file path
      final doc = await supabase
          .from('driver_documents')
          .select('file_path')
          .eq('driver_custom_id', driverId)
          .eq('document_type', docType)
          .single();

      final filePath = doc['file_path'];

      // Delete from storage if file path exists
      if (filePath != null && filePath.isNotEmpty) {
        await supabase.storage.from('driver-documents').remove([filePath]);
      }

      // Delete from database
      await supabase
          .from('driver_documents')
          .delete()
          .eq('driver_custom_id', driverId)
          .eq('document_type', docType);

      _showSuccessSnackBar('Document deleted successfully');
      await _fetchDriversWithDocStatus();
    } catch (e) {
      _showErrorSnackBar('Failed to delete document: ${e.toString()}');
    }
  }

  void _showRejectionDialog(String driverId, String docType) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $docType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context);
                _rejectDocument(driverId, docType, reason);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleText = 'User';
    switch (_userRole) {
      case UserRole.agent:
        roleText = 'Agent';
        break;
      case UserRole.truckOwner:
        roleText = 'Truck Owner';
        break;
      case UserRole.driver:
        roleText = 'Driver';
        break;
      default:
        roleText = 'User';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_userRole != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  roleText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          DropdownButton<String>(
            value: _selectedStatusFilter,
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            underline: Container(),
            dropdownColor: AppColors.teal,
            style: const TextStyle(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatusFilter = newValue;
                  _applyStatusFilter();
                });
              }
            },
            items: _statusFilters.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDriversWithDocStatus,
              child: _filteredDrivers.isEmpty
                  ? _buildEmptyState()
                  : _buildDriversList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'noAssignedDrivers'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'addDriversToManageDocuments'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = _filteredDrivers[index];
        return _buildDriverCard(driver);
      },
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final docStatus = driver['doc_status'] as Map<String, dynamic>;
    final completionPercentage = driver['completion_percentage'] as int;
    final totalDocs = driver['total_docs'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDriverHeader(driver, completionPercentage, totalDocs),
            const Divider(height: 24),
            ..._documentTypes.keys.map((docType) {
              final docInfo = docStatus[docType] ?? {'uploaded': false};
              return _buildDocumentRow(
                driver['custom_user_id'],
                docType,
                docInfo,
                _documentTypes[docType]!,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverHeader(
    Map<String, dynamic> driver,
    int completionPercentage,
    int totalDocs,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            (driver['name'] ?? 'U')[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver['name'] ?? 'Unnamed Driver',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ID: ${driver['custom_user_id']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              if (driver['email'] != null)
                Text(
                  driver['email'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
        ),
        _buildProgressIndicator(completionPercentage, totalDocs),
      ],
    );
  }

  Widget _buildProgressIndicator(int percentage, int totalDocs) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage == 100 ? Colors.green : Colors.blue,
            ),
            strokeWidth: 5,
          ),
          Text(
            '$percentage%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
    String driverId,
    String docType,
    Map<String, dynamic> docInfo,
    Map<String, dynamic> docTypeInfo,
  ) {
    final status = docInfo['status'] ?? 'Not Uploaded';
    final uploadedByRole = docInfo['uploaded_by_role'] ?? '';
    final documentCategory = docInfo['document_category'] ?? '';
    final isVehicleDoc = documentCategory == 'vehicle';
    final isUploading =
        _uploadingDriverId == driverId && _uploadingDocType == docType;

    // Define driver-specific documents (only these can be uploaded by drivers)
    final driverOnlyDocuments = {
      'Drivers License',
      'Aadhaar Card',
      'PAN Card',
      'Profile Photo',
    };

    // Determine upload permissions
    bool canUpload = false;
    if (_userRole == UserRole.agent) {
      canUpload = true; // Agents can upload all documents
    } else if (_userRole == UserRole.truckOwner) {
      canUpload = true; // Truck owners can upload ALL documents
    } else if (_userRole == UserRole.driver) {
      // Drivers can only upload specific personal documents AND only for themselves
      canUpload =
          driverOnlyDocuments.contains(docType) && driverId == _loggedInUserId;
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = AppColors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(docTypeInfo['icon'], color: docTypeInfo['color'], size: 24),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        docType,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isVehicleDoc
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVehicleDoc ? 'Vehicle' : 'Personal',
                        style: TextStyle(
                          fontSize: 10,
                          color: isVehicleDoc ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  docTypeInfo['description'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (status != 'Not Uploaded' && docInfo['uploadedAt'] != null)
                  Text(
                    'Uploaded: ${_formatDate(docInfo['uploadedAt'])} by $uploadedByRole',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (status == 'rejected' &&
                        docInfo['rejection_reason'] != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: docInfo['rejection_reason'],
                        child: Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90, // Fixed width to prevent overflow
            child: isUploading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _buildActionButtons(
                    driverId,
                    docType,
                    docInfo,
                    canUpload,
                    isVehicleDoc,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    String driverId,
    String docType,
    Map<String, dynamic> docInfo,
    bool canUpload,
    bool isVehicleDoc,
  ) {
    final status = docInfo['status'] ?? 'Not Uploaded';
    final fileUrl = docInfo['file_url'];

    final List<Widget> actionButtons = [];

    // Upload button for not uploaded documents
    if (status == 'Not Uploaded' && canUpload) {
      actionButtons.add(
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () => _uploadDocument(driverId, docType),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              textStyle: const TextStyle(fontSize: 10),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Upload'),
          ),
        ),
      );
    }

    // View button for uploaded documents
    if (status != 'Not Uploaded' && fileUrl != null) {
      actionButtons.add(
        IconButton(
          tooltip: 'View',
          icon: Icon(
            Icons.visibility_outlined,
            color: AppColors.teal,
            size: 18,
          ),
          onPressed: () => _viewDocument(fileUrl),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      );
    }

    // Agent-only action buttons
    if (_userRole == UserRole.agent && status == 'pending') {
      actionButtons.addAll([
        IconButton(
          tooltip: 'Approve',
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 18,
          ),
          onPressed: () => _approveDocument(driverId, docType),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          tooltip: 'Reject',
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
          onPressed: () => _showRejectionDialog(driverId, docType),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]);
    }

    // Delete button for agents
    if (_userRole == UserRole.agent && status != 'Not Uploaded') {
      actionButtons.add(
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          onPressed: () => _deleteDocument(driverId, docType),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      );
    }

    // Disabled state for users who can't upload certain documents
    if (status == 'Not Uploaded' && !canUpload) {
      actionButtons.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getDisabledMessage(docType),
            style: const TextStyle(color: Colors.grey, fontSize: 9),
          ),
        ),
      );
    }
    if (actionButtons.length > 2) {
      return SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              actionButtons.take(2).toList() +
              [
                if (actionButtons.length > 2) ...[
                  const SizedBox(height: 2),
                  Wrap(spacing: 2, children: actionButtons.skip(2).toList()),
                ],
              ],
        ),
      );
    }

    return SizedBox(
      width: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: actionButtons,
      ),
    );
  }

  String _getDisabledMessage(String docType) {
    final driverOnlyDocuments = {
      'Drivers License',
      'Aadhaar Card',
      'PAN Card',
      'Profile Photo',
    };

    switch (_userRole) {
      case UserRole.truckOwner:
        return 'Can Upload All';
      case UserRole.driver:
        if (driverOnlyDocuments.contains(docType)) {
          return 'Can Upload';
        } else {
          return 'Truck Owner Only';
        }
      case UserRole.agent:
        return 'Can Upload All';
      default:
        return 'No Access';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return '';
    }
  }
}
