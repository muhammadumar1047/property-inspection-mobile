import 'package:get/get.dart';
import '../controllers/inspection_list_controller.dart';

class InspectionListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InspectionListController());
  }
}
