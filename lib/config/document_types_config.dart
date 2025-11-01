import 'package:flutter/material.dart';

class DocumentTypes {
  // Driver documents (uploaded by driver)
  static final Map<String, Map<String, dynamic>> driverDocuments = {
    'Drivers License': {
      'icon': Icons.drive_eta,
      'description': 'Valid driving license',
      'color': Colors.orange,
      'isRequired': true,
      'category': 'personal',
      'uploadedBy': 'driver',
    },
    'Aadhaar Card': {
      'icon': Icons.credit_card,
      'description': 'Government identity card',
      'color': Colors.indigo,
      'isRequired': true,
      'category': 'personal',
      'uploadedBy': 'driver',
    },
    'PAN Card': {
      'icon': Icons.account_balance_wallet,
      'description': 'PAN card for tax identification',
      'color': Colors.purple,
      'isRequired': true,
      'category': 'personal',
      'uploadedBy': 'driver',
    },
    'Profile Photo': {
      'icon': Icons.person,
      'description': 'Driver profile photograph',
      'color': Colors.teal,
      'isRequired': false,
      'category': 'personal',
      'uploadedBy': 'driver',
    },
  };

  // Vehicle documents (uploaded by truck owner)
  static final Map<String, Map<String, dynamic>> vehicleDocuments = {
    'Vehicle Registration': {
      'icon': Icons.directions_car,
      'description': 'Vehicle registration certificate',
      'color': Colors.blue,
      'isRequired': true,
      'category': 'vehicle',
      'uploadedBy': 'truck_owner',
    },
    'Vehicle Insurance': {
      'icon': Icons.security,
      'description': 'Vehicle insurance certificate',
      'color': Colors.green,
      'isRequired': true,
      'category': 'vehicle',
      'uploadedBy': 'truck_owner',
    },
    'Vehicle Permit': {
      'icon': Icons.local_shipping,
      'description': 'Commercial vehicle permit',
      'color': Colors.deepOrange,
      'isRequired': true,
      'category': 'vehicle',
      'uploadedBy': 'truck_owner',
    },
    'Pollution Certificate': {
      'icon': Icons.eco,
      'description': 'Pollution under control certificate',
      'color': Colors.lightGreen,
      'isRequired': true,
      'category': 'vehicle',
      'uploadedBy': 'truck_owner',
    },
    'Fitness Certificate': {
      'icon': Icons.verified,
      'description': 'Vehicle fitness certificate',
      'color': Colors.cyan,
      'isRequired': true,
      'category': 'vehicle',
      'uploadedBy': 'truck_owner',
    },
  };

  // Combined documents map
  static final Map<String, Map<String, dynamic>> allDocuments = {
    ...driverDocuments,
    ...vehicleDocuments,
  };

  // Get documents by role
  static Map<String, Map<String, dynamic>> getDocumentsByRole(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return driverDocuments;
      case 'truck_owner':
        return vehicleDocuments;
      default:
        return allDocuments;
    }
  }

  // Get documents by category
  static Map<String, Map<String, dynamic>> getDocumentsByCategory(
    String category,
  ) {
    return Map.fromEntries(
      allDocuments.entries.where(
        (entry) => entry.value['category'] == category,
      ),
    );
  }

  // Get list of required document types by role
  static List<String> getRequiredTypesByRole(String role) {
    return getDocumentsByRole(role).entries
        .where((entry) => entry.value['isRequired'] == true)
        .map((entry) => entry.key)
        .toList();
  }

  // Get list of all document types by role
  static List<String> getAllTypesByRole(String role) {
    return getDocumentsByRole(role).keys.toList();
  }

  // Get document info by type
  static Map<String, dynamic>? getDocumentInfo(String type) {
    return allDocuments[type];
  }

  // Check if user can upload this document type
  static bool canUploadDocument(String documentType, String userRole) {
    final docInfo = getDocumentInfo(documentType);
    if (docInfo == null) return false;
    return docInfo['uploadedBy'] == userRole;
  }

  // Legacy support - maintain compatibility with existing code
  static final Map<String, Map<String, dynamic>> requiredDocuments =
      allDocuments;

  static List<String> get requiredTypes {
    return allDocuments.entries
        .where((entry) => entry.value['isRequired'] == true)
        .map((entry) => entry.key)
        .toList();
  }

  static List<String> get allTypes {
    return allDocuments.keys.toList();
  }
}
