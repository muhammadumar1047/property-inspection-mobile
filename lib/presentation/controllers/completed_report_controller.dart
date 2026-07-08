import 'package:get/get.dart';
import '../../data/models/inspection_model.dart';
import '../../data/services/api_service.dart';

class CompletedReportController extends GetxController {
  final _api = ApiService();

  final Rxn<InspectionModel> inspection = Rxn();
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final Rxn<Map<String, dynamic>> data = Rxn();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is InspectionModel) {
      inspection.value = args;
      _fetch(args.id);
    }
  }

  Future<void> refresh() async {
    if (inspection.value != null) await _fetch(inspection.value!.id);
  }

  Future<void> _fetch(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      print("my inspected report id is: ${id}");
      final response = await _api.getInspectionById(id);
      final body = response.data as Map<String, dynamic>;
      data.value = body['data'] as Map<String, dynamic>?;
    } catch (e) {
      errorMessage.value = 'Failed to load: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic>? get property => data.value?['property'] as Map<String, dynamic>?;
  Map<String, dynamic>? get inspector => data.value?['inspector'] as Map<String, dynamic>?;
  List<dynamic> get landlordSnapshots => (data.value?['landlordSnapshots'] ?? []) as List;
  List<dynamic> get tenancySnapshots => (data.value?['tenancySnapshots'] ?? []) as List;

  String get propertyImage => property?['propertyImages']?.toString() ?? '';
  String get propertyAddress => data.value?['propertyAddress']?.toString() ?? '';
  String get propertySuburb => data.value?['propertySubhurb']?.toString() ?? '';
  String get inspectorName => data.value?['inspectorName']?.toString() ?? '';
  String get inspectionDate => (data.value?['inspectionDate']?.toString() ?? '').split('T').first;
  String get inspectionTime => data.value?['inspectionTime']?.toString() ?? '';
  String get typeLabel {
    switch (data.value?['inspectionType']) {
      case 1: return 'Entry';
      case 2: return 'Exit';
      case 3: return 'Routine';
      default: return 'Inspection';
    }
  }

  // Property details
  String get keyNo => property?['keyNo']?.toString() ?? '';
  String get alarmCode => property?['alarmCode']?.toString() ?? '';
  String get propertyNotes => property?['propertyNotes']?.toString() ?? '';
  String get postcode => property?['postcode']?.toString() ?? '';
  String get address2 => property?['address2']?.toString() ?? '';
}
