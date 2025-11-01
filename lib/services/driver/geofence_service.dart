import 'package:geolocator/geolocator.dart';
import '../shipment_manager.dart';

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}

class GeofenceService {
  static const double EN_ROUTE_RADIUS = 5000;
  static const double ARRIVED_RADIUS = 500;

  static Future<String?> checkGeofences(
    Position currentPosition,
    Map<String, dynamic> shipment,
  ) async {
    final pickupLat = shipment['pickup_lat'] as double?;
    final pickupLng = shipment['pickup_lng'] as double?;
    final dropLat = shipment['drop_lat'] as double?;
    final dropLng = shipment['drop_lng'] as double?;

    if (pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      print(
        "❌ Geofence check failed: Shipment ${shipment['shipment_id']} has incomplete location data.",
      );
      return null;
    }

    final shipmentId = shipment['shipment_id'];
    String currentStatus = shipment['booking_status'];

    final distanceToPickup = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      pickupLat,
      pickupLng,
    );

    final distanceToDropoff = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      dropLat,
      dropLng,
    );

    String? newStatus;

    // Use a switch statement for clarity
    switch (currentStatus) {
      case 'Accepted':
        if (distanceToPickup < EN_ROUTE_RADIUS) {
          newStatus = 'En Route to Pickup';
        }
        break;

      case 'En Route to Pickup':
        if (distanceToPickup < ARRIVED_RADIUS) {
          newStatus = 'Arrived at Pickup';
        }
        break;

      case 'Arrived at Pickup':
        if (distanceToPickup > ARRIVED_RADIUS) {
          newStatus = 'In Transit';
        }
        break;

      case 'In Transit':
        if (distanceToDropoff < ARRIVED_RADIUS) {
          newStatus = 'Arrived at Drop';
        }
        break;

      default:
        break;
    }
    if (newStatus != null) {
      await ShipmentManager.updateShipmentStatus(shipmentId, newStatus);
      return newStatus;
    }
    return null;
  }
}
