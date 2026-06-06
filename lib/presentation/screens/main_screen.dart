import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:primesoftware/data/models/inspection_model.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/main_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/inspection_list_controller.dart';
import 'calendar_screen.dart';
import 'inspection_list_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends GetView<MainController> {
    MainScreen({super.key});
var width,height;
  @override
  Widget build(BuildContext context) {
    width=MediaQuery.of(context).size.width;
    height=MediaQuery.of(context).size.height;  
    return Scaffold(
      body: Obx(() => _getScreen(controller.currentIndex.value)),
      bottomNavigationBar: _buildBottomNav(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Get.toNamed('/inspection-form'),
      //   backgroundColor: AppColors.primary,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardContent();
      case 1:
        return const InspectionListContent();
      case 2:
        return const CalendarContent();
      case 3:
        return const NotificationsContent();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardContent();
    }
  }

  Widget _buildBottomNav() {
    return Obx(() {
      final current = controller.currentIndex.value;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0, current),
                _navItem(Icons.list_alt_rounded, Icons.list_alt_outlined, 'Inspect', 1, current),
                _navItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar', 2, current),
                _navItem(Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts', 0, current),
                _navItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 4, current),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label, int index, int current) {
    final isActive = current == index;
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard content without bottom nav
class DashboardContent extends GetView<DashboardController> {
  const DashboardContent({super.key});

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
              const SizedBox(height: 20),
              _buildHeroText(),
              const SizedBox(height: 24),
              _buildTotalPropertiesCard(),
              const SizedBox(height: 16),
              _buildDonutChartCard(),
              const SizedBox(height: 16),
              _buildWeeklyBarChart(),
              const SizedBox(height: 16),
              _buildActionGrid(),
              const SizedBox(height: 24),
              _buildRecentActivityFeed(),
              const SizedBox(height: 24),
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
        Row(
          children: [
            const Text('Ease',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
              child: const Text('Inspect', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Get.find<MainController>().changeIndex(2),
          child: Stack(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface, shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 20),
              ),
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: const Center(child: Text('0', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Property',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.bold, height: 1.1)),
        Text('Inspections Made Simple',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w400, height: 1.4)),
      ],
    );
  }

  // ── Total Assigned Properties banner ──────────────────────────────────────
  Widget _buildTotalPropertiesCard() {
    return Obx(() {
      final total = controller.totalProperties;
      final completed = controller.completedCount;
      final pending = controller.pendingCount;
      final progress = total == 0 ? 0.0 : completed / total;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradient1, AppColors.gradient2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Assigned Properties',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text('$total',
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, height: 1)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniChip(total == 0 ? '0% Done' : '${(completed / total * 100).round()}% Done', Colors.white24),
                            const SizedBox(width: 8),
                            _buildMiniChip(total == 0 ? '0% Pending' : '${(pending / total * 100).round()}% Pending', Colors.white24),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildCircularProgress(progress),
                ],
              ),
      );
    });
  }

  Widget _buildMiniChip(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _buildCircularProgress(double value) {
    return SizedBox(
      width: 80, height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Center(
            child: Text('${(value * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Donut chart card ───────────────────────────────────────────────────────
  Widget _buildDonutChartCard() {
    return Obx(() {
      final completed = controller.completedCount.toDouble();
      final pending = controller.pendingCount.toDouble();
      final total = controller.totalProperties;
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
            const Text('Inspection Breakdown',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: total == 0
                          ? [PieChartSectionData(value: 1, color: AppColors.border, radius: 22, title: '')]
                          : [
                              PieChartSectionData(value: completed, color: AppColors.primary, radius: 28, title: ''),
                              PieChartSectionData(value: pending, color: AppColors.warning, radius: 24, title: ''),
                            ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Completed', '${controller.completedCount}', AppColors.primary),
                      const SizedBox(height: 14),
                      _buildLegendItem('Pending', '${controller.pendingCount}', AppColors.warning),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Weekly bar chart ───────────────────────────────────────────────────────
  Widget _buildWeeklyBarChart() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Obx(() {
      final data = controller.weeklyData;
      final maxY = data.fold<double>(
        1,
        (prev, e) {
          final total = (e['completed'] as int) + (e['pending'] as int);
          return total > prev ? total.toDouble() : prev;
        },
      );
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
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildDot(AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Done',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(width: 12),
                    _buildDot(AppColors.warning),
                    const SizedBox(width: 4),
                    const Text('Pending',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY + 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          data[v.toInt()]['label'] as String,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final completed =
                        (data[i]['completed'] as int).toDouble();
                    final pending = (data[i]['pending'] as int).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: completed,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: pending,
                          color: AppColors.warning,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDot(Color color) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // ── Action grid ────────────────────────────────────────────────────────────
  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            Icons.history_outlined, 'Recent\nInspections',
            () => Get.find<MainController>().changeIndex(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            Icons.calendar_today_outlined, 'Scheduled\nInspections',
            () => Get.find<MainController>().changeIndex(1),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ── Recent activity ────────────────────────────────────────────────────────
  Widget _buildRecentActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() {
          final items = controller.recentActivity;
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                    style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              ),
            );
          }
          return Column(
            children: items.map((item) {
              final isDone = item.isCompleted;
              return GestureDetector(
                onTap: () => Get.toNamed('/inspection-detail', arguments: item),
                child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: (isDone ? AppColors.primary : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDone ? Icons.check_circle_outline : Icons.schedule,
                        color: isDone ? AppColors.primary : AppColors.warning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Inspection at ${item.propertyAddress}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.inspectionTime,
                            style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDone ? AppColors.primary : AppColors.warning).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: TextStyle(
                              color: isDone ? AppColors.primary : AppColors.warning,
                              fontSize: 10, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
            }).toList(),
          );
        }),
      ],
    );
  }
}

// Inspection List content without bottom nav
class InspectionListContent extends StatefulWidget {
  const InspectionListContent({super.key});

  @override
  State<InspectionListContent> createState() => _InspectionListContentState();
}

class _InspectionListContentState extends State<InspectionListContent>
    with SingleTickerProviderStateMixin {
  bool showMap = false;
  final _controller = Get.find<InspectionListController>();
  GoogleMapController? mapController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          showMap ? 'Map View' : 'Inspections',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.find<MainController>().changeIndex(2),
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (!showMap) _buildTabs(),
          Expanded(
            child: showMap
                ? _buildMapView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListView(false),
                      _buildListView(true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final type = _controller.selectedType.value;
      final date = _controller.selectedDate.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', type == null && date == null, () {
                      _controller.setTypeFilter(null);
                      _controller.setDateFilter(null);
                    }),
                    const SizedBox(width: 8),
                    _filterChip('Entry', type == 1, () => _controller.setTypeFilter(type == 1 ? null : 1)),
                    const SizedBox(width: 8),
                    _filterChip('Exit', type == 2, () => _controller.setTypeFilter(type == 2 ? null : 2)),
                    const SizedBox(width: 8),
                    _filterChip('Routine', type == 3, () => _controller.setTypeFilter(type == 3 ? null : 3)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        _controller.setDateFilter(picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: date != null ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: date != null ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          date != null ? '${date.day}/${date.month}/${date.year}' : 'Date',
                          style: TextStyle(
                            color: date != null ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => showMap = !showMap),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  showMap ? Icons.list : Icons.map,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildListView(bool? completedFilter) {
    return RefreshIndicator(
      onRefresh: _controller.loadInspections,
      color: AppColors.primary,
      child: Obx(() {
        var inspections = _controller.filteredInspections;
        if (completedFilter != null) {
          inspections = completedFilter
              ? inspections.where((i) => i.isCompleted).toList()
              : inspections.where((i) => i.isPending).toList();
        }
        if (inspections.isEmpty) {
          return const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: Center(
                  child: Text('No inspections found', style: TextStyle(color: AppColors.textHint)),
                ),
              ),
            ],
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: inspections.length,
          itemBuilder: (_, i) {
            final item = inspections[i];
            final statusColor = item.isPending ? AppColors.warning : AppColors.primary;
            return _buildInspectionCard(
              item,
              item.propertyAddress,
              '${item.inspectionDate.split('T').first} • ${item.inspectionTime}',
              item.typeLabel,
              statusColor,
              item.statusLabel,
              () => Get.toNamed('/inspection-detail', arguments: item),
            );
          },
        );
      }),
    );
  }

  Widget _buildInspectionCard(
 InspectionModel   inspectionModel,
    String address, String date, String type, Color statusColor, String status, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                  Text(
                  '${inspectionModel.inspectorName}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final inspections = _controller.inspections;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SizedBox.expand(
                child: Obx(() => GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-33.8688, 151.2093),
                    zoom: 12,
                  ),
                  markers: _controller.markers.toSet(),
                  onMapCreated: (c) {
                    mapController = c;
                    _controller.onMapCreated(c);
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                )),
              ),
            ],
          ),
        ),
        // Horizontal card strip — real data, scrollable
        Container(
          color: AppColors.background,
          height: 200,
          child: Obx(() {
            final items = _controller.inspections;
            if (items.isEmpty) {
              return const Center(
                child: Text('No inspections found',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              );
            }
            return PageView.builder(
              controller: _controller.pageController,
              itemCount: items.length,
              onPageChanged: _controller.onPageChanged,
              physics: const PageScrollPhysics(),
              itemBuilder: (_, i) {
                final item = items[i];
                final statusColor =
                    item.isPending ? const Color(0xFFF59E0B) : AppColors.primary;
                return Obx(() {
                  final isSelected = _controller.selectedIndex.value == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.fromLTRB(8, isSelected ? 4 : 14, 8, isSelected ? 4 : 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                      color: statusColor, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.propertyAddress,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(item.statusLabel,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(item.inspectionDate.split('T').first,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(width: 10),
                              const Icon(Icons.access_time,
                                  size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(item.inspectionTime,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(item.typeLabel,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.textSecondary)),
                              ),
                              const Spacer(),
                              Text(item.inspectorName,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Get.toNamed('/inspection-detail', arguments: item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Open Inspection →',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }
}


// Notifications content without bottom nav
class NotificationsContent extends StatelessWidget {
  const NotificationsContent({super.key});

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
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Notifications will be available\nin a future update.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}