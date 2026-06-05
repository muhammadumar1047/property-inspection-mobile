import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/inspection_model.dart';
import '../controllers/calendar_controller.dart';

// ─── Constants ──────────────────────────────────────────────────────────────

const _kWeekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _kMonthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// ─── Root screen ────────────────────────────────────────────────────────────

class CalendarContent extends StatefulWidget {
  const CalendarContent({super.key});

  @override
  State<CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  // We keep a large virtual page list centred at index 1200 so the user can
  // swipe left/right almost infinitely, just like Google Calendar.
  static const int _kBase = 1200;
  late final PageController _pageCtrl;
  late CalendarController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CalendarController>();
    _pageCtrl = PageController(initialPage: _kBase, viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // Convert virtual page index → real month offset from today's month
  DateTime _monthForPage(int page) {
    final now = DateTime.now();
    final offset = page - _kBase;
    final month = now.month + offset;
    final year = now.year + (month - 1) ~/ 12;
    final normalised = ((month - 1) % 12) + 1;
    return DateTime(year, normalised);
  }

  void _onPageChanged(int page) {
    final month = _monthForPage(page);
    _ctrl.focusedMonth.value = month;
    // Clear selection when month changes via swipe
    _ctrl.selectedDay.value = null;
  }

  // Programmatic month navigation (chevron buttons) keeps page in sync
  void _goToPrev() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  void _goToNext() {
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final focused = _ctrl.focusedMonth.value;
        final selected = _ctrl.selectedDay.value;
        final dayItems = _ctrl.selectedDayInspections;
        final today = DateTime.now();

        return NestedScrollView(
          headerSliverBuilder: (context, _) => [
            // ── App bar with month title + nav arrows ──────────────────
            SliverAppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              pinned: true,
              floating: false,
              title: GestureDetector(
                onTap: () {
                  // Jump back to today
                  final now = DateTime.now();
                  final offset =
                      (now.year - today.year) * 12 + (now.month - today.month);
                  _pageCtrl.animateToPage(
                    _kBase + offset,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                  _ctrl.selectedDay.value = today;
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_kMonthNames[focused.month - 1]} ${focused.year}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
              centerTitle: false,
              leading: const SizedBox.shrink(),
              leadingWidth: 0,
              actions: [
                Obx(() => _ctrl.isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.today_outlined,
                            color: AppColors.textSecondary, size: 22),
                        tooltip: 'Jump to today',
                        onPressed: () {
                          final now = DateTime.now();
                          _pageCtrl.animateToPage(
                            _kBase,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                          _ctrl.focusedMonth.value =
                              DateTime(now.year, now.month);
                          _ctrl.selectedDay.value = now;
                        },
                      )),
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary, size: 26),
                  onPressed: _goToPrev,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 26),
                  onPressed: _goToNext,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ── Sticky weekday header ──────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _WeekdayHeaderDelegate(),
            ),
          ],

          body: CustomScrollView(
            slivers: [
              // ── Colour legend ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _LegendDot(color: AppColors.warning),
                      const SizedBox(width: 4),
                      const Text('Pending',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                      const SizedBox(width: 12),
                      _LegendDot(
                          color: AppColors.primary.withValues(alpha: 0.55)),
                      const SizedBox(width: 4),
                      const Text('Completed',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                      const SizedBox(width: 12),
                      _LegendDot(
                          gradient: const LinearGradient(
                              colors: [AppColors.warning, AppColors.primary])),
                      const SizedBox(width: 4),
                      const Text('Mixed',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              // ── Swipeable month grid ─────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _monthGridHeight(focused),
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, page) {
                      final month = _monthForPage(page);
                      return Obx(() {
                        final currentPage = _pageCtrl.hasClients
                            ? (_pageCtrl.page?.round() ?? _kBase)
                            : _kBase;
                        final map = currentPage == page
                            ? _ctrl.monthMap
                            : _buildMonthMap(month);
                        return _MonthGrid(
                          month: month,
                          monthMap: map,
                          selected: _ctrl.selectedDay.value,
                          today: today,
                          onDayTap: _ctrl.selectDay,
                        );
                      });
                    },
                  ),
                ),
              ),

              // ── Divider ──────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Divider(height: 1, color: AppColors.border),
              ),

              // ── Selected-day header ──────────────────────────────────
              if (selected != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Row(
                      children: [
                        // Big day circle (Google Calendar style)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isToday(selected, today)
                                ? AppColors.primary
                                : AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isToday(selected, today)
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${selected.day}',
                                style: TextStyle(
                                    color: _isToday(selected, today)
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _weekdayName(selected.weekday),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11),
                            ),
                            Text(
                              '${_kMonthShort[selected.month - 1]} ${selected.day}, ${selected.year}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (dayItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${dayItems.length} event${dayItems.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Inspection cards ─────────────────────────────────────
              if (selected != null && dayItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _InspectionCard(item: dayItems[i]),
                      childCount: dayItems.length,
                    ),
                  ),
                ),

              // ── No inspections for selected day ──────────────────────
              if (selected != null && dayItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.event_busy_outlined,
                    message:
                        'No inspections on\n${_kMonthShort[selected.month - 1]} ${selected.day}',
                  ),
                ),

              // ── Nothing selected yet ─────────────────────────────────
              if (selected == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.calendar_today_outlined,
                    message: 'Select a day to\nview inspections',
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // Pre-compute monthMap for non-active pages (no reactive rebuild needed)
  Map<int, List<InspectionModel>> _buildMonthMap(DateTime month) {
    final map = <int, List<InspectionModel>>{};
    for (final i in _ctrl.inspections) {
      final p = i.parsedDate;
      if (p.year == month.year && p.month == month.month) {
        map.putIfAbsent(p.day, () => []).add(i);
      }
    }
    return map;
  }

  // Height varies by number of grid rows (5 or 6 weeks)
  double _monthGridHeight(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final rows = ((startWeekday + daysInMonth) / 7).ceil();
    return rows * 52.0 + 8; // 52 per row + small padding
  }

  bool _isToday(DateTime d, DateTime today) =>
      d.year == today.year && d.month == today.month && d.day == today.day;

  String _weekdayName(int wd) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(wd - 1) % 7];
  }
}

// ─── Sticky weekday row ─────────────────────────────────────────────────────

class _WeekdayHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Row(
        children: _kWeekdays
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: d == 'S'
                            ? AppColors.error.withValues(alpha: 0.8)
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(_WeekdayHeaderDelegate old) => false;
}

// ─── Month grid (one page) ──────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, List<InspectionModel>> monthMap;
  final DateTime? selected;
  final DateTime today;
  final void Function(DateTime) onDayTap;

