import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logistics_toolkit/config/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ManageTrucksPage extends StatefulWidget {
  const ManageTrucksPage({super.key});

  @override
  State<ManageTrucksPage> createState() => _ManageTrucksPageState();
}

class _ManageTrucksPageState extends State<ManageTrucksPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _trucksFuture;

  @override
  void initState() {
    super.initState();
    _trucksFuture = _fetchTrucks();
  setState(() {});
  }

  void _showEditDilog(Map<String, dynamic> trucks) {
    final truckNumberController =
        TextEditingController(text: trucks['truck_number']?.toString() ?? '');
    final makeController =
        TextEditingController(text: trucks['make']?.toString() ?? '');
    final modelController =
        TextEditingController(text: trucks['model']?.toString() ?? '');
    final yearController =
        TextEditingController(text: trucks['year']?.toString() ?? '');
    final capacityTonsController =
        TextEditingController(text: trucks['capacity_tons']?.toString() ?? '');
    final fuelTypeController =
        TextEditingController(text: trucks['fuel_type']?.toString() ?? '');
    final engineNumberController =
        TextEditingController(text: trucks['engine_number']?.toString() ?? '');
    final chassisNumberController =
        TextEditingController(text: trucks['chassis_number']?.toString() ?? '');
    final vehicleTypeController =
        TextEditingController(text: trucks['vehicle_type']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title:  Text("en_route_pickup".tr()),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: truckNumberController, decoration:  InputDecoration(labelText: 'truck_number'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: engineNumberController, decoration:  InputDecoration(labelText: 'engine_number'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: chassisNumberController, decoration:  InputDecoration(labelText: 'chassis_number'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: vehicleTypeController, decoration:  InputDecoration(labelText: 'vehicle_type'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: makeController, decoration:  InputDecoration(labelText: 'make'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: modelController, decoration:  InputDecoration(labelText: 'model'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: yearController, decoration:  InputDecoration(labelText: 'year'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: capacityTonsController, decoration:  InputDecoration(labelText: 'capacity_tons'.tr())),
                  const SizedBox(height: 8),
                  TextField(controller: fuelTypeController, decoration:  InputDecoration(labelText: 'fuel_type'.tr())),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:  Text("cancel".tr()),
              ),
              ElevatedButton(
                onPressed: () async {
                  int? parsedYear = int.tryParse(yearController.text);
                  final truckId = trucks['id'];
                  if (truckId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("truck_id_not_found".tr())));
                    return;
                  }

                  await _updateTrucks(
                    truckId,
                    truckNumberController.text,
                    engineNumberController.text,
                    chassisNumberController.text,
                    modelController.text,
                    makeController.text,
                    parsedYear,
                    vehicleTypeController.text,
                    capacityTonsController.text,
                    fuelTypeController.text,
                  );

                  Navigator.pop(context);
                  _refresh();
                },
                child:  Text("save".tr()),
              ),
            ],
          );
      },
    );
  }

  Future<void> _updateTrucks(
    int truckId,
    String truckNumber,
    String engineNumber,
    String chassisNumber,
    String model,
    String make,
    int? year,
    String vehicleType,
    String capacityTons,
    String fuelType,
  ) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'update_truck_details',
        params: {
          'p_truck_id': truckId,
          'p_truck_number': truckNumber.isNotEmpty ? truckNumber : null,
          'p_engine_number': engineNumber.isNotEmpty ? engineNumber : null,
          'p_chassis_number': chassisNumber.isNotEmpty ? chassisNumber : null,
          'p_vehicle_type': vehicleType.isNotEmpty ? vehicleType : null,
          'p_make': make.isNotEmpty ? make : null,
          'p_model': model.isNotEmpty ? model : null,
          'p_year': year,
          'p_capacity_tons': capacityTons.isNotEmpty ? double.tryParse(capacityTons) : null,
          'p_fuel_type': fuelType.isNotEmpty ? fuelType : null,
        },
      );

      if (response == null || (response as List).isEmpty) {
        throw "Truck not found or no changes applied";
      }

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Truck updated successfully".tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating truck: $e")),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTrucks() async {
    final response = await Supabase.instance.client.rpc(
      'get_all_trucks_for_admin',
      params: {'search_query': _searchQuery},
    );
    return response == null ? [] : List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refresh() async {
    setState(() {
      _trucksFuture = _fetchTrucks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(title:  Text("manage_trucks".tr())),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildTruckList()),
          ],
        ),
      );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'search_truck'.tr(),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _refresh();
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        onSubmitted: (_) => _refresh(),
      ),
    );
  }

  Widget _buildTruckList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _trucksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.teal));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final trucks = snapshot.data!;
        if (trucks.isEmpty) {
          return Center(
            child: Text("no_trucks_found".tr(), style: TextStyle(color: AppColors.textColor)),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.teal,
          child: ListView.builder(
            itemCount: trucks.length,
            itemBuilder: (context, index) {
              final truck = trucks[index];
              return Card(
                //color: Colors.white,
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.directions_bus_filled_outlined, color: AppColors.teal),
                  title: Text(truck['truck_number'] ?? 'No Number', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Owner: ${truck['truck_admin'] ?? 'N/A'}\nType: ${truck['vehicle_type'] ?? 'N/A'}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    onPressed: () => _showEditDilog(truck),
                    icon: Icon(Icons.edit, color: AppColors.orange),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
