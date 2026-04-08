import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/storage_service.dart';
import '../controllers/auth_controller.dart';

class EditProfileController extends GetxController {
  final _storage = GetStorage();
  final _picker = ImagePicker();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final profileImagePath = RxnString();
  final isLoading = false.obs;
  final obscureCurrent = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Prefer live data from AuthController, fall back to StorageService cache
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value ?? await StorageService.getUser();
    if (user != null) {
      firstNameController.text = user.firstName;
      lastNameController.text = user.lastName;
      emailController.text = user.email;
      profileImagePath.value = user.profileImage ?? _storage.read('profileImage');
    } else {
      firstNameController.text = _storage.read('firstName') ?? '';
      lastNameController.text = _storage.read('lastName') ?? '';
      emailController.text = _storage.read('email') ?? '';
      profileImagePath.value = _storage.read('profileImage');
    }
  }

  Future<void> pickImage() async {
    final source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) profileImagePath.value = picked.path;
  }

  Future<void> saveProfile() async {
    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'First and last name are required',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    _storage.write('firstName', firstNameController.text.trim());
    _storage.write('lastName', lastNameController.text.trim());
    _storage.write('email', emailController.text.trim());
    if (profileImagePath.value != null) {
      _storage.write('profileImage', profileImagePath.value);
    }
    isLoading.value = false;
    Get.snackbar('Success', 'Profile updated successfully',
        backgroundColor: const Color(0xFF2E5BFF), colorText: Colors.white);
  }

  Future<void> updatePassword() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar('Error', 'All password fields are required',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar('Error', 'New passwords do not match',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    if (newPasswordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    Get.snackbar('Success', 'Password updated successfully',
        backgroundColor: const Color(0xFF2E5BFF), colorText: Colors.white);
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
