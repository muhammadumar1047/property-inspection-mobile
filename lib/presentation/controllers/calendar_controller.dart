import 'package:get/get.dart';
import '../../data/models/inspection_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';

class CalendarController extends GetxController {
  final _api = ApiService();

  final isLoading = false.obs;
  final inspections = <InspectionModel>[].obs;
  final focusedMonth = DateTime.now().obs; // month being displayed
  final selectedDay = Rxn<DateTime>();

  /// All inspections on the currently selected day.
  List<InspectionModel> get selectedDayInspections {
    final d = selectedDay.value;
    if (d == null) return [];
    return inspections.where((i) {
      final p = i.parsedDate;
      return p.year == d.year && p.month == d.month && p.day == d.day;
    }).toList();
  }

  /// Map of day-of-month → list for the focused month (used for dot indicators).
  Map<int, List<InspectionModel>> get monthMap {
    final m = focusedMonth.value;
    final map = <int, List<InspectionModel>>{};
    for (final i in inspections) {
      final p = i.parsedDate;
      if (p.year == m.year && p.month == m.month) {
        map.putIfAbsent(p.day, () => []).add(i);
      }
    }
    return map;
  }

  @override
  void onInit() {
    super.onInit();
    loadInspections();
  }

  Future<void> loadInspections() async {
    isLoading.value = true;
    try {
      final connectivity = Get.find<ConnectivityService>();
      if (connectivity.isOnline.value) {
        final response = await _api.getInspections(pageSize: 500);
        if (response.data['success'] == true) {
          final parsed = InspectionListResponse.fromJson(response.data);
          inspections.assignAll(parsed.data.data);
          await StorageService.saveInspections(parsed.data.data);
          return;
        }
      }
      // Fallback to cache
      final cached = await StorageService.getCachedInspections();
      inspections.assignAll(cached);
    } catch (_) {
      final cached = await StorageService.getCachedInspections();
      inspections.assignAll(cached);
    } finally {
      isLoading.value = false;
    }
  }

  void selectDay(DateTime day) {
    final current = selectedDay.value;
    if (current != null &&
        current.year == day.year &&
        current.month == day.month &&
        current.day == day.day) {
      selectedDay.value = null; // deselect
    } else {
      selectedDay.value = day;
    }
  }

  void prevMonth() {
    final m = focusedMonth.value;
    focusedMonth.value = DateTime(m.year, m.month - 1);
  }

  void nextMonth() {
    final m = focusedMonth.value;
    focusedMonth.value = DateTime(m.year, m.month + 1);
  }
}
