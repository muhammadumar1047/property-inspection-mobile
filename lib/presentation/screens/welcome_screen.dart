import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight.withOpacity(0.3),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                _build3DIcon(),
                const SizedBox(height: 48),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildSubtitle(),
                const Spacer(),
                CustomButton(
                  buttonColor: AppColors.primary,
                  title: 'GET STARTED',
                  textColor: Colors.white,
                  borderColor: Colors.transparent,
                  onTap: () => Get.toNamed('/login'),
                  icon: Icons.arrow_forward,
                  gradient: const LinearGradient(
                    colors: [AppColors.gradient1, AppColors.gradient2],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DIcon() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icon(Icons.home_work_rounded, size: 120, color: AppColors.primary),
          Image.asset("assets/images/inspectLogo.png", width: 130, height: 130),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        children: [
          TextSpan(text: 'Welcome to\n'),
          TextSpan(
            text: 'EaseInspect ',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Professional property inspections\nat your fingertip',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}