  const _MonthGrid({
    required this.month,
    required this.monthMap,
    required this.selected,
    required this.today,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sun=0 … Sat=6
    final totalCells = startWeekday + daysInMonth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: totalCells,
        itemBuilder: (_, idx) {
          if (idx < startWeekday) return const SizedBox.shrink();
          final day = idx - startWeekday + 1;
          final date = DateTime(month.year, month.month, day);
          final inspList = monthMap[day] ?? [];
          final hasItems = inspList.isNotEmpty;

          final isToday = today.year == date.year &&
              today.month == date.month &&
              today.day == date.day;

          final isSelected = selected != null &&
              selected!.year == date.year &&
              selected!.month == date.month &&
              selected!.day == date.day;

          final isSunday = date.weekday == DateTime.sunday;
          final isSaturday = date.weekday == DateTime.saturday;
          final isWeekend = isSunday || isSaturday;

          final pendingCount = inspList.where((i) => i.isPending).length;
          final completedCount = inspList.where((i) => i.isCompleted).length;

          // Determine fill colour / gradient for this cell
          final hasBoth = pendingCount > 0 && completedCount > 0;
          final onlyPending = pendingCount > 0 && completedCount == 0;
          final onlyCompleted = completedCount > 0 && pendingCount == 0;

          // Text is white whenever the cell has a coloured background
          final hasBackground = isSelected || (hasItems && !isToday);
          final textColor = hasBackground
              ? Colors.white
              : isToday
                  ? AppColors.primary
                  : isWeekend
                      ? AppColors.error.withValues(alpha: 0.75)
                      : AppColors.textPrimary;

          BoxDecoration cellDecoration;
          if (isSelected) {
            cellDecoration = const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            );
          } else if (isToday) {
            // Today ring — no fill even if it has inspections; selection shows fill
            cellDecoration = BoxDecoration(
              color: hasItems
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            );
          } else if (hasBoth) {
            cellDecoration = const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            );
          } else if (onlyPending) {
            cellDecoration = BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            );
          } else if (onlyCompleted) {
            cellDecoration = BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            );
          } else {
            cellDecoration = const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            );
          }

          return GestureDetector(
            onTap: () => onDayTap(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.all(3),
              decoration: cellDecoration,
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || isSelected || hasItems
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Inspection card ────────────────────────────────────────────────────────

class _InspectionCard extends StatelessWidget {
  final InspectionModel item;
  const _InspectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isPending ? AppColors.warning : AppColors.primary;
    return GestureDetector(
      onTap: () => Get.toNamed('/inspection-detail', arguments: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Google Calendar-style coloured left bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Time column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(item.inspectionTime),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.typeLabel,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Vertical divider
              Container(
                  width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.propertyAddress,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.propertySubhurb.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.propertySubhurb,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _StatusChip(
                              label: item.statusLabel, color: statusColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.inspectorName,
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String t) {
    if (t.isEmpty) return '--:--';
    // Attempt AM/PM formatting if it's HH:mm or HH:mm:ss
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      final suffix = h >= 12 ? 'PM' : 'AM';
      h = h % 12 == 0 ? 12 : h % 12;
      return '$h:$m $suffix';
    } catch (_) {
      return t;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

// ─── Legend dot ─────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color? color;
  final Gradient? gradient;
  const _LegendDot({this.color, this.gradient});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          shape: BoxShape.circle,
        ),
      );
}

// ─── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.gradient1, AppColors.gradient2]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5),
            ),
          ],
        ),
      );
}
