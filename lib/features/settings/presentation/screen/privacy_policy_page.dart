import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // Helper for main headings (e.g., "1. Introduction")
  Widget _buildHeading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper for sub-headings (e.g., "A. Information You Provide")
  Widget _buildSubHeading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper for body text (automatically adapts to light/dark mode)
  Widget _buildBodyText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeading(context, 'Privacy Policy for TRUCK SINGH'),


          _buildHeading(context, '1. Introduction'),
          _buildBodyText(context,
              'Welcome to TRUCK SINGH. We provide a logistics platform that connects Shippers, Agents, Drivers, and Truck Owners (collectively, "Users") to facilitate the booking, tracking, and management of freight shipments.'),
          _buildBodyText(context,
              'This Privacy Policy explains what personal information we collect from our Users, how we use and share that information, and your rights in connection with our services.'),
          _buildBodyText(context,
              'By creating an account or using our Services, you agree to the collection, use, and sharing of your information as described in this policy.'),

          _buildHeading(context, '2. Information We Collect'),
          _buildBodyText(context,
              'We collect information to provide and improve our Services. The type of information we collect depends on your role as a User.'),

          _buildSubHeading(context, 'A. Information You Provide Directly (All Users)'),
          _buildBodyText(context,
              'Account Information: When you register, you provide your name, email address, phone number, a password, and your designated role (e.g., Shipper, Driver).\n\n'
                  'Profile Information: You may add further details to your profile, such as a profile picture or company name.\n\n'
                  'Communications: We collect information when you contact us for support, report an issue, or otherwise communicate with us.'),

          _buildSubHeading(context, 'B. Information Collected Based on Your Role'),
          _buildBodyText(context,
              'We collect specific information necessary for each role to use the Services:'),
          _buildBodyText(context,
              'If you are a Shipper:\n\n'
                  'Company Details: Your company name, business address, and GSTIN (or other tax identification numbers).\n\n'
                  'Shipment Details: Information about your shipments, including pickup and drop-off locations, recipient names and phone numbers, and descriptions of the goods being transported.'),
          _buildBodyText(context,
              'If you are an Agent:\n\n'
                  'Agency/Company Details: Your company name, business address, and GSTIN.\n\n'
                  'Financial Information: Bank account details for processing payments and commissions.\n\n'
                  'Client Information: You may enter information on behalf of Shippers, which includes their shipment and company details as listed above.'),
          _buildBodyText(context,
              'If you are a Truck Owner:\n\n'
                  'Business Details: Your company or business name, address, and GSTIN.\n\n'
                  'Financial Information: Bank account details for receiving payments.\n\n'
                  'Vehicle Information: Detailed information about your trucks, including truck registration numbers, vehicle type, insurance documents, permits, and vehicle-specific details like engine and chassis numbers.'),
          _buildBodyText(context,
              'If you are a Driver:\n\n'
                  'Identity Verification: Your driver\'s license number and/or photo, and potentially other government-issued ID to verify your identity and eligibility to drive.\n\n'
                  'Vehicle Information: The truck number and type you are associated with (if not the Truck Owner).'),

          _buildSubHeading(context, 'C. Information We Collect Automatically'),
          _buildBodyText(context,
              'Precise Location Data (Drivers): This is essential for our Service. We collect your precise geolocation from your mobile device only when you are on an active, assigned shipment. This tracking occurs even when the app is in the background. This data is used to:\n\n'
                  'Show Shippers and Agents the live location of their shipment.\n\n'
                  'Calculate ETAs (Estimated Times of Arrival).\n\n'
                  'Verify shipment milestones (e.g., "Arrived at Pickup").\n\n'
                  '(If you have an SOS feature) Share your location with your company or emergency services.\n\n'
                  'Usage Information: We log activity on our Services, including features you use, pages you view, and dates/times of your sessions.\n\n'
                  'Device Information: We collect data about your mobile device, such as the hardware model, operating system, and unique device identifiers.\n\n'
                  'Cookies and Similar Technologies: We may use cookies to store user preferences and session information.'),

          _buildHeading(context, '3. How We Use Your Information'),
          _buildBodyText(context,
              'We use your information for the following purposes:\n\n'
                  'To Provide and Manage the Services: To create your account, connect Shippers with Drivers/Truck Owners, generate Bilty/shipping documents, process payments, and track active shipments.\n\n'
                  'To Ensure Safety and Security: To verify driver identities, prevent fraud, and (if applicable) operate safety features like an SOS button.\n\n'
                  'To Communicate with You: To send you service-related notifications (e.g., "New Shipment Assigned"), invoices, and support messages.\n\n'
                  'For Customer Support: To investigate and resolve your issues or inquiries.\n\n'
                  'To Comply with Legal Obligations: To meet legal and regulatory requirements, such as tax laws (which require GSTIN and bank details) and transportation regulations.\n\n'
                  'To Improve Our Services: To analyze how our Users interact with the app so we can improve its functionality and user experience.'),

          _buildHeading(context, '4. How We Share Your Information'),
          _buildBodyText(context,
              'Your information is shared only as necessary to provide the Services.\n\n'
                  'Between Users (To Fulfill a Shipment):\n\n'
                  'Shippers and Agents will see: The assigned Driver\'s name, truck number, and the live location of the driver during the active shipment.\n\n'
                  'Drivers and Truck Owners will see: The Shipper/Recipient name, company, phone number, and the pickup/drop-off addresses for the shipment.\n\n'
                  'Payment Processors: To securely handle payments.\n\n'
                  'For Legal Reasons: We may share information with law enforcement or government authorities if required by law, in response to a court order, or to protect the rights, property, or safety of our Users or the public.\n\n'
                  'Business Transfers: If we are involved in a merger, acquisition, or sale of assets, your information may be transferred as part of that transaction.\n\n'
                  'We do not sell your personal information to third parties.'),

          _buildHeading(context, '5. Data Security'),
          _buildBodyText(context,
              'We implement reasonable technical and administrative security measures to protect your information from loss, theft, misuse, and unauthorized access. This includes encryption and access controls. However, no system is 100% secure, and we cannot guarantee the absolute security of your information.'),

          _buildHeading(context, '6. Data Retention'),
          _buildBodyText(context,
              'We retain your personal information for as long as you have an active account with us.\n\n'
                  'After you close your account, we may retain your information for a longer period as necessary to:\n\n'
                  'Comply with legal obligations (e.g., tax and financial records).\n\n'
                  'Resolve disputes or enforce our agreements.\n\n'
                  'Maintain fraud and abuse prevention records.'),

          _buildHeading(context, '7. Your Rights and Choices'),
          _buildBodyText(context,
              'You have choices regarding your personal information:\n\n'
                  'Account Information: You can access and update your profile information (name, phone, bank details, etc.) at any time through the "Settings" or "Profile" section of the app.\n\n'
                  'Location Data (Drivers): You can disable the app\'s access to your location through your device\'s settings. However, doing so will prevent you from being assigned or completing shipments, as live tracking is a core part of the Service.\n\n'
                  'Account Deletion: You can request to delete your account by contacting us. We may be unable to delete your account if you have an active shipment or if we are required to retain your information for legal reasons (as noted in Section 6).\n\n'
                  'Disabling Account: You may have an option to "Disable" your account in the app settings. This will temporarily deactivate your account, but your data will not be deleted.'),

          _buildHeading(context, '8. Children\'s Privacy'),
          _buildBodyText(context,
              'Our Services are not intended for or directed at individuals under the age of 18. We do not knowingly collect personal information from children.'),

          _buildHeading(context, '9. Changes to This Privacy Policy'),
          _buildBodyText(context,
              'We may update this Privacy Policy from time to time. If we make significant changes, we will notify you through the app or by email. Your continued use of the Services after a change becomes effective constitutes your acceptance of the new policy.'),

          _buildHeading(context, '10. Contact Us'),
          _buildBodyText(context,
              'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:\n\n'
                  'Company Name: TRUCK SINGH\n'
                  'Email: trucksingh.com@gmail.com'
          ),
        ],
      ),
    );
  }
}