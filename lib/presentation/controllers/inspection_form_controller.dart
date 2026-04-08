import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/report_template_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';

class InspectionFormController extends GetxController {
  final _api = ApiService();
  final _picker = ImagePicker();

  final Rxn<InspectionModel> inspection = Rxn<InspectionModel>();
  final Rxn<ReportTemplate> template = Rxn<ReportTemplate>();
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;

  // key: 'areaIdx-itemIdx-condIdx' → bool or String
  final Map<String, dynamic> conditionValues = {};
  // key: 'areaIdx-itemIdx' → List<String>
  final Map<String, List<String>> commentValues = {};
  // key: 'areaIdx-itemIdx' → List<String> (local paths or uploaded URLs)
  final Map<String, List<String>> photoValues = {};
  // key: 'areaIdx-itemIdx' → bool
  final Map<String, bool> expandedState = {};

  ConnectivityService get _connectivity => Get.find<ConnectivityService>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is InspectionModel) {
      inspection.value = args;
      _fetchTemplate();
    }
    // Auto-sync pending reports when coming back online
    ever(_connectivity.isOnline, (online) {
      if (online) _syncPendingReports();
    });
  }

  String _ck(int a, int i, int c) => '$a-$i-$c';
  String _ik(int a, int i) => '$a-$i';

  Future<void> _fetchTemplate() async {
    final item = inspection.value;
    if (item == null) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final isEntryExit = item.inspectionType == 2 || item.inspectionType == 3;
      final response = await _api.getReportTemplate(item.id, isEntryExit: isEntryExit);
      if (response.data['success'] == true) {
        final parsed = ReportTemplateResponse.fromJson(response.data);
        template.value = parsed.data;
        _initFormState(parsed.data);
      } else {
        errorMessage.value = response.data['message'] ?? 'Failed to load template';
      }
    } catch (e, st) {
      if (e.toString().contains('TickerProvider') || e.toString().contains('Ticker')) rethrow;
      print('fetchTemplate error: $e\n$st');
      errorMessage.value = 'Failed to load inspection template: $e';
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
          conditionValues[_ck(aIdx, iIdx, cIdx)] = cond.type == 'boolean'
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

  // ─── Build sync payload ───────────────────────────────────────────────────

  Map<String, dynamic> _buildPayload({required Map<String, String> uploadedPhotoUrls}) {
    final item = inspection.value!;
    final t = template.value!;

    final reportAreas = t.reportAreas.asMap().entries.map((aEntry) {
      final aIdx = aEntry.key;
      final area = aEntry.value;
      final reportItems = area.reportItems.asMap().entries.map((iEntry) {
        final iIdx = iEntry.key;
        final ri = iEntry.value;
        final ik = _ik(aIdx, iIdx);

        final conditions = ri.reportItemConditions.asMap().entries.map((cEntry) {
          final cIdx = cEntry.key;
          final cond = cEntry.value;
          final ck = _ck(aIdx, iIdx, cIdx);
          dynamic value = conditionValues[ck];
          if (cond.type == 'boolean') {
            value = value == true;
          } else if (cond.type == 'number') {
            value = value != null && value.toString().isNotEmpty
                ? num.tryParse(value.toString())
                : null;
          } else {
            value = value?.toString().isEmpty == true ? null : value?.toString();
          }
          return {
            'description': cond.description,
            'type': cond.type,
            'value': value,
          };
        }).toList();

        final comments = (commentValues[ik] ?? [])
            .map((c) => {'text': c})
            .toList();

        final photos = (photoValues[ik] ?? []).asMap().entries.map((e) {
          final photoKey = '$ik-${e.key}';
          final url = uploadedPhotoUrls[photoKey] ?? e.value;
          return {'url': url, 'type': 'photo'};
        }).toList();

        return {
          'name': ri.name,
          'reportItemConditions': conditions,
          'reportItemComments': comments,
          'reportMedia': photos,
        };
      }).toList();

      return {'name': area.name, 'reportItems': reportItems};
    }).toList();

    return {
      'AgencyId': item.agencyId,
      'inspectionId': item.id,
      'reportType': item.typeLabel,
      'notes': '',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'reportAreas': reportAreas,
    };
  }

  // ─── Upload photos → returns map of 'aIdx-iIdx-photoIdx' → uploaded URL ──

  Future<Map<String, String>> _uploadPhotos() async {
    final item = inspection.value!;
    final uploaded = <String, String>{};
    final t = template.value!;

    for (var aIdx = 0; aIdx < t.reportAreas.length; aIdx++) {
      final area = t.reportAreas[aIdx];
      for (var iIdx = 0; iIdx < area.reportItems.length; iIdx++) {
        final ik = _ik(aIdx, iIdx);
        final photos = photoValues[ik] ?? [];
        for (var pIdx = 0; pIdx < photos.length; pIdx++) {
          final path = photos[pIdx];
          if (path.startsWith('http')) {
            uploaded['$ik-$pIdx'] = path;
            continue;
          }
          try {
            print('Uploading photo $ik-$pIdx: $path');
            final fileUrl = await _api.uploadPhoto(
              agencyId: item.agencyId,
              propertyId: item.propertyId,
              inspectionId: item.id,
              filePath: path,
            );
            print('Uploaded $ik-$pIdx → $fileUrl');
            uploaded['$ik-$pIdx'] = fileUrl;
          } catch (e) {
            print('Photo upload failed for $ik-$pIdx: $e');
          }
        }
      }
    }
    return uploaded;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> submitInspection() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      if (!_connectivity.isOnline.value) {
        // Save locally and notify user
        final payload = _buildPayload(uploadedPhotoUrls: {});
        await StorageService.savePendingReport(payload);
        Get.offAllNamed('/main');
        Get.snackbar(
          'Saved Offline',
          'Report saved locally. It will sync when you reconnect.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Upload photos first
      final uploadedUrls = await _uploadPhotos();
      final payload = _buildPayload(uploadedPhotoUrls: uploadedUrls);

      final response = await _api.syncReport(payload);
      if (response.data['success'] == true || response.statusCode == 200) {
        Get.offAllNamed('/main');
        Get.snackbar(
          'Success',
          'Report submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        final msg = response.data['message'] ?? 'Submission failed';
        Get.snackbar('Error', msg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      Get.snackbar('Error', msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Auto-sync pending reports when back online ───────────────────────────

  Future<void> _syncPendingReports() async {
    final pending = await StorageService.getPendingReports();
    if (pending.isEmpty) return;
    print('Syncing ${pending.length} pending report(s)...');
    for (var i = pending.length - 1; i >= 0; i--) {
      try {
        final response = await _api.syncReport(pending[i]);
        if (response.data['success'] == true || response.statusCode == 200) {
          await StorageService.removePendingReport(i);
          print('Pending report $i synced successfully');
        }
      } catch (e) {
        print('Failed to sync pending report $i: $e');
      }
    }
    final remaining = await StorageService.getPendingReports();
    if (remaining.isEmpty) {
      Get.snackbar(
        'Synced',
        'All pending reports submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
