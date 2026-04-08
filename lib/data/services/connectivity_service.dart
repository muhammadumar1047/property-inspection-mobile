import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitial();
    Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _checkInitial() async {
    final result = await Connectivity().checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(List<ConnectivityResult> result) {
    isOnline.value = result.any((r) => r != ConnectivityResult.none);
    if (!isOnline.value) {
      Get.snackbar(
        'No Internet',
        'You are offline. Some features may be unavailable.',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
