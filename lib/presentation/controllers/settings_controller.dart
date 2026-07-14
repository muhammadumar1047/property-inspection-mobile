import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import 'auth_controller.dart';

class SettingsController extends GetxController {
  final _storage = GetStorage();
  final _api = ApiService();

  final RxBool notificationsEnabled = true.obs;
  final RxBool darkModeEnabled = false.obs;
  final RxBool autoSyncEnabled = true.obs;
  final RxString selectedLanguage = 'English'.obs;

  final firstName = ''.obs;
  final lastName = ''.obs;
  final email = ''.obs;
  final profileImage = RxnString();

  String get fullName {
    final f = firstName.value.trim();
    final l = lastName.value.trim();
    if (f.isEmpty && l.isEmpty) return 'User';
    return '$f $l'.trim();
  }

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    loadProfile();
  }

  Future<void> loadProfile() async {
    // First load from cache so UI shows immediately
    _loadFromCache();
    // Then fetch fresh from API
    try {
      final response = await _api.getProfile();
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        firstName.value = data['firstName']?.toString() ?? '';
        lastName.value = data['lastName']?.toString() ?? '';
        email.value = data['email']?.toString() ?? '';
        profileImage.value = data['profileImage']?.toString();
        // Persist to cache
        _storage.write('firstName', firstName.value);
        _storage.write('lastName', lastName.value);
        _storage.write('email', email.value);
        _storage.write('profileImageUrl', profileImage.value);
        // Keep AuthController in sync
        final auth = Get.find<AuthController>();
        final saved = await StorageService.getUser();
        if (saved != null) await StorageService.saveSession(
          await StorageService.getToken() ?? '',
          saved,
        );
        auth.currentUser.refresh();
      }
    } catch (_) {
      // API failed — cached values already shown
    }
  }

  void _loadFromCache() {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    firstName.value = _storage.read('firstName') ?? user?.firstName ?? '';
    lastName.value = _storage.read('lastName') ?? user?.lastName ?? '';
    email.value = _storage.read('email') ?? user?.email ?? '';
    profileImage.value = _storage.read('profileImageUrl') ?? _storage.read('profileImage') ?? user?.profileImage;
  }
  
  void loadSettings() {
    notificationsEnabled.value = _storage.read('notifications') ?? true;
    darkModeEnabled.value = _storage.read('darkMode') ?? false;
    autoSyncEnabled.value = _storage.read('autoSync') ?? true;
    selectedLanguage.value = _storage.read('language') ?? 'English';
  }
  
  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    _storage.write('notifications', value);
  }
  
  void toggleDarkMode(bool value) {
    darkModeEnabled.value = value;
    _storage.write('darkMode', value);
  }
  
  void toggleAutoSync(bool value) {
    autoSyncEnabled.value = value;
    _storage.write('autoSync', value);
  }
  
  void changeLanguage(String language) {
    selectedLanguage.value = language;
    _storage.write('language', language);
  }
  
  void logout() {
    _storage.erase();
    Get.offAllNamed('/login');
  }
}