import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 48),
                _buildTitle(),
                const SizedBox(height: 8),
                _buildSubtitle(),
                const SizedBox(height: 48),
                _buildSignInLabel(),
                const SizedBox(height: 24),
                _buildLoginForm(),
                const SizedBox(height: 40),
                // _buildCreateAccount(),
                // const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.home,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: 'Pro',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          TextSpan(
            text: 'Inspect',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Professional Property Inspections',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildSignInLabel() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'SIGN IN',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          _buildTextField(
            label: 'Email / Username',
            icon: Icons.person_outline,
            onChanged: (value) => controller.email.value = value,
          ),
          const SizedBox(height: 16),
          Obx(() => _buildTextField(
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: controller.obscurePassword.value,
            onChanged: (value) => controller.password.value = value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
          )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => CustomButton(
            buttonColor: AppColors.primary,
            title: 'LOGIN',
            textColor: AppColors.background,
            borderColor: Colors.transparent,
            onTap: controller.login,
            isLoading: controller.isLoading.value,
            gradient: const LinearGradient(
              colors: [AppColors.gradient1, AppColors.gradient2],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCreateAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New User? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
