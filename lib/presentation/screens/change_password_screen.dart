import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/edit_profile_controller.dart';

class ChangePasswordScreen extends GetView<EditProfileController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Obx(() => _buildPasswordField(
              'Current Password',
              controller.currentPasswordController,
              controller.obscureCurrent.value,
              () => controller.obscureCurrent.toggle(),
            )),
            const SizedBox(height: 16),
            Obx(() => _buildPasswordField(
              'New Password',
              controller.newPasswordController,
              controller.obscureNew.value,
              () => controller.obscureNew.toggle(),
            )),
            const SizedBox(height: 16),
            Obx(() => _buildPasswordField(
              'Confirm New Password',
              controller.confirmPasswordController,
              controller.obscureConfirm.value,
              () => controller.obscureConfirm.toggle(),
            )),
            const SizedBox(height: 32),
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        await controller.updatePassword();
                        if (!controller.isLoading.value) Get.back();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController textController,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: textController,
          obscureText: obscure,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 18),
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
