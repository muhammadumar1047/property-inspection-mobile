import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/report_template_model.dart';
import '../../data/services/api_service.dart';

class InspectionController extends GetxController {
  final _api = ApiService();
  final _picker = ImagePicker();

  final Rxn<InspectionModel> inspection = Rxn<InspectionModel>();
  final Rxn<ReportTemplate> template = Rxn<ReportTemplate>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // key: 'areaIdx-itemIdx-condIdx' → bool or String
  final Map<String, dynamic> conditionValues = {};
  // key: 'areaIdx-itemIdx' → List<String>
  final Map<String, List<String>> commentValues = {};
  // key: 'areaIdx-itemIdx' → List<String> (local paths)
  final Map<String, List<String>> photoValues = {};
  // key: 'areaIdx-itemIdx' → bool
  final Map<String, bool> expandedState = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is InspectionModel) {
      inspection.value = args;
      _fetchTemplate();
    }
  }

  String _ck(int a, int i, int c) => '$a-$i-$c';
  String _ik(int a, int i) => '$a-$i';

  Future<void> _fetchTemplate() async {
    final item = inspection.value;
    if (item == null) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // type 1 = Routine, type 2 = Entry, type 3 = Exit
      final isEntryExit = item.inspectionType == 2 || item.inspectionType == 3;
      final response = await _api.getReportTemplate(item.id, isEntryExit: isEntryExit);
      if (response.data['success'] == true) {
        final parsed = ReportTemplateResponse.fromJson(response.data);
        template.value = parsed.data;
        _initFormState(parsed.data);
      } else {
        errorMessage.value = response.data['message'] ?? 'Failed to load template';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load inspection template';
    } finally {
      isLoading.value = false;
    }
  }

  void _initFormState(ReportTemplate t) {
    conditionValues.clear();
    commentValues.clear();
    photoValues.clear();
    expandedState.clear();
    for (var aIdx = 0; aIdx < t.reportAreas.length; aIdx++) {
      final area = t.reportAreas[aIdx];
      for (var iIdx = 0; iIdx < area.reportItems.length; iIdx++) {
        final item = area.reportItems[iIdx];
        final ik = _ik(aIdx, iIdx);
        expandedState[ik] = false;
        commentValues[ik] = item.reportItemComments
            .map((c) => c.text)
            .where((t) => t.isNotEmpty)
            .toList();
        photoValues[ik] = [];
        for (var cIdx = 0; cIdx < item.reportItemConditions.length; cIdx++) {
          final cond = item.reportItemConditions[cIdx];
          final ck = _ck(aIdx, iIdx, cIdx);
          conditionValues[ck] = cond.type == 'boolean'
              ? (cond.value == true || cond.value == 'true')
              : (cond.value?.toString() ?? '');
        }
      }
    }
  }

  bool getBool(int a, int i, int c) => conditionValues[_ck(a, i, c)] == true;
  String getText(int a, int i, int c) => conditionValues[_ck(a, i, c)]?.toString() ?? '';

  void setBool(int a, int i, int c, bool val) {
    conditionValues[_ck(a, i, c)] = val;
    update(['form']);
  }

  void setText(int a, int i, int c, String val) {
    conditionValues[_ck(a, i, c)] = val;
  }

  List<String> getComments(int a, int i) => commentValues[_ik(a, i)] ?? [];

  void addComment(int a, int i, String text) {
    commentValues[_ik(a, i)] ??= [];
    commentValues[_ik(a, i)]!.add(text);
    update(['form']);
  }

  void removeComment(int a, int i, int idx) {
    commentValues[_ik(a, i)]?.removeAt(idx);
    update(['form']);
  }

  List<String> getPhotos(int a, int i) => photoValues[_ik(a, i)] ?? [];

  Future<void> pickPhoto(int a, int i, ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      photoValues[_ik(a, i)] ??= [];
      photoValues[_ik(a, i)]!.add(file.path);
      update(['form']);
    }
  }

  void removePhoto(int a, int i, int idx) {
    photoValues[_ik(a, i)]?.removeAt(idx);
    update(['form']);
  }

  bool isExpanded(int a, int i) => expandedState[_ik(a, i)] ?? false;

  void toggleExpanded(int a, int i) {
    expandedState[_ik(a, i)] = !(expandedState[_ik(a, i)] ?? false);
    update(['form']);
  }

  int get totalItems {
    final t = template.value;
    if (t == null) return 0;
    return t.reportAreas.fold(0, (sum, a) => sum + a.reportItems.length);
  }

  void submitInspection() {
    Get.snackbar('Success', 'Inspection submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white);
    Get.back();
  }
}
