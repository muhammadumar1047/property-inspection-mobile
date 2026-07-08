import 'package:get/get.dart';
import '../../data/models/inspection_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';

class DashboardController extends GetxController {
  final _api = ApiService();

  final isLoading = false.obs;
  final isOffline = false.obs;

  final allInspections = <InspectionModel>[].obs;
  final weeklyData = List.generate(
    7,
    (_) => <String, dynamic>{'label': '-', 'pending': 0, 'completed': 0},
  ).obs;

  // Computed stats
  int get totalProperties => allInspections.length;
  int get pendingCount =>
      allInspections.where((i) => i.inspectionStatus == 1).length;
  int get completedCount =>
      allInspections.where((i) => i.inspectionStatus == 4).length;

  List<InspectionModel> get recentActivity => allInspections.take(3).toList();

  void _computeWeeklyData() {
    final list = allInspections.toList();
    if (list.isEmpty) {
      weeklyData.assignAll(
        List.generate(7, (_) => {'label': '-', 'pending': 0, 'completed': 0}),
      );
      return;
    }

    final Map<String, Map<String, int>> grouped = {};
    for (final ins in list) {
      final d = ins.parsedDate;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => {'pending': 0, 'completed': 0});
      if (ins.inspectionStatus == 1)
        grouped[key]!['pending'] = grouped[key]!['pending']! + 1;
      if (ins.inspectionStatus == 4)
        grouped[key]!['completed'] = grouped[key]!['completed']! + 1;
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 7
        ? sortedKeys.sublist(sortedKeys.length - 7)
        : sortedKeys;

    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final result = recentKeys.map((key) {
      final d = DateTime.parse(key);
      return <String, dynamic>{
        'label': dayLetters[d.weekday - 1],
        'pending': grouped[key]!['pending']!,
        'completed': grouped[key]!['completed']!,
      };
    }).toList();

    while (result.length < 7) {
      result.insert(0, {'label': '-', 'pending': 0, 'completed': 0});
    }
    weeklyData.assignAll(result);
  }

  @override
  void onInit() {
    super.onInit();
    loadInspections();
  }

  Future<void> loadInspections() async {
    isLoading.value = true;
    final connectivity = Get.find<ConnectivityService>();

    if (connectivity.isOnline.value) {
      try {
        final response = await _api.getInspections();
        if (response.data['success'] == true) {
          final parsed = InspectionListResponse.fromJson(response.data);
          print('API Inspection Response: ${response.data}');
          allInspections.assignAll(parsed.data.data);
          _computeWeeklyData();
          await StorageService.saveInspections(parsed.data.data);
          isOffline.value = false;
          // Debug
          for (final ins in allInspections) {
            print(
              'INS: id=${ins.id} date=${ins.inspectionDate} parsedDate=${ins.parsedDate} status=${ins.inspectionStatus} isPending=${ins.isPending} isCompleted=${ins.isCompleted}',
            );
          }
          print('weeklyData: ${weeklyData}');
        }
      } catch (_) {
        await _loadFromCache();
      }
    } else {
      await _loadFromCache();
    }

    isLoading.value = false;
  }

  Future<void> _loadFromCache() async {
    final cached = await StorageService.getCachedInspections();
    allInspections.assignAll(cached);
    _computeWeeklyData();
    isOffline.value = true;
  }
}
