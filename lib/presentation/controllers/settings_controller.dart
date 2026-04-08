import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final _storage = GetStorage();
  
  final RxBool notificationsEnabled = true.obs;
  final RxBool darkModeEnabled = false.obs;
  final RxBool autoSyncEnabled = true.obs;
  final RxString selectedLanguage = 'English'.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadSettings();
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