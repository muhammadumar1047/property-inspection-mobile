import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/report_template_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';

class InspectionFormController extends GetxController {
  final _api = ApiService();
  final _picker = ImagePicker();
  final _speech = SpeechToText();

  final isListening = false.obs;
  final isGeneratingAi = <String, bool>{}.obs; // key: 'aIdx-iIdx'

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
  // key: 'areaIdx-itemIdx-photoIdx' → label text
  final Map<String, String> photoLabels = {};
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
    photoLabels.clear();
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
    if (source == ImageSource.gallery) {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isNotEmpty) {
        photoValues[_ik(a, i)] ??= [];
        photoValues[_ik(a, i)]!.addAll(files.map((f) => f.path));
        update(['form']);
      }
    } else {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        photoValues[_ik(a, i)] ??= [];
        photoValues[_ik(a, i)]!.add(file.path);
        update(['form']);
      }
    }
  }

  /// Quick capture: keeps opening camera until user taps Done.
  /// Each captured photo is added to the list immediately.
  Future<void> quickCapture(int a, int i) async {
    photoValues[_ik(a, i)] ??= [];
    while (true) {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      // User cancelled camera — exit cleanly
      if (file == null) break;
      photoValues[_ik(a, i)]!.add(file.path);
      update(['form']);
      // Show bottom sheet asking to take another
      final takeAnother = await showModalBottomSheet<bool>(
        context: Get.context!,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (_) => _QuickCaptureSheet(
            count: photoValues[_ik(a, i)]!.length),
      );
      // null = dismissed by drag/back = done
      if (takeAnother != true) break;
    }
  }

  bool _speechInitialized = false;

  // ─── Voice to Text ────────────────────────────────────────────────────────

  Future<void> startListening(void Function(String) onResult) async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onError: (e) {
          // error_no_match / error_speech_timeout are non-fatal — just stop
          isListening.value = false;
        },
        onStatus: (s) {
          if (s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) {
            isListening.value = false;
          }
        },
        debugLogging: false,
      );
    }
    if (!_speechInitialized) {
      Get.snackbar(
        'Microphone',
        'Speech recognition is not available on this device. Please check microphone permissions.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }
    if (_speech.isListening) await _speech.stop();
    isListening.value = true;
    String accumulated = '';
    await _speech.listen(
      onResult: (r) {
        accumulated = r.recognizedWords;
        if (r.finalResult && accumulated.isNotEmpty) {
          onResult(accumulated);
          isListening.value = false;
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
    isListening.value = false;
  }

  // ─── AI Comment Generation ────────────────────────────────────────────────

  Future<String?> generateAiComment(int a, int i, String itemName) async {
    final ik = _ik(a, i);
    isGeneratingAi[ik] = true;
    isGeneratingAi.refresh();
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final conditions = <String>[];
      final t = template.value;
      if (t != null) {
        final item = t.reportAreas[a].reportItems[i];
        for (var cIdx = 0; cIdx < item.reportItemConditions.length; cIdx++) {
          final cond = item.reportItemConditions[cIdx];
          final val = conditionValues[_ck(a, i, cIdx)];
          if (cond.type == 'boolean' && val == true) {
            conditions.add(cond.description);
          } else if (cond.type != 'boolean' && val != null && val.toString().isNotEmpty) {
            conditions.add('${cond.description}: $val');
          }
        }
      }
      return _buildAiComment(itemName, conditions);
    } finally {
      isGeneratingAi[ik] = false;
      isGeneratingAi.refresh();
    }
  }

  String _buildAiComment(String itemName, List<String> conditions) {
    final name = itemName.toLowerCase();
    final hasConditions = conditions.isNotEmpty;
    final condText = hasConditions ? conditions.join(', ').toLowerCase() : '';

    if (name.contains('wall') || name.contains('ceiling') || name.contains('floor')) {
      if (condText.contains('damage') || condText.contains('crack') || condText.contains('stain')) {
        return '$itemName shows signs of damage. Recommend inspection and repair before next tenancy.';
      }
      return '$itemName is in good condition with no visible damage or staining.';
    }
    if (name.contains('window') || name.contains('door')) {
      if (condText.contains('broken') || condText.contains('damage')) {
        return '$itemName requires attention — damage noted. Repair or replacement recommended.';
      }
      return '$itemName opens and closes properly. Locks and seals are functioning as expected.';
    }
    if (name.contains('kitchen') || name.contains('oven') || name.contains('stove')) {
      return '$itemName is clean and in working order. No defects observed during inspection.';
    }
    if (name.contains('bathroom') || name.contains('toilet') || name.contains('shower')) {
      return '$itemName is clean and functional. Plumbing and fixtures are in good working condition.';
    }
    if (name.contains('carpet') || name.contains('rug')) {
      if (condText.contains('stain') || condText.contains('worn')) {
        return '$itemName shows wear and staining. Professional cleaning or replacement may be required.';
      }
      return '$itemName is clean and in satisfactory condition with no significant wear.';
    }
    if (hasConditions) {
      return '$itemName inspected. Noted: $condText. Overall condition is satisfactory.';
    }
    return '$itemName has been inspected and is in satisfactory condition with no issues noted.';
  }

  void removePhoto(int a, int i, int idx) {
    final ik = _ik(a, i);
    photoValues[ik]?.removeAt(idx);
    // shift labels down for photos after the removed one
    final photos = photoValues[ik] ?? [];
    for (var k = idx; k <= photos.length; k++) {
      final next = photoLabels['$ik-${k + 1}'];
      if (next != null) {
        photoLabels['$ik-$k'] = next;
      } else {
        photoLabels.remove('$ik-$k');
      }
    }
    update(['form']);
  }

  String getPhotoLabel(int a, int i, int idx) =>
      photoLabels['${_ik(a, i)}-$idx'] ?? '';

  void setPhotoLabel(int a, int i, int idx, String label) {
    if (label.trim().isEmpty) {
      photoLabels.remove('${_ik(a, i)}-$idx');
    } else {
      photoLabels['${_ik(a, i)}-$idx'] = label.trim();
    }
    update(['form']);
  }

  /// Burns label text onto the image and returns path to the new annotated file.
  Future<String> _burnLabelOnImage(String sourcePath, String label) async {
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw original image
    canvas.drawImage(srcImage, Offset.zero, Paint());

    final w = srcImage.width.toDouble();
    final h = srcImage.height.toDouble();
    final fontSize = (w * 0.045).clamp(18.0, 52.0);
    final padding = fontSize * 0.6;

    // Semi-transparent dark banner at bottom
    canvas.drawRect(
      Rect.fromLTWH(0, h - fontSize * 2.2, w, fontSize * 2.2),
      Paint()..color = const Color(0xCC000000),
    );

    // Draw label text
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          ui.Shadow(color: const Color(0xFF000000), blurRadius: 4, offset: const Offset(1, 1)),
        ],
      ))
      ..addText(label);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: w - padding * 2));

    canvas.drawParagraph(
      paragraph,
      Offset(padding, h - fontSize * 2.2 + (fontSize * 2.2 - paragraph.height) / 2),
    );

    final picture = recorder.endRecording();
    final annotated = await picture.toImage(srcImage.width, srcImage.height);
    final byteData = await annotated.toByteData(format: ui.ImageByteFormat.png);
    final annotatedBytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'annotated_${p.basename(sourcePath)}');
    await File(outPath).writeAsBytes(annotatedBytes);
    return outPath;
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

        final photos = (photoValues[ik] ?? []).asMap().entries
            .where((e) => uploadedPhotoUrls.containsKey('$ik-${e.key}'))
            .map((e) => {'url': uploadedPhotoUrls['$ik-${e.key}']!, 'type': 'photo'})
            .toList();

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
          String uploadPath = path;
          final label = photoLabels['$ik-$pIdx'];
          if (label != null && label.isNotEmpty) {
            uploadPath = await _burnLabelOnImage(path, label);
          }
          final fileUrl = await _api.uploadPhoto(
            agencyId: item.agencyId,
            propertyId: item.propertyId,
            inspectionId: item.id,
            filePath: uploadPath,
          );
          uploaded['$ik-$pIdx'] = fileUrl;
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

class _QuickCaptureSheet extends StatelessWidget {
  final int count;
  const _QuickCaptureSheet({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            '$count photo${count == 1 ? '' : 's'} captured',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take another photo?',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 16),
                      SizedBox(width: 6),
                      Text('Next Shot'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
