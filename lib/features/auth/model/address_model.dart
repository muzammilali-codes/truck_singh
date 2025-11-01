import 'package:easy_localization/easy_localization.dart';

class BillingAddress {
  String flatNo, streetName, cityName, district, zipCode;

  BillingAddress({
    required this.flatNo,
    required this.streetName,
    required this.cityName,
    required this.district,
    required this.zipCode,
  });

  /// Generates a map with localized keys for display purposes.
  /// Note: This is not recommended for sending data to a server/API.
  Map<String, dynamic> toLocalizedJson() => {
    'flatNo'.tr(): flatNo,
    'streetName'.tr(): streetName,
    'cityName'.tr(): cityName,
    'district'.tr(): district,
    'zipCode'.tr(): zipCode,
  };
  
  /// Generates a map with fixed keys for server communication.
  Map<String, dynamic> toJson() => {
    'flatNo': flatNo,
    'streetName': streetName,
    'cityName': cityName,
    'district': district,
    'zipCode': zipCode,
  };

  factory BillingAddress.fromJson(Map<String, dynamic> json) => BillingAddress(
    flatNo: json['flatNo'] ?? '',
    streetName: json['streetName'] ?? '',
    cityName: json['cityName'] ?? '',
    district: json['district'] ?? '',
    zipCode: json['zipCode'] ?? '',
  );
}

class CompanyAddress {
  String flatNo, streetName, cityName, district, zipCode;

  CompanyAddress({
    required this.flatNo,
    required this.streetName,
    required this.cityName,
    required this.district,
    required this.zipCode,
  });

  /// Generates a map with localized keys for display purposes.
  /// Note: This is not recommended for sending data to a server/API.
  Map<String, dynamic> toLocalizedJson() => {
    'flatNo'.tr(): flatNo,
    'streetName'.tr(): streetName,
    'cityName'.tr(): cityName,
    'district'.tr(): district,
    'zipCode'.tr(): zipCode,
  };

  /// Generates a map with fixed keys for server communication.
  Map<String, dynamic> toJson() => {
    'flatNo': flatNo,
    'streetName': streetName,
    'cityName': cityName,
    'district': district,
    'zipCode': zipCode,
  };

  factory CompanyAddress.fromJson(Map<String, dynamic> json) => CompanyAddress(
    flatNo: json['flatNo'] ?? '',
    streetName: json['streetName'] ?? '',
    cityName: json['cityName'] ?? '',
    district: json['district'] ?? '',
    zipCode: json['zipCode'] ?? '',
  );
}