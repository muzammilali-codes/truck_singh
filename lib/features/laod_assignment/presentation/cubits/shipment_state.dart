import 'package:equatable/equatable.dart';
import 'package:easy_localization/easy_localization.dart';

// Using an enum for clearer status tracking
enum ShipmentStatus { initial, loading, success, failure }

class ShipmentState extends Equatable {
  const ShipmentState({
    this.status = ShipmentStatus.initial,
    this.shipments = const <Map<String, dynamic>>[],
    this.errorMessage,
  });

  final ShipmentStatus status;
  final List<Map<String, dynamic>> shipments;
  final String? errorMessage;

  // copyWith allows creating a new state object by copying the old one
  ShipmentState copyWith({
    ShipmentStatus? status,
    List<Map<String, dynamic>>? shipments,
    String? errorMessage,
  }) {
    return ShipmentState(
      status: status ?? this.status,
      shipments: shipments ?? this.shipments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, shipments, errorMessage];
}