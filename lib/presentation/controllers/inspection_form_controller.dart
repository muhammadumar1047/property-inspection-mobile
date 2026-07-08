import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/models/inspection_model.dart';
import '../../data/models/report_template_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';
import '../screens/quick_capture_screen.dart';

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
  final suggestions = <String>[].obs;
  // key: 'aIdx-iIdx' → filtered suggestions for that item's comment input
  final filteredSuggestions = <String, RxList<String>>{};

  Future<void> fetchSuggestions() async {
    final item = inspection.value;
    if (item == null) return;
    try {
      final type = (item.inspectionType == 1 || item.inspectionType == 2) ? 1 : 2;
      final response = await _api.getQuickSuggestions(agencyId: item.agencyId, type: type);
      print('QuickSuggestions response: ${response.data}');
      if (response.data['success'] == true) {
        final raw = response.data['data'];
        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map && raw['data'] is List ? raw['data'] as List : []);
        // Try common key names: suggestion, text, comment, name, value
        suggestions.assignAll(
          data.map((e) {
            if (e is Map) {
              return (e['suggestion'] ?? e['text'] ?? e['comment'] ?? e['name'] ?? e['value'] ?? '').toString();
            }
            return e.toString();
          }).where((s) => s.isNotEmpty),
        );
        print('Loaded ${suggestions.length} suggestions');
      }
    } catch (e) {
      print('fetchSuggestions error: $e');
    }
  }

  void filterSuggestions(String ik, String query) {
    filteredSuggestions[ik] ??= <String>[].obs;
    if (query.trim().isEmpty) {
      filteredSuggestions[ik]!.clear();
      return;
    }
    filteredSuggestions[ik]!.assignAll(
      suggestions.where((s) => s.toLowerCase().contains(query.toLowerCase())).take(5),
    );
  }

  RxList<String> getSuggestions(String ik) {
    filteredSuggestions[ik] ??= <String>[].obs;
    return filteredSuggestions[ik]!;
  }

  void clearSuggestions(String ik) {
    filteredSuggestions[ik]?.clear();
  }
  // key: 'areaIdx-itemIdx' → List<String> (local paths or uploaded URLs)
  final Map<String, List<String>> photoValues = {};
  // key: 'areaIdx-itemIdx-photoIdx' → label text
  final Map<String, String> photoLabels = {};
  // key: 'areaIdx-itemIdx' → List<String> (local paths or uploaded URLs)
  final Map<String, List<String>> videoValues = {};
  // key: 'areaIdx-itemIdx' → bool
  final Map<String, bool> expandedState = {};

  bool get isRoutineInspection => inspection.value?.inspectionType == 3;

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
      // Always try network first
      if (_connectivity.isOnline.value) {
        final response = await _api.getReportTemplate(item.id, isEntryExit: item.inspectionType == 1 || item.inspectionType == 2);
        if (response.data['success'] == true) {
          // Cache the raw response for offline use
          await StorageService.saveTemplate(item.id, response.data as Map<String, dynamic>);
          final parsed = ReportTemplateResponse.fromJson(response.data);
          template.value = parsed.data;
          _initFormState(parsed.data);
          // Restore any in-progress draft on top of the fresh template
          await _restoreDraft();
          fetchSuggestions();
          return;
        } else {
          errorMessage.value = response.data['message'] ?? 'Failed to load template';
          return;
        }
      }
      // Offline: load from cache
      final cached = await StorageService.getCachedTemplate(item.id);
      if (cached != null) {
        final parsed = ReportTemplateResponse.fromJson(cached);
        template.value = parsed.data;
        _initFormState(parsed.data);
        // Restore draft on top of fresh init
        await _restoreDraft();
      } else {
        errorMessage.value = 'No internet connection and no cached template found.';
      }
    } catch (e) {
      if (e.toString().contains('TickerProvider') || e.toString().contains('Ticker')) rethrow;
      // Network failed — try cache
      final cached = await StorageService.getCachedTemplate(item.id);
      if (cached != null) {
        final parsed = ReportTemplateResponse.fromJson(cached);
        template.value = parsed.data;
        _initFormState(parsed.data);
        await _restoreDraft();
      } else {
        errorMessage.value = 'Failed to load inspection template. Please connect to the internet.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _initFormState(ReportTemplate t) {
    conditionValues.clear();
    commentValues.clear();
    photoValues.clear();
    photoLabels.clear();
    videoValues.clear();
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
        videoValues[ik] = [];
        for (var cIdx = 0; cIdx < item.reportItemConditions.length; cIdx++) {
          final cond = item.reportItemConditions[cIdx];
          conditionValues[_ck(aIdx, iIdx, cIdx)] = cond.type == 'boolean'
              ? (cond.value == true || cond.value == 'true'
                  ? true
                  : cond.value == false || cond.value == 'false'
                      ? false
                      : null) // null = blank/unset
              : (cond.value?.toString() ?? '');
        }
      }
    }
    // After populating from template, restore any saved draft on top
    // (called via _restoreDraft separately after online fetch too)
  }

  // ─── Draft persistence ────────────────────────────────────────────────────

  Future<void> _restoreDraft() async {
    final id = inspection.value?.id;
    if (id == null) return;
    final draft = await StorageService.getDraft(id);
    if (draft == null) return;

    // Restore condition values
    final conds = draft['conditions'] as Map<String, dynamic>? ?? {};
    conds.forEach((k, v) => conditionValues[k] = v);

    // Restore comments
    final comments = draft['comments'] as Map<String, dynamic>? ?? {};
    comments.forEach((k, v) {
      commentValues[k] = (v as List).cast<String>();
    });

    // Restore photo paths (only local paths that still exist on disk)
    final photos = draft['photos'] as Map<String, dynamic>? ?? {};
    photos.forEach((k, v) {
      final paths = (v as List).cast<String>();
      photoValues[k] = paths.where((p) => p.startsWith('http') || File(p).existsSync()).toList();
    });

    // Restore labels
    final labels = draft['labels'] as Map<String, dynamic>? ?? {};
    labels.forEach((k, v) => photoLabels[k] = v.toString());

    // Restore video paths
    final videos = draft['videos'] as Map<String, dynamic>? ?? {};
    videos.forEach((k, v) {
      final paths = (v as List).cast<String>();
      videoValues[k] = paths.where((p) => p.startsWith('http') || File(p).existsSync()).toList();
    });

    update(['form']);
  }

  Future<void> _saveDraft() async {
    final id = inspection.value?.id;
    if (id == null) return;
    await StorageService.saveDraft(id, {
      'conditions': Map<String, dynamic>.from(conditionValues),
      'comments': commentValues.map((k, v) => MapEntry(k, List<String>.from(v))),
      'photos': photoValues.map((k, v) => MapEntry(k, List<String>.from(v))),
      'labels': Map<String, String>.from(photoLabels),
      'videos': videoValues.map((k, v) => MapEntry(k, List<String>.from(v))),
    });
  }

  bool getBool(int a, int i, int c) => conditionValues[_ck(a, i, c)] == true;
  bool? getBoolNullable(int a, int i, int c) {
    final v = conditionValues[_ck(a, i, c)];
    if (v == null) return null;
    if (v == true || v == 'true') return true;
    if (v == false || v == 'false') return false;
    return null;
  }

  String getText(int a, int i, int c) => conditionValues[_ck(a, i, c)]?.toString() ?? '';

  void setBool(int a, int i, int c, bool val) {
    conditionValues[_ck(a, i, c)] = val;
    update(['form']);
    _saveDraft();
  }

  void setBoolNullable(int a, int i, int c, bool? val) {
    conditionValues[_ck(a, i, c)] = val;
    update(['form']);
    _saveDraft();
  }

  void setText(int a, int i, int c, String val) {
    conditionValues[_ck(a, i, c)] = val;
    _saveDraft();
  }

  List<String> getComments(int a, int i) => commentValues[_ik(a, i)] ?? [];

  void addComment(int a, int i, String text) {
    commentValues[_ik(a, i)] ??= [];
    commentValues[_ik(a, i)]!.add(text);
    update(['form']);
    _saveDraft();
  }

  void removeComment(int a, int i, int idx) {
    commentValues[_ik(a, i)]?.removeAt(idx);
    update(['form']);
    _saveDraft();
  }

  List<String> getPhotos(int a, int i) => photoValues[_ik(a, i)] ?? [];

  Future<void> pickPhoto(int a, int i, ImageSource source) async {
    if (source == ImageSource.gallery) {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isNotEmpty) {
        photoValues[_ik(a, i)] ??= [];
        photoValues[_ik(a, i)]!.addAll(files.map((f) => f.path));
        update(['form']);
        _saveDraft();
      }
    } else {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        photoValues[_ik(a, i)] ??= [];
        photoValues[_ik(a, i)]!.add(file.path);
        update(['form']);
        _saveDraft();
      }
    }
  }

  /// Quick capture: opens a live camera screen, user taps to capture multiple
  /// photos one after another. All captured photos are added instantly on Done.
  Future<void> quickCapture(int a, int i) async {
    final result = await Get.to<List<String>>(() => const QuickCaptureScreen());
    if (result == null || result.isEmpty) return;
    photoValues[_ik(a, i)] ??= [];
    photoValues[_ik(a, i)]!.addAll(result);
    update(['form']);
    _saveDraft();
  }

  bool _speechInitialized = false;

  // ─── Voice to Text ────────────────────────────────────────────────────────

  String _lastPartialWords = '';

  Future<void> startListening(void Function(String) onPartialResult) async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onError: (e) => isListening.value = false,
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
        'Speech recognition is not available on this device.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }
    if (_speech.isListening) await _speech.stop();
    _lastPartialWords = '';
    isListening.value = true;
    await _speech.listen(
      onResult: (r) {
        _lastPartialWords = r.recognizedWords;
        // Stream every partial result live into the text field
        if (r.recognizedWords.isNotEmpty) {
          onPartialResult(r.recognizedWords);
        }
        if (r.finalResult) {
          isListening.value = false;
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 8),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Stops listening and returns the last accumulated text.
  String stopListeningAndFlush() {
    final words = _lastPartialWords;
    _lastPartialWords = '';
    if (_speech.isListening) _speech.stop();
    isListening.value = false;
    return words;
  }

  void stopListening() {
    _lastPartialWords = '';
    if (_speech.isListening) _speech.stop();
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

  List<String> getVideos(int a, int i) => videoValues[_ik(a, i)] ?? [];

  Future<void> recordVideo(int a, int i) async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null) return;
    videoValues[_ik(a, i)] ??= [];
    videoValues[_ik(a, i)]!.add(file.path);
    update(['form']);
    _saveDraft();
  }

  void removeVideo(int a, int i, int idx) {
    videoValues[_ik(a, i)]?.removeAt(idx);
    update(['form']);
    _saveDraft();
  }

  /// Opens the signature pad sheet and saves the result as a photo entry.
  Future<void> captureSignature(int a, int i) async {
    final signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    final confirmed = await Get.bottomSheet<bool>(
      _SignaturePadSheet(controller: signatureController),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (confirmed != true) {
      signatureController.dispose();
      return;
    }

    final bytes = await signatureController.toPngBytes();
    signatureController.dispose();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'signature_${DateTime.now().millisecondsSinceEpoch}.png'));
    await file.writeAsBytes(bytes);

    photoValues[_ik(a, i)] ??= [];
    photoValues[_ik(a, i)]!.add(file.path);
    final idx = photoValues[_ik(a, i)]!.length - 1;
    photoLabels['${_ik(a, i)}-$idx'] = 'Signature';
    update(['form']);
    _saveDraft();
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
    _saveDraft();
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
    _saveDraft();
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
            // Keep null as null — only coerce actual true/false
            if (value == true || value == 'true') {
              value = true;
            } else if (value == false || value == 'false') {
              value = false;
            } else {
              value = null;
            }
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
            .where((e) => uploadedPhotoUrls.containsKey('photo-$ik-${e.key}'))
            .map((e) => {'url': uploadedPhotoUrls['photo-$ik-${e.key}']!, 'type': 'photo'})
            .toList();

        final videos = (videoValues[ik] ?? []).asMap().entries
            .where((e) => uploadedPhotoUrls.containsKey('video-$ik-${e.key}'))
            .map((e) => {'url': uploadedPhotoUrls['video-$ik-${e.key}']!, 'type': 'video'})
            .toList();

        final allMedia = [...photos, ...videos];

        return {
          'name': ri.name,
          'reportItemConditions': conditions,
          'reportItemComments': comments,
          'reportMedia': allMedia,
        };
      }).toList();

      return {'name': area.name, 'reportItems': reportItems};
    }).toList();

    return {
      'agencyId': item.agencyId,
      'inspectionId': item.id,
      'inspectionType': item.inspectionType,
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

        // Upload photos
        final photos = photoValues[ik] ?? [];
        for (var pIdx = 0; pIdx < photos.length; pIdx++) {
          final path = photos[pIdx];
          if (path.startsWith('http')) {
            uploaded['photo-$ik-$pIdx'] = path;
            continue;
          }
          String uploadPath = path;
          final label = photoLabels['$ik-$pIdx'];
          if (label != null && label.isNotEmpty) {
            uploadPath = await _burnLabelOnImage(path, label);
          }
          final fileUrl = await _api.uploadMedia(
            agencyId: item.agencyId,
            propertyId: item.propertyId,
            inspectionId: item.id,
            filePath: uploadPath,
          );
          uploaded['photo-$ik-$pIdx'] = fileUrl;
        }

        // Upload videos (only present for Routine inspections)
        final videos = videoValues[ik] ?? [];
        for (var vIdx = 0; vIdx < videos.length; vIdx++) {
          final path = videos[vIdx];
          if (path.startsWith('http')) {
            uploaded['video-$ik-$vIdx'] = path;
            continue;
          }
          final fileUrl = await _api.uploadMedia(
            agencyId: item.agencyId,
            propertyId: item.propertyId,
            inspectionId: item.id,
            filePath: path,
            isVideo: true,
          );
          uploaded['video-$ik-$vIdx'] = fileUrl;
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
        await StorageService.clearDraft(inspection.value!.id);
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

      final response = isRoutineInspection
          ? await _api.syncRoutineReport(payload)
          : await _api.syncReport(payload);
      if (response.data['success'] == true || response.statusCode == 200) {
        await StorageService.clearDraft(inspection.value!.id);
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
        final isRoutine = pending[i]['inspectionType'] == 3;
        final response = isRoutine
            ? await _api.syncRoutineReport(pending[i])
            : await _api.syncReport(pending[i]);
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

class _SignaturePadSheet extends StatefulWidget {
  final SignatureController controller;
  const _SignaturePadSheet({required this.controller});

  @override
  State<_SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<_SignaturePadSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.draw, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Draw Signature',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => widget.controller.clear(),
                child: const Text('Clear',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Signature(
                controller: widget.controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in the box above',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
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
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (widget.controller.isEmpty) {
                      Get.snackbar(
                        'Empty Signature',
                        'Please draw your signature first.',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Signature'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
