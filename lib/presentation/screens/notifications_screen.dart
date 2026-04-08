import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotificationItem(
            'New Inspection Assigned',
            'Assigned: 24 Western Avenue Wall (Routine)',
            '2 hours ago',
            AppColors.error,
            true,
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            'Inspection Submitted',
            'Smith St (Entry)',
            '5 hours ago',
            AppColors.success,
            false,
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            'Inspection Submitted',
            '33 Smith St (Entry)',
            '1 day ago',
            AppColors.success,
            false,
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            'Reminder: Inspection due today at 3PM',
            '2 hours ago',
            '2 hours ago',
            AppColors.warning,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, String time, Color indicatorColor, bool hasRedDot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForNotification(title),
                  color: indicatorColor,
                  size: 20,
                ),
              ),
              if (hasRedDot)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForNotification(String title) {
    if (title.contains('Assigned')) return Icons.assignment;
    if (title.contains('Submitted')) return Icons.check_circle;
    if (title.contains('Reminder')) return Icons.schedule;
    return Icons.notifications;
  }


}