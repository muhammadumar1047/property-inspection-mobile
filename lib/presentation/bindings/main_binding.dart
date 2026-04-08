import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/inspection_list_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/edit_profile_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<InspectionListController>(() => InspectionListController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}