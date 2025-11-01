class BiltyModel {
  final String? id;
  final String biltyNo;
  final String consignorName;
  final String consigneeName;
  final String origin;
  final String destination;
  final double totalFare;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  BiltyModel({
    this.id,
    required this.biltyNo,
    required this.consignorName,
    required this.consigneeName,
    required this.origin,
    required this.destination,
    required this.totalFare,
    this.userId,
    this.createdAt,
    this.updatedAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bilty_no': biltyNo,
      'consignor_name': consignorName,
      'consignee_name': consigneeName,
      'origin': origin,
      'destination': destination,
      'total_fare': totalFare,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory BiltyModel.fromJson(Map<String, dynamic> json) {
    return BiltyModel(
      id: json['id'],
      biltyNo: json['bilty_no'] ?? '',
      consignorName: json['consignor_name'] ?? '',
      consigneeName: json['consignee_name'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      totalFare: (json['total_fare'] ?? 0).toDouble(),
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      metadata: json['metadata'] ?? {},
    );
  }
}

// Model for consignor/consignee details
class PartyDetails {
  final String name;
  final String address;
  final String? gstin;
  final String? phone;
  final String? email;

  PartyDetails({
    required this.name,
    required this.address,
    this.gstin,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'gstin': gstin,
      'phone': phone,
      'email': email,
    };
  }

  factory PartyDetails.fromJson(Map<String, dynamic> json) {
    return PartyDetails(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      gstin: json['gstin'],
      phone: json['phone'],
      email: json['email'],
    );
  }
}

// Model for goods/item details
class GoodsItem {
  final String description;
  final int quantity;
  final double weight;
  final double rate;
  final double amount;

  GoodsItem({
    required this.description,
    required this.quantity,
    required this.weight,
    required this.rate,
    required this.amount,
  });

  GoodsItem copyWith({
    String? description,
    int? quantity,
    double? weight,
    double? rate,
    double? amount,
  }) {
    return GoodsItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'weight': weight,
      'rate': rate,
      'amount': amount,
    };
  }

  factory GoodsItem.fromJson(Map<String, dynamic> json) {
    return GoodsItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

// Model for vehicle and driver details
class VehicleDetails {
  final String vehicleNumber;
  final String driverName;
  final String? driverPhone;
  final String? driverLicense;

  VehicleDetails({
    required this.vehicleNumber,
    required this.driverName,
    this.driverPhone,
    this.driverLicense,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_license': driverLicense,
    };
  }

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      vehicleNumber: json['vehicle_number'] ?? '',
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'],
      driverLicense: json['driver_license'],
    );
  }
}

// Model for charges and payment details
class ChargesDetails {
  final double basicFare;
  final double otherCharges;
  final double gst;
  final double totalAmount;
  final String paymentStatus; // "Paid", "To Pay", "Partial"

  ChargesDetails({
    required this.basicFare,
    required this.otherCharges,
    required this.gst,
    required this.totalAmount,
    required this.paymentStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'basic_fare': basicFare,
      'other_charges': otherCharges,
      'gst': gst,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
    };
  }

  factory ChargesDetails.fromJson(Map<String, dynamic> json) {
    return ChargesDetails(
      basicFare: (json['basic_fare'] ?? 0).toDouble(),
      otherCharges: (json['other_charges'] ?? 0).toDouble(),
      gst: (json['gst'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'To Pay',
    );
  }
} 