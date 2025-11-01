import 'package:flutter/material.dart';


enum UserRole {
  driver,
  truckOwner,
  shipper,
  agent,
  Admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.agent:
        return 'Agent';
      case UserRole.driver:
        return 'Driver';
      case UserRole.truckOwner:
        return 'Truck Owner';
      case UserRole.shipper:
        return 'Shipper';
      case UserRole.Admin:
        return 'Admin';
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.agent:
        return 'agent';
      case UserRole.driver:
        return 'driver';
      case UserRole.truckOwner:
        return 'truckowner';
      case UserRole.shipper:
        return 'shipper';
      case UserRole.Admin:
        return 'Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.agent:
        return Icons.support_agent;
      case UserRole.driver:
        return Icons.groups;
      case UserRole.truckOwner:
        return Icons.local_shipping;
      case UserRole.shipper:
        return Icons.shopping_cart;
      case UserRole.Admin:
        return Icons.add_moderator_outlined;
    }
  }

  static UserRole? fromDbValue(String? value) {
    switch (value) {
      case 'agent':
        return UserRole.agent;
      case 'driver':
        return UserRole.driver;
      case 'truckowner':
        return UserRole.truckOwner;
      case 'shipper':
        return UserRole.shipper;
      case 'Admin':
        return UserRole.Admin;
      default:
        return null;
    }
  }

  String get prefix {
    switch (this) {
      case UserRole.agent:
        return 'AGNT';
      case UserRole.driver:
        return 'DRV';
      case UserRole.truckOwner:
        return 'TRUK';
      case UserRole.shipper:
        return 'SHIP';
      case UserRole.Admin:
        return 'ADM';
    }
  }
}