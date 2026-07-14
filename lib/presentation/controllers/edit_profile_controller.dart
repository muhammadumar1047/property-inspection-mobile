import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../controllers/auth_controller.dart';

class EditProfileController extends GetxController {
  final _storage = GetStorage();
  final _picker = ImagePicker();
  final _api = ApiService();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final profileImagePath = RxnString();   // local file path (just picked)
  final profileImageUrl = RxnString();    // remote URL from API
  final isLoading = false.obs;
  final isUploadingPhoto = false.obs;
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
      profileImageUrl.value = user.profileImage ?? _storage.read('profileImageUrl');
    } else {
      firstNameController.text = _storage.read('firstName') ?? '';
      lastNameController.text = _storage.read('lastName') ?? '';
      emailController.text = _storage.read('email') ?? '';
      profileImageUrl.value = _storage.read('profileImageUrl');
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
    if (picked == null) return;

    profileImagePath.value = picked.path; // show local preview immediately
    await _uploadProfilePhoto(picked.path);
  }

  Future<void> _uploadProfilePhoto(String filePath) async {
    isUploadingPhoto.value = true;
    try {
      // Step 1: get pre-signed upload URL
      print('[PhotoUpload] Step 1: getting pre-signed URL...');
      final fileName = filePath.split('/').last;
      final urlRes = await _api.getProfilePhotoUploadUrl(fileName);
      print('[PhotoUpload] Step 1 status: ${urlRes.statusCode}');
      print('[PhotoUpload] Step 1 body: ${urlRes.data}');
      if ((urlRes.statusCode ?? 0) >= 400) {
        throw Exception('Step 1 failed ${urlRes.statusCode}: ${urlRes.data}');
      }
      final urlData = urlRes.data['data'] as Map<String, dynamic>? ?? urlRes.data as Map<String, dynamic>;
      final uploadUrl = urlData['preSignedUrl']?.toString() ?? urlData['uploadUrl']?.toString() ?? urlData['upload_url']?.toString() ?? '';
      final fileKey = urlData['fileKey']?.toString() ?? urlData['file_key']?.toString() ?? '';
      print('[PhotoUpload] uploadUrl: $uploadUrl');
      print('[PhotoUpload] fileKey: $fileKey');
      if (uploadUrl.isEmpty) throw Exception('No uploadUrl returned');

      // Step 2a: PUT file bytes directly to S3
      final ext = filePath.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final bytes = await File(filePath).readAsBytes();
      print('[PhotoUpload] Step 2a: uploading ${bytes.length} bytes to S3, contentType: $contentType');
      await _api.s3Put(uploadUrl, bytes, contentType);
      print('[PhotoUpload] Step 2a: S3 upload success');

      // Step 2b: save fileKey against profile
      print('[PhotoUpload] Step 2b: saving fileKey: $fileKey');
      final saveRes = await _api.saveProfilePhoto(fileKey);
      print('[PhotoUpload] Step 2b response: ${saveRes.statusCode} ${saveRes.data}');
      if (saveRes.data['success'] == true) {
        final newUrl = (saveRes.data['data'] as Map<String, dynamic>?)?['profileImage']?.toString();
        if (newUrl != null) {
          profileImageUrl.value = newUrl;
          _storage.write('profileImageUrl', newUrl);
        }
        await _refreshProfileImage();
        Get.snackbar('Success', 'Profile photo updated',
            backgroundColor: const Color(0xFF2E5BFF), colorText: Colors.white);
      } else {
        final msg = saveRes.data['message']?.toString() ?? 'Failed to save photo';
        print('[PhotoUpload] Step 2b failed: $msg');
        Get.snackbar('Error', msg,
            backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      }
    } catch (e, st) {
      print('[PhotoUpload] ERROR: $e');
      if (e is DioException) {
        print('[PhotoUpload] Response body: ${e.response?.data}');
        print('[PhotoUpload] Request path: ${e.requestOptions.path}');
        print('[PhotoUpload] Request query: ${e.requestOptions.queryParameters}');
      }
      print('[PhotoUpload] STACKTRACE: $st');
      Get.snackbar('Error', 'Failed to upload photo: ${e.toString()}',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<void> _refreshProfileImage() async {
    try {
      final res = await _api.getProfile();
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>? ?? {};
        final url = data['profileImage']?.toString();
        if (url != null) {
          profileImageUrl.value = url;
          profileImagePath.value = null; // clear local path, use remote URL
          _storage.write('profileImageUrl', url);
          // Sync to AuthController
          final auth = Get.find<AuthController>();
          auth.currentUser.refresh();
        }
      }
    } catch (_) {}
  }

  Future<void> saveProfile() async {
    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'First and last name are required',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      final response = await _api.updateProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );
      if (response.data['success'] == true) {
        // Persist locally
        _storage.write('firstName', firstNameController.text.trim());
        _storage.write('lastName', lastNameController.text.trim());
        if (profileImageUrl.value != null) {
          _storage.write('profileImageUrl', profileImageUrl.value);
        }
        // Keep AuthController in sync
        final auth = Get.find<AuthController>();
        auth.currentUser.refresh();
        Get.snackbar('Success', 'Profile updated successfully',
            backgroundColor: const Color(0xFF2E5BFF), colorText: Colors.white);
      } else {
        final msg = response.data['message']?.toString() ?? 'Update failed';
        Get.snackbar('Error', msg,
            backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword() async {
    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      Get.snackbar('Error', 'All password fields are required',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    if (newPass != confirm) {
      Get.snackbar('Error', 'New passwords do not match',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    if (newPass.length < 8) {
      Get.snackbar('Error', 'Password must be at least 8 characters',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    if (!newPass.contains(RegExp(r'[A-Z]'))) {
      Get.snackbar('Error', 'Password must contain at least one uppercase letter',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }
    if (!newPass.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      Get.snackbar('Error', 'Password must contain at least one special character',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      if (response.data['success'] == true) {
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        Get.snackbar('Success', 'Password updated successfully',
            backgroundColor: const Color(0xFF2E5BFF), colorText: Colors.white);
      } else {
        final msg = response.data['message']?.toString() ?? 'Update failed';
        Get.snackbar('Error', msg,
            backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update password',
          backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
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
