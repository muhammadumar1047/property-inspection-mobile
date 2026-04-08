import 'dart:io';
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
          builder: (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(cond.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                Switch(
                  value: c.getBool(aIdx, iIdx, cIdx),
                  onChanged: (val) => c.setBool(aIdx, iIdx, cIdx, val),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Comments',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            TextButton.icon(
              onPressed: () => _showAddCommentDialog(aIdx, iIdx),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
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
      ],
    );
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
                IconButton(
                  onPressed: () => c.pickPhoto(aIdx, iIdx, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  style: IconButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
                IconButton(
                  onPressed: () => c.pickPhoto(aIdx, iIdx, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  style: IconButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
              ],
            ),
          ],
        ),
        if (photos.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (_, idx) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(photos[idx]),
                          width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => c.removePhoto(aIdx, iIdx, idx),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddCommentDialog(int aIdx, int iIdx) {
    String comment = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Add Comment',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter comment',
            hintStyle: const TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => comment = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              if (comment.trim().isNotEmpty) _ctrl.addComment(aIdx, iIdx, comment.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
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
