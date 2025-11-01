import 'package:flutter/material.dart';
import 'package:logistics_toolkit/dashboard/admin_dashboard.dart';
import '../../../../dashboard/agent_db_screen.dart';
import '../../../../dashboard/company_driver_db_screen.dart';
import '../../../../dashboard/owner_db.dart';
import '../../../../dashboard/shipper_db_screen.dart';
import '../../utils/user_role.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../dashboard/shipper_db_screen.dart';
import '../../../../dashboard/agent_db_screen.dart';


class DashboardRouter extends StatelessWidget {
  final UserRole role;

  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.driver:
        return const CompanyDriverDb();
      case UserRole.truckOwner:
        return const TruckOwnerDashboard();
      case UserRole.shipper:
        return const ShipperDashboard();
      case UserRole.agent:
        return const AgentDashboard();
      case UserRole.Admin:
        return const AdminDashboard();
    }
  }
}

class BlankPage extends StatelessWidget {
  final String title;
  const BlankPage({super.key, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'dashboard'.tr() : title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('welcome_dashboard'.tr(), style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}