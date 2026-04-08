import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/inspection_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/storage_service.dart';

class InspectionListController extends GetxController {
  final _api = ApiService();

  final isMapView = false.obs;
  final isLoading = false.obs;
  final isOffline = false.obs;
  var markers = <Marker>[].obs;
  GoogleMapController? mapController;

  final inspections = <InspectionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInspections();
  }

  Future<void> loadInspections() async {
    isLoading.value = true;
    final connectivity = Get.find<ConnectivityService>();

    if (connectivity.isOnline.value) {
      try {
        final response = await _api.getInspections();
        if (response.data['success'] == true) {
          final parsed = InspectionListResponse.fromJson(response.data);
          inspections.assignAll(parsed.data.data);
          await StorageService.saveInspections(parsed.data.data);
          isOffline.value = false;
        }
      } catch (_) {
        await _loadFromCache();
      }
    } else {
      await _loadFromCache();
    }

    setupMarkers();
    isLoading.value = false;
  }

  Future<void> _loadFromCache() async {
    final cached = await StorageService.getCachedInspections();
    inspections.assignAll(cached);
    isOffline.value = true;
  }

  void toggleView() {
    isMapView.value = !isMapView.value;
  }

  final selectedInspection = Rxn<InspectionModel>();

  void setupMarkers() {
    markers.clear();
    for (var inspection in inspections) {
      final lat = inspection.property?.latitude;
      final lng = inspection.property?.longitude;
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      markers.add(
        Marker(
          markerId: MarkerId(inspection.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: inspection.propertyAddress,
            snippet: '${inspection.typeLabel} · ${inspection.statusLabel}',
          ),
          onTap: () => selectedInspection.value = inspection,
        ),
      );
    }
    // Auto-select first valid inspection for the bottom card
    if (markers.isNotEmpty && selectedInspection.value == null) {
      selectedInspection.value = inspections.firstWhere(
        (i) => i.property?.latitude != null && i.property?.longitude != null &&
               !(i.property!.latitude == 0 && i.property!.longitude == 0),
        orElse: () => inspections.first,
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
}
