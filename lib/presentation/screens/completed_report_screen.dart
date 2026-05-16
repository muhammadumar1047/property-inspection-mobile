import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/completed_report_controller.dart';

class CompletedReportScreen extends GetView<CompletedReportController> {
  const CompletedReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 56),
                const SizedBox(height: 16),
                Text(controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
          slivers: [
            _buildHeroHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildInspectorCard(),
                    const SizedBox(height: 16),
                    _buildPropertyDetailsCard(),
                    if (controller.landlordSnapshots.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPeopleCard('Landlords', Icons.home_work_outlined,
                          controller.landlordSnapshots),
                    ],
                    if (controller.tenancySnapshots.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPeopleCard('Tenants', Icons.people_outline,
                          controller.tenancySnapshots),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      );
    });
  }

  Widget _buildHeroHeader() {
    final hasImage = controller.propertyImage.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Property image or gradient fallback
            if (hasImage)
              Image.network(
                controller.propertyImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _gradientFallback(),
              )
            else
              _gradientFallback(),
            // Dark overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            // Bottom content
            Positioned(
              left: 20, right: 20, bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.propertyAddress,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (controller.propertySuburb.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.propertySuburb}${controller.postcode.isNotEmpty ? '  ${controller.postcode}' : ''}',
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2E5BFF), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.home_work_rounded, color: Colors.white24, size: 80),
        ),
      );

  Widget _buildStatusRow() {
    return Row(
      children: [
        _badge(Icons.check_circle, 'Completed', Colors.green),
        const SizedBox(width: 8),
        _badge(Icons.category_outlined, controller.typeLabel, AppColors.primary),
        const Spacer(),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, color: AppColors.textHint, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text(controller.inspectionDate,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, color: AppColors.textHint, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text(controller.inspectionTime,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Inspection Info', Icons.info_outline),
          const SizedBox(height: 14),
          _infoRow(Icons.home_outlined, 'Property', controller.propertyAddress),
          if (controller.address2.isNotEmpty)
            _infoRow(Icons.location_city_outlined, 'Address 2', controller.address2),
          _infoRow(Icons.location_on_outlined, 'Suburb', controller.propertySuburb),
          if (controller.postcode.isNotEmpty)
            _infoRow(Icons.markunread_mailbox_outlined, 'Postcode', controller.postcode),
        ],
      ),
    );
  }

  Widget _buildInspectorCard() {
    final inspector = controller.inspector;
    final firstName = inspector?['firstName']?.toString() ?? '';
    final lastName = inspector?['lastName']?.toString() ?? '';
    final email = inspector?['email']?.toString() ?? '';
    final profileImage = inspector?['profileImage']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Inspector', Icons.person_outline),
          const SizedBox(height: 14),
          Row(
            children: [
              // Avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.gradient1, AppColors.gradient2],
                  ),
                ),
                child: profileImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(profileImage, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(fullName)),
                      )
                    : _avatarFallback(fullName),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName.isNotEmpty ? fullName : controller.inspectorName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(email,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';
    return Center(
      child: Text(initials.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPropertyDetailsCard() {
    final hasKey = controller.keyNo.isNotEmpty;
    final hasAlarm = controller.alarmCode.isNotEmpty;
    final hasNotes = controller.propertyNotes.isNotEmpty;
    if (!hasKey && !hasAlarm && !hasNotes) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Property Details', Icons.apartment_outlined),
          const SizedBox(height: 14),
          if (hasKey)
            _detailTile(Icons.vpn_key_outlined, 'Key No.', controller.keyNo,
                AppColors.warning),
          if (hasAlarm)
            _detailTile(Icons.security_outlined, 'Alarm Code', controller.alarmCode,
                AppColors.error),
          if (hasNotes) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(controller.propertyNotes,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPeopleCard(String title, IconData icon, List people) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 14),
          ...people.map((p) {
            final person = p as Map<String, dynamic>;
            final name = '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}'.trim();
            final email = person['email']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : 'Unknown',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _sectionTitle(String title, IconData icon) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.gradient1, AppColors.gradient2]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      );

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textHint),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
