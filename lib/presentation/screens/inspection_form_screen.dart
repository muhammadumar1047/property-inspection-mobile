import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/report_template_model.dart';
import '../controllers/inspection_form_controller.dart';

class InspectionFormScreen extends StatefulWidget {
  const InspectionFormScreen({super.key});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedArea = 0;
  late InspectionFormController _ctrl;

  // inline comment input state: key = 'aIdx-iIdx'
  final Map<String, bool> _commentInputVisible = {};
  final Map<String, TextEditingController> _commentControllers = {};

  TextEditingController _commentCtrl(String ik) {
    _commentControllers[ik] ??= TextEditingController();
    return _commentControllers[ik]!;
  }

  void _toggleCommentInput(String ik, {String prefill = ''}) {
    setState(() {
      final wasVisible = _commentInputVisible[ik] == true;
      _commentInputVisible[ik] = !wasVisible;
      if (!wasVisible) {
        _commentCtrl(ik).text = prefill;
        _ctrl.filteredSuggestions.clear();
      } else {
        _ctrl.filteredSuggestions.clear();
      }
    });
  }

  void _submitInlineComment(String ik, int aIdx, int iIdx) {
    FocusScope.of(context).unfocus();
    final text = _commentCtrl(ik).text.trim();
    if (text.isNotEmpty) _ctrl.addComment(aIdx, iIdx, text);
    _commentCtrl(ik).clear();
    _ctrl.stopListening();
    _ctrl.filteredSuggestions.clear();
    setState(() => _commentInputVisible[ik] = false);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<InspectionFormController>();
    _tabController = TabController(length: 1, vsync: this);
    ever(_ctrl.template, (t) {
      if (t != null && mounted) {
        setState(() {
          _tabController.dispose();
          _tabController = TabController(length: t.reportAreas.length, vsync: this);
          _tabController.addListener(() {
            if (!_tabController.indexIsChanging) {
              setState(() => _selectedArea = _tabController.index);
            }
          });
          _selectedArea = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _commentControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar('Loading...'),
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      if (_ctrl.errorMessage.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar('Error'),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(_ctrl.errorMessage.value,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => Get.back(), child: const Text('Go Back')),
              ],
            ),
          ),
        );
      }
      final t = _ctrl.template.value;
      if (t == null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar('Inspection'),
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(t.reportType),
        body: Column(
          children: [
            _buildProgressBar(t),
            _buildTabBar(t),
            Expanded(child: _buildTabContent(t)),
          ],
        ),
        bottomNavigationBar: Obx(() => _buildBottomBar(t)),
      );
    });
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
      ),
      title: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          if (_ctrl.inspection.value != null)
            Text(
              _ctrl.inspection.value!.propertyAddress,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressBar(ReportTemplate t) {
    final total = t.reportAreas.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${_selectedArea + 1}/$total',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_selectedArea + 1) / total,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ReportTemplate t) {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        onTap: (i) => setState(() => _selectedArea = i),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: t.reportAreas.asMap().entries.map((e) {
          final isActive = _selectedArea == e.key;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(e.value.name, style: const TextStyle(fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(ReportTemplate t) {
    return TabBarView(
      controller: _tabController,
      children: t.reportAreas.asMap().entries.map((aEntry) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: aEntry.value.reportItems.length,
          itemBuilder: (_, iIdx) =>
              _buildItemCard(aEntry.key, iIdx, aEntry.value.reportItems[iIdx]),
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(int aIdx, int iIdx, ReportItem item) {
    return GetBuilder<InspectionFormController>(
      id: 'form',
      builder: (c) {
        final expanded = c.isExpanded(aIdx, iIdx);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => c.toggleExpanded(aIdx, iIdx),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.gradient1, AppColors.gradient2]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_box_outlined,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      Icon(
                        expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.reportItemConditions.isNotEmpty) ...[
                        _buildConditionsSection(aIdx, iIdx, item),
                        const SizedBox(height: 16),
                      ],
                      _buildCommentsSection(aIdx, iIdx, c),
                      const SizedBox(height: 16),
                      _buildPhotosSection(aIdx, iIdx, c),
                      if (c.isRoutineInspection) ...[
                        const SizedBox(height: 16),
                        _buildVideosSection(aIdx, iIdx, c),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConditionsSection(int aIdx, int iIdx, ReportItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Conditions',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...item.reportItemConditions.asMap().entries.map((e) =>
            _buildConditionField(aIdx, iIdx, e.key, e.value)),
      ],
    );
  }

  Widget _buildConditionField(int aIdx, int iIdx, int cIdx, ReportItemCondition cond) {
    switch (cond.type) {
      case 'boolean':
        return GetBuilder<InspectionFormController>(
          id: 'form',
          builder: (c) {
            final val = c.getBoolNullable(aIdx, iIdx, cIdx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(cond.description,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  _YNToggle(
                    value: val,
                    onChanged: (v) => c.setBoolNullable(aIdx, iIdx, cIdx, v),
                  ),
                ],
              ),
            );
          },
        );

      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cond.description,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: cond.value?.toString() ?? '',
                onChanged: (val) => _ctrl.setText(aIdx, iIdx, cIdx, val),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                maxLines: 2,
                decoration: _inputDecoration('Enter ${cond.description.toLowerCase()}'),
              ),
            ],
          ),
        );

      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cond.description,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: cond.value?.toString() ?? '',
                onChanged: (val) => _ctrl.setText(aIdx, iIdx, cIdx, val),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: _inputDecoration('0'),
              ),
            ],
          ),
        );

      case 'date':
        return GetBuilder<InspectionFormController>(
          id: 'form',
          builder: (c) {
            final val = c.getText(aIdx, iIdx, cIdx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(cond.description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              surface: AppColors.cardBg,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        c.setText(aIdx, iIdx, cIdx,
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                        c.update(['form']);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            val.isEmpty ? 'Select date' : val,
                            style: TextStyle(
                                fontSize: 12,
                                color: val.isEmpty ? AppColors.textHint : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary)),
      );

  Widget _buildCommentsSection(int aIdx, int iIdx, InspectionFormController c) {
    final comments = c.getComments(aIdx, iIdx);
    final ik = '$aIdx-$iIdx';
    final inputVisible = _commentInputVisible[ik] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Comments',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI button
                Obx(() {
                  final loading = c.isGeneratingAi[ik] == true;
                  return GestureDetector(
                    onTap: loading
                        ? null
                        : () async {
                            final t = c.template.value;
                            if (t == null) return;
                            final itemName = t.reportAreas[aIdx].reportItems[iIdx].name;
                            final suggestion = await c.generateAiComment(aIdx, iIdx, itemName);
                            if (suggestion != null) {
                              _commentCtrl(ik).text = suggestion;
                              if (_commentInputVisible[ik] != true) {
                                setState(() => _commentInputVisible[ik] = true);
                              }
                            }
                          },
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: loading
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)]),
                        color: loading ? AppColors.border : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('✨', style: TextStyle(fontSize: 11)),
                                SizedBox(width: 3),
                                Text('AI',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                    ),
                  );
                }),
                // Add / Cancel toggle
                TextButton.icon(
                  onPressed: () {
                    if (inputVisible) {
                      _ctrl.stopListening();
                      _ctrl.filteredSuggestions.clear();
                      _commentCtrl(ik).clear();
                      setState(() => _commentInputVisible[ik] = false);
                    } else {
                      _toggleCommentInput(ik);
                    }
                  },
                  icon: Icon(inputVisible ? Icons.close : Icons.add, size: 16),
                  label: Text(inputVisible ? 'Cancel' : 'Add',
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: inputVisible ? AppColors.error : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ],
        ),
        // Existing comments list
        ...comments.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                  GestureDetector(
                    onTap: () => c.removeComment(aIdx, iIdx, e.key),
                    child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )),
        // Inline input — shown below comments when Add is tapped
        if (inputVisible) ..._buildInlineCommentInput(ik, aIdx, iIdx),
      ],
    );
  }

  List<Widget> _buildInlineCommentInput(String ik, int aIdx, int iIdx) {
    return [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _commentCtrl(ik),
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              maxLines: 3,
              minLines: 1,
              onChanged: (val) => _ctrl.filterSuggestions(val),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                filled: true,
                fillColor: AppColors.cardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            // Suggestions
            Obx(() {
              final sugs = _ctrl.filteredSuggestions;
              if (sugs.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: sugs.map((s) => InkWell(
                    onTap: () {
                      _commentCtrl(ik).text = s;
                      _commentCtrl(ik).selection = TextSelection.fromPosition(
                          TextPosition(offset: s.length));
                      _ctrl.filteredSuggestions.clear();
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 13, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                // WhatsApp-style hold-to-record mic
                _VoiceMicButton(
                  textController: _commentCtrl(ik),
                  ctrl: _ctrl,
                  onStateChange: () => setState(() {}),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _submitInlineComment(ik, aIdx, iIdx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Add Comment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildPhotosSection(int aIdx, int iIdx, InspectionFormController c) {
    final photos = c.getPhotos(aIdx, iIdx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Photos',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Row(
              children: [
                GestureDetector(
                  onTap: () => c.quickCapture(aIdx, iIdx),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: Colors.white),
                        SizedBox(width: 3),
                        Text('Quick',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => c.pickPhoto(aIdx, iIdx, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  tooltip: 'Single photo',
                  style: IconButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
                IconButton(
                  onPressed: () => c.pickPhoto(aIdx, iIdx, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  tooltip: 'Pick multiple from gallery',
                  style: IconButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
                IconButton(
                  onPressed: () => c.captureSignature(aIdx, iIdx),
                  icon: const Icon(Icons.draw, size: 18),
                  tooltip: 'Draw signature',
                  style: IconButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
              ],
            ),
          ],
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (_, idx) {
                final label = c.getPhotoLabel(aIdx, iIdx, idx);
                return GestureDetector(
                  onTap: () => _showLabelEditor(aIdx, iIdx, idx, c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(photos[idx]),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Label badge on image
                            if (label.isNotEmpty)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xCC000000),
                                    borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(8)),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            // Edit label icon
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: label.isNotEmpty
                                      ? AppColors.primary
                                      : Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  label.isNotEmpty ? Icons.edit : Icons.label_outline,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Delete button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => c.removePhoto(aIdx, iIdx, idx),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label.isEmpty ? 'Tap to label' : label,
                          style: TextStyle(
                            fontSize: 9,
                            color: label.isEmpty
                                ? AppColors.textHint
                                : AppColors.primary,
                            fontWeight: label.isEmpty
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideosSection(int aIdx, int iIdx, InspectionFormController c) {
    final videos = c.getVideos(aIdx, iIdx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Videos',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            IconButton(
              onPressed: () => c.recordVideo(aIdx, iIdx),
              icon: const Icon(Icons.videocam, size: 20),
              tooltip: 'Record video',
              style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
            ),
          ],
        ),
        if (videos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            children: videos.asMap().entries.map((e) {
              final name = e.value.split('/').last;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.videocam,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Video ${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      name.length > 20
                          ? '...${name.substring(name.length - 16)}'
                          : name,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => c.removeVideo(aIdx, iIdx, e.key),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tap the camera icon to record a video',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint.withAlpha(180)),
            ),
          ),
      ],
    );
  }

  void _showLabelEditor(int aIdx, int iIdx, int photoIdx, InspectionFormController c) {
    final current = c.getPhotoLabel(aIdx, iIdx, photoIdx);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _LabelEditorSheet(
        initialLabel: current,
        photoPath: c.getPhotos(aIdx, iIdx)[photoIdx],
        onSave: (label) {
          c.setPhotoLabel(aIdx, iIdx, photoIdx, label);
          Navigator.pop(ctx);
        },
        onRemove: current.isNotEmpty
            ? () {
                c.setPhotoLabel(aIdx, iIdx, photoIdx, '');
                Navigator.pop(ctx);
              }
            : null,
      ),
    );
  }



  Widget _buildBottomBar(ReportTemplate t) {
    final total = t.reportAreas.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_selectedArea > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_selectedArea - 1);
                  setState(() => _selectedArea--);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _ctrl.isSubmitting.value ? null : () {
                if (_selectedArea == total - 1) {
                  _ctrl.submitInspection();
                } else {
                  _tabController.animateTo(_selectedArea + 1);
                  setState(() => _selectedArea++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _ctrl.isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _selectedArea == total - 1 ? 'Submit Report' : 'Next →',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Y / N toggle ────────────────────────────────────────────────────────────

class _YNToggle extends StatelessWidget {
  final bool? value; // true=Y, false=N, null=blank
  final void Function(bool?) onChanged;

  const _YNToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn('Y', true),
        const SizedBox(width: 6),
        _btn('N', false),
      ],
    );
  }

  Widget _btn(String label, bool btnVal) {
    final isSelected = value == btnVal;
    final color = btnVal ? AppColors.primary : AppColors.error;
    return GestureDetector(
      onTap: () {
        // Tap selected again → deselect (blank)
        onChanged(isSelected ? null : btnVal);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelEditorSheet extends StatefulWidget {
  final String initialLabel;
  final String photoPath;
  final void Function(String) onSave;
  final VoidCallback? onRemove;

  const _LabelEditorSheet({
    required this.initialLabel,
    required this.photoPath,
    required this.onSave,
    this.onRemove,
  });

  @override
  State<_LabelEditorSheet> createState() => _LabelEditorSheetState();
}

class _LabelEditorSheetState extends State<_LabelEditorSheet> {
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.label, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Photo Label',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (widget.onRemove != null)
                TextButton(
                  onPressed: widget.onRemove,
                  child: const Text('Remove',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(widget.photoPath),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tc,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Water damage, Crack in wall...',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              prefixIcon:
                  const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSave(_tc.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Label',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tap-to-start / tap-to-stop mic button ────────────────────────────────

class _VoiceMicButton extends StatefulWidget {
  final TextEditingController textController;
  final InspectionFormController ctrl;
  final VoidCallback onStateChange;

  const _VoiceMicButton({
    required this.textController,
    required this.ctrl,
    required this.onStateChange,
  });

  @override
  State<_VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<_VoiceMicButton> {
  Timer? _timer;
  Timer? _waveTimer;
  int _seconds = 0;
  final List<double> _bars = List.filled(5, 0.3);

  bool get _recording => widget.ctrl.isListening.value;

  void _toggle() {
    if (_recording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      final rng = Random();
      setState(() {
        for (var i = 0; i < _bars.length; i++) {
          _bars[i] = 0.2 + rng.nextDouble() * 0.8;
        }
      });
    });

    final baseText = widget.textController.text;
    widget.ctrl.startListening((partial) {
      if (!mounted) return;
      // Replace any previous partial with the latest recognised words
      final prefix = baseText.isEmpty ? '' : '$baseText ';
      widget.textController.text = '$prefix$partial';
      widget.textController.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.textController.text.length));
      widget.onStateChange();
    });
    setState(() {});
  }

  void _stopRecording() {
    _timer?.cancel();
    _waveTimer?.cancel();
    _timer = null;
    _waveTimer = null;
    widget.ctrl.stopListeningAndFlush();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveTimer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final recording = widget.ctrl.isListening.value;
      if (!recording) {
        return GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: const Icon(Icons.mic, color: AppColors.primary, size: 18),
          ),
        );
      }
      return GestureDetector(
        onTap: _toggle,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(20),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.red.withAlpha(100)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_bars.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3,
                  height: 6 + _bars[i] * 18,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
              const SizedBox(width: 8),
              Text(
                _timeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              const Text('Tap to stop',
                  style: TextStyle(fontSize: 10, color: Colors.red)),
            ],
          ),
        ),
      );
    });
  }
}
