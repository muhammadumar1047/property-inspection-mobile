import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadInspections,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBg,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildHeroText(),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildWeeklyChart(),
                const SizedBox(height: 20),
                _buildActionGrid(),
                const SizedBox(height: 24),
                _buildRecentActivityFeed(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Inspect ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              WidgetSpan(child: _ProBadge()),
            ],
          ),
        ),
        Row(
          children: [
            Obx(() => controller.isOffline.value
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: AppColors.warning, size: 12),
                        SizedBox(width: 4),
                        Text('Offline',
                            style: TextStyle(
                                color: AppColors.warning, fontSize: 11)),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),

          ],
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Property',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          'Inspections Made\nSimple',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
                child: _buildStat(
                    controller.totalProperties.toString(), 'Total\nProperties')),
            Expanded(
                child: _buildStat(
                    controller.pendingCount.toString(), 'Pending\nInspections',
                    color: AppColors.warning)),
            Expanded(
                child: _buildStat(controller.completedCount.toString(),
                    'Completed\nInspections',
                    color: AppColors.primary)),
          ],
        ),
      );
    });
  }

  Widget _buildStat(String value, String label, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Obx(() {
      final data = controller.weeklyData;
      final maxVal = data.fold<int>(
          1,
          (prev, e) => ((e['pending'] as int) + (e['completed'] as int)) > prev
              ? (e['pending'] as int) + (e['completed'] as int)
              : prev);
      final todayIndex = DateTime.now().weekday - 1;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('This Week',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(
                  'Total: ${data.fold(0, (s, e) => s + (e['pending'] as int) + (e['completed'] as int))}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendDot(AppColors.warning, 'Pending'),
                const SizedBox(width: 12),
                _buildLegendDot(AppColors.primary, 'Completed'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final pending = data[i]['pending'] as int;
                  final completed = data[i]['completed'] as int;
                  final label = data[i]['label'] as String;
                  final total = pending + completed;
                  final isToday = label != '-' && (() {
                    final now = DateTime.now();
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return label == days[now.weekday - 1] && total > 0;
                  })();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (total > 0)
                            Text('$total',
                                style: TextStyle(
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          _buildBar(pending, completed, maxVal),
                          const SizedBox(height: 6),
                          Text(label,
                              style: TextStyle(
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBar(int pending, int completed, int maxVal) {
    const maxHeight = 70.0;
    final total = pending + completed;
    if (total == 0) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    final totalHeight = (total / maxVal) * maxHeight;
    final completedHeight = (completed / total) * totalHeight;
    final pendingHeight = totalHeight - completedHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pendingHeight > 0)
          Container(
            height: pendingHeight,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: completedHeight == 0
                  ? BorderRadius.circular(4)
                  : const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        if (completedHeight > 0)
          Container(
            height: completedHeight,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: pendingHeight == 0
                  ? BorderRadius.circular(4)
                  : const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
          ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildNewInspectionTile(),
        _buildActionTile(Icons.history_outlined, 'Recent\nInspections',
            () => Get.toNamed('/inspections')),
        _buildActionTile(
            Icons.calendar_today_outlined,
            'Scheduled\nInspections',
            () => Get.toNamed('/inspections',
                arguments: {'filter': 'scheduled'})),
        _buildActionTile(Icons.layers_outlined, 'Pre-built\nTemplates', () {}),
      ],
    );
  }

  Widget _buildNewInspectionTile() {
    return GestureDetector(
      onTap: () => Get.toNamed('/inspection-form'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradient1, AppColors.gradient2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
            Text(
              'New\nInspection',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity Feed',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final items = controller.recentActivity;
          if (controller.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (items.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('No recent activity',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 13)),
              ),
            );
          }
          return Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActivityItem(item),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildActivityItem(dynamic inspection) {
    final isPending = inspection.isPending as bool;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPending ? AppColors.warning : AppColors.primary)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              color: isPending ? AppColors.warning : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inspection.propertyAddress,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${inspection.typeLabel} · ${inspection.inspectionTime}',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isPending ? AppColors.warning : AppColors.primary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              inspection.statusLabel,
              style: TextStyle(
                  color: isPending ? AppColors.warning : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Pro',
        style: TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
