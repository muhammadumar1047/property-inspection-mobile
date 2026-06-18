import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/login_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  ConnectivityService get _connectivity => Get.find<ConnectivityService>();

  final email = ''.obs;
  final password = ''.obs;
  final obscurePassword = true.obs;
  final isLoading = false.obs;
  final isForgotLoading = false.obs;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final token = ''.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    isLoading.value = true;

    // Offline: restore from local storage
    if (!_connectivity.isOnline.value) {
      final savedToken = await StorageService.getToken();
      final savedUser = await StorageService.getUser();

      if (savedToken != null && savedUser != null) {
        token.value = savedToken;
        currentUser.value = savedUser;
        Get.snackbar('Offline Mode', 'Logged in using saved session');
        Get.offAllNamed('/main');
      } else {
        Get.snackbar('No Internet', 'Please connect to the internet to login');
      }
      isLoading.value = false;
      return;
    }

    // Online: call API
    try {
      final response = await _apiService.login(email.value, password.value);
      final loginResponse = LoginResponse.fromJson(response.data);

      if (loginResponse.success) {
        token.value = loginResponse.data.token;
        currentUser.value = loginResponse.data.user;
        await StorageService.saveSession(token.value, currentUser.value!);
        Get.offAllNamed('/main');
      } else {
        Get.snackbar('Error', loginResponse.message);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
      Get.snackbar('Error', message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter your email address',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isForgotLoading.value = true;
    try {
      final response = await _apiService.forgotPassword(email.trim());
      final success = response.data['success'] == true;
      final message = response.data['message']?.toString() ??
          (success ? 'Reset link sent to your email.' : 'Request failed.');
      Get.snackbar(
        success ? 'Email Sent' : 'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: success ? Colors.green : Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return success;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
      Get.snackbar('Error', msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isForgotLoading.value = false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    token.value = '';
    currentUser.value = null;
    email.value = '';
    password.value = '';
    Get.offAllNamed('/login');
  }

  /// Fetches fresh user data from API using saved token.
  /// Returns updated UserModel on success, null on failure.
  Future<UserModel?> fetchCurrentUser(String savedToken) async {
    try {
      print("saved token is: ${savedToken}");
      final response = await _apiService.getProfile(token: savedToken);
      print('fetchCurrentUser status: ${response.statusCode}');
      print('fetchCurrentUser body: ${response.data}');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final user = UserModel.fromJson(data is Map ? data : response.data);
        return user;
      }
    } on DioException catch (e) {
      print('fetchCurrentUser DioException: ${e.response?.statusCode} ${e.response?.data}');
      // 401 = token expired/invalid → return null to force re-login
      if (e.response?.statusCode == 401) return null;
      // Any other network error → rethrow so splash falls back to cache
      rethrow;
    } catch (e) {
      print('fetchCurrentUser error: $e');
      rethrow;
    }
    return null;
  }
}
