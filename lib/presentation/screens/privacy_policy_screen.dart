import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Privacy Policy',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last updated: January 1, 2025',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(height: 20),
            _section('1. Information We Collect',
                'We collect information you provide directly to us, such as your name, email address, and profile photo when you create an account. We also collect inspection data, photos, and comments you enter while using the app.\n\nWe may automatically collect certain information about your device, including your IP address, operating system, and app usage data to improve our services.'),
            _section('2. How We Use Your Information',
                'We use the information we collect to provide, maintain, and improve our services. This includes processing and storing inspection reports, syncing data across devices, sending notifications relevant to your inspections, and providing customer support.\n\nWe do not sell, trade, or rent your personal information to third parties.'),
            _section('3. Data Storage and Security',
                'Your data is stored securely on our servers using industry-standard encryption. Inspection data may also be stored locally on your device for offline access. We implement appropriate technical and organisational measures to protect your personal information against unauthorised access, alteration, disclosure, or destruction.'),
            _section('4. Photos and Media',
                'Photos taken or uploaded during inspections are stored securely in our cloud storage. These photos are accessible only to authorised users within your agency. We do not use inspection photos for any purpose other than generating reports.'),
            _section('5. Data Sharing',
                'We may share your information with your agency administrators and property managers as part of the inspection workflow. We may also share data with trusted third-party service providers who assist us in operating the app, subject to confidentiality agreements.'),
            _section('6. Your Rights',
                'You have the right to access, correct, or delete your personal information at any time. You may also request a copy of the data we hold about you. To exercise these rights, please contact us through the Help & Support section.'),
            _section('7. Cookies and Tracking',
                'Our app may use cookies and similar tracking technologies to enhance your experience. You can control cookie settings through your device preferences. Disabling cookies may affect certain features of the app.'),
            _section('8. Children\'s Privacy',
                'EaseInspect is not intended for use by individuals under the age of 18. We do not knowingly collect personal information from children. If we become aware that a child has provided us with personal information, we will take steps to delete such information.'),
            _section('9. Changes to This Policy',
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last updated" date at the top of this page. Your continued use of the app after any changes constitutes your acceptance of the new policy.'),
            _section('10. Contact Us',
                'If you have any questions about this Privacy Policy or our data practices, please contact us at:\n\nEmail: privacy@easeinspect.com\nAddress: 123 Inspection Street, Sydney NSW 2000, Australia'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}
