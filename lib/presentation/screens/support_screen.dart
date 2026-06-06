import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I start a new inspection?',
      'a': 'Navigate to the Inspections tab, find the inspection assigned to you, and tap "Start Inspection". You will be guided through each section of the report template.',
    },
    {
      'q': 'Can I complete an inspection without internet?',
      'a': 'Yes. EaseInspect works fully offline. Your data is saved locally and automatically synced to the server once your device reconnects to the internet.',
    },
    {
      'q': 'How do I add photos to an inspection report?',
      'a': 'Inside any inspection item, tap the camera icon to take a photo or select one from your gallery. You can add multiple photos per item.',
    },
    {
      'q': 'How do I add comments to a report item?',
      'a': 'Tap the "Add" button in the Comments section of any report item. You can type a comment, use voice-to-text, or pick from quick suggestions.',
    },
    {
      'q': 'What is the difference between Entry, Exit, and Routine inspections?',
      'a': 'Entry inspections are done when a tenant moves in, Exit when they move out, and Routine inspections are periodic checks during the tenancy.',
    },
    {
      'q': 'How do I update my profile or profile picture?',
      'a': 'Go to Settings and tap on your profile card at the top. From there you can edit your name, email, and upload a new profile photo.',
    },
    {
      'q': 'What happens if I accidentally close the app during an inspection?',
      'a': 'All progress is auto-saved as you go. Simply reopen the app and continue from where you left off.',
    },
    {
      'q': 'How do I submit a completed inspection?',
      'a': 'Once all sections are filled, tap the "Submit" button at the bottom of the inspection form. Ensure you have an active internet connection for submission.',
    },
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Help & Support',
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
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headset_mic, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need Help?',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Browse our FAQs below or contact support.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Frequently Asked Questions',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._faqs.asMap().entries.map((entry) => _buildFaq(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaq(int index, Map<String, String> faq) {
    final isOpen = _expanded.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOpen ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => isOpen ? _expanded.remove(index) : _expanded.add(index)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(faq['q']!,
                        style: TextStyle(
                            color: isOpen ? AppColors.primary : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
              if (isOpen) ...[
                const SizedBox(height: 10),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
                Text(faq['a']!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
