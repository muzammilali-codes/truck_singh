import 'package:flutter/material.dart';

class notificationDetails_page extends StatelessWidget {
  const notificationDetails_page({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double width = size.width;

    // Breakpoints
    final bool isTablet = width > 600 && width <= 1000;
    final bool isDesktop = width > 1000;

    // Font sizes
    final double titleSize = isDesktop
        ? 32
        : isTablet
        ? 28
        : 26;

    final double bodyFontSize = isDesktop
        ? 16
        : isTablet
        ? 15
        : 14.5;

    const double maxContentWidth = 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notification Details",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? 48
                    : isTablet
                    ? 32
                    : 16,
                vertical: isDesktop
                    ? 40
                    : isTablet
                    ? 28
                    : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Shipment Section
                  _buildCard(
                    title: "Shipment Notifications",
                    description:
                    "Stay updated on your shipment progress in real-time. "
                        "You will receive alerts when a shipment is created, picked up, loading, dispatched, dropped, unloading, delayed, or successfully delivered. "
                        "These notifications help you monitor logistics and ensure timely operations.",
                    context: context,
                    fontSize: bodyFontSize,
                  ),

                  // Driver SOS Alerts
                  _buildCard(
                    title: "Driver SOS Alerts",
                    description:
                    "This section handles emergency alerts from drivers. "
                        "When a driver presses the SOS button, agents and nearby response teams are instantly notified. "
                        "You can track driver safety and take quick action during critical situations.",
                    context: context,
                    fontSize: bodyFontSize,
                  ),

                  // Admin Account Enable / Disable
                  _buildCard(
                    title: "Admin Account Enable / Disable",
                    description:
                    "Admins can manage user accounts directly from the Admin panel. "
                        "Receive alerts when any account is enabled, suspended, or reactivated. "
                        "This ensures better control and security over platform access.",
                    context: context,
                    fontSize: bodyFontSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable Card Widget
  Widget _buildCard({
    required String title,
    required String description,
    required BuildContext context,
    required double fontSize,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}