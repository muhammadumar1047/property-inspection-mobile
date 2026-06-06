import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Terms of Service',
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
            _section('1. Acceptance of Terms',
                'By downloading, installing, or using EaseInspect, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our application. These terms apply to all users of the app, including inspectors, agency administrators, and property managers.'),
            _section('2. Use of the Application',
                'EaseInspect is a professional property inspection management tool. You agree to use it only for lawful purposes and in accordance with these terms. You must not use the app in any way that violates applicable local, national, or international laws or regulations.\n\nYou are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.'),
            _section('3. User Accounts',
                'To use EaseInspect, you must create an account through your agency. You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate. We reserve the right to suspend or terminate accounts that contain false or misleading information.'),
            _section('4. Inspection Data and Reports',
                'All inspection reports, photos, and data entered into EaseInspect remain the property of your agency. By submitting data through the app, you grant EaseInspect a limited licence to store, process, and transmit this data solely for the purpose of providing our services.\n\nYou are responsible for ensuring that inspection data is accurate and that appropriate consents have been obtained for any photographs taken on private property.'),
            _section('5. Intellectual Property',
                'The EaseInspect application, including its design, features, and content, is owned by EaseInspect Pty Ltd and is protected by copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works based on our app without our explicit written permission.'),
            _section('6. Limitation of Liability',
                'To the maximum extent permitted by applicable law, EaseInspect shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the app. This includes but is not limited to loss of data, loss of profits, or business interruption.\n\nOur total liability to you for any claims arising from these terms or your use of the app shall not exceed the amount you paid us in the twelve months preceding the claim.'),
            _section('7. Availability and Updates',
                'We strive to keep EaseInspect available at all times, but we do not guarantee uninterrupted access. We reserve the right to modify, suspend, or discontinue the app at any time with or without notice. We may also update the app and these terms from time to time.'),
            _section('8. Termination',
                'We may terminate or suspend your access to EaseInspect immediately, without prior notice or liability, for any reason, including if you breach these terms. Upon termination, your right to use the app will immediately cease. Provisions of these terms that by their nature should survive termination shall continue to apply.'),
            _section('9. Governing Law',
                'These terms shall be governed by and construed in accordance with the laws of New South Wales, Australia. Any disputes arising from these terms or your use of EaseInspect shall be subject to the exclusive jurisdiction of the courts of New South Wales.'),
            _section('10. Contact Us',
                'If you have any questions about these Terms of Service, please contact us at:\n\nEmail: legal@easeinspect.com\nAddress: 123 Inspection Street, Sydney NSW 2000, Australia'),
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
