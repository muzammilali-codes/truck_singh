import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: theme.primaryColor,
        elevation: 1,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Page Heading
                Text(
                  'Terms & Conditions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                _sectionTitle(theme, '1. Introduction'),
                _sectionBody(
                  theme,
                  'Welcome to Truck Singh, a unified logistics platform connecting Shippers, '
                      'Agents, Truck Owners and Drivers. By accessing or using this App, you agree '
                      'to these Terms. If you disagree, please stop using the App.',
                ),
                _divider(),

                _sectionTitle(theme, '2. User Eligibility & Account Responsibility'),
                _sectionBody(
                  theme,
                  'You must provide accurate information and maintain account confidentiality. '
                      'Fraud, fake identity, unauthorized activity, or illegal conduct will result in '
                      'account suspension/termination and possible legal action.',
                ),
                _divider(),

                _sectionTitle(theme, '3. Role-Specific Terms'),

                /// ✅ DRIVER
                _sectionTitle(theme, '3.1 Driver'),
                _sectionBody(
                  theme,
                  'As a Driver:\n'
                      '- You confirm you hold required licences, registration and insurance\n'
                      '- Follow safe driving standards & transport laws\n'
                      '- Maintain vehicle fitness & route compliance\n'
                      '- Accept assignments responsibly\n'
                      '- Do not solicit payment outside the App\n'
                      '- Do not tamper with tracking or avoid jobs without reason\n\n'
                      'The Platform is not liable for loss, damage or delay caused by your conduct, '
                      'vehicle condition or handling of goods.',
                ),

                /// ✅ AGENT
                _sectionTitle(theme, '3.2 Agent'),
                _sectionBody(
                  theme,
                  'As an Agent:\n'
                      '- Coordinate Shippers, Truck Owners & Drivers\n'
                      '- Create shipments, allocate vehicles & monitor trips\n'
                      '- Ensure documents, vehicle & driver validity\n'
                      '- Do not misrepresent load capacity, route, cost or documents\n'
                      '- Do not bypass app workflow for external deals\n\n'
                      'The Platform is not responsible for disputes or deals done outside the App.',
                ),

                /// ✅ TRUCK OWNER
                _sectionTitle(theme, '3.3 Truck Owner'),
                _sectionBody(
                  theme,
                  'As a Truck Owner:\n'
                      '- Provide legally compliant vehicles & eligible drivers\n'
                      '- Keep fleet details updated\n'
                      '- Do not accept jobs you cannot fulfil\n'
                      '- Manage routing, tracking, loading/unloading\n\n'
                      'The Platform is not liable for damage, delay, breakdowns or regulatory issues.',
                ),

                /// ✅ SHIPPER
                _sectionTitle(theme, '3.4 Shipper'),
                _sectionBody(
                  theme,
                  'As a Shipper:\n'
                      '- Provide correct shipment details (goods, weight, pickup, delivery)\n'
                      '- Maintain valid identity & business details\n'
                      '- Do not bypass platform workflow to avoid fees\n'
                      '- Pay quoted price, fees & taxes\n'
                      '- Update shipment details if changed\n\n'
                      'The Platform only facilitates connections and is not liable for damages, '
                      'loss, or delays. Claims must be pursued with the assigned Agent/Truck Owner/Driver.',
                ),

                _divider(),

                _sectionTitle(theme, '4. Prohibited Activities'),
                _sectionBody(
                  theme,
                  'You must not:\n'
                      '- Submit false documents or load/vehicle info\n'
                      '- Circumvent platform or fees\n'
                      '- Harass or abuse other users\n'
                      '- Hack, manipulate or misuse app systems',
                ),
                _divider(),

                _sectionTitle(theme, '5. Payment & Transactions'),
                _sectionBody(
                  theme,
                  'Payments are between users. Truck Singh is not responsible for disputes or '
                      'losses due to incorrect banking details, delays or offline agreements.',
                ),
                _divider(),

                _sectionTitle(theme, '6. Location & Tracking Permission'),
                _sectionBody(
                  theme,
                  'The app uses GPS for assignment matching, live tracking and safety. '
                      'By using the app, you consent to location access.',
                ),
                _divider(),

                _sectionTitle(theme, '7. Data Usage'),
                _sectionBody(
                  theme,
                  'We collect and use data to improve service and safety. '
                      'Please review our Privacy Policy for details.',
                ),
                _divider(),

                _sectionTitle(theme, '8. Termination'),
                _sectionBody(
                  theme,
                  'Accounts violating policies or laws may be suspended or permanently terminated.',
                ),
                _divider(),

                _sectionTitle(theme, '9. Limitation of Liability'),
                _sectionBody(
                  theme,
                  'Truck Singh is a technology platform only. We are not responsible for:\n'
                      '- Shipment loss/damage\n'
                      '- Driver or owner behavior\n'
                      '- Payment disputes\n'
                      '- Delays or operational issues',
                ),
                _divider(),

                _sectionTitle(theme, '10. Policy Updates'),
                _sectionBody(
                  theme,
                  'Terms may be updated. Continued use means acceptance.',
                ),

                const SizedBox(height: 20),
                Text(
                  'Last Updated: November 2025',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _sectionBody(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }

  Widget _divider() =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Divider(thickness: 0.7, height: 24, color: Colors.black12),
      );
}