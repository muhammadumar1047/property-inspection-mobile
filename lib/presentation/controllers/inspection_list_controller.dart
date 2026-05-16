import 'package:flutter/material.dart';
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
  late final PageController pageController;

  final inspections = <InspectionModel>[].obs;
  final selectedIndex = 0.obs;
  final selectedType = RxnInt();   // null=All, 1=Entry, 2=Exit, 3=Routine
  final selectedDate = Rxn<DateTime>();

  List<InspectionModel> get filteredInspections {
    var list = inspections.toList();
    if (selectedType.value != null) {
      list = list.where((i) => i.inspectionType == selectedType.value).toList();
    }
    if (selectedDate.value != null) {
      final d = selectedDate.value!;
      list = list.where((i) {
        final parsed = DateTime.tryParse(i.inspectionDate);
        return parsed != null &&
            parsed.year == d.year &&
            parsed.month == d.month &&
            parsed.day == d.day;
      }).toList();
    }
    return list;
  }

  void setTypeFilter(int? type) => selectedType.value = type;

  void setDateFilter(DateTime? date) => selectedDate.value = date;

  // All inspections shown in the card strip
  // Only inspections with valid coords get markers
  List<InspectionModel> get mappableInspections => inspections.toList();

  List<InspectionModel> get inspectionsWithCoords => inspections
      .where(
        (i) =>
            i.property?.latitude != null &&
            i.property?.longitude != null &&
            !(i.property!.latitude == 0 && i.property!.longitude == 0),
      )
      .toList();

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(viewportFraction: 0.88);
    loadInspections();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
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

  void toggleView() => isMapView.value = !isMapView.value;

  // Called when user swipes the horizontal card list
  void onPageChanged(int index) {
    selectedIndex.value = index;
    _animateCameraToIndex(index);
    _refreshMarkers(index);
  }

  // Called when user taps a map marker
  void onMarkerTapped(int index) {
    selectedIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _animateCameraToIndex(index);
    _refreshMarkers(index);
  }

  void _animateCameraToIndex(int index) {
    final list = mappableInspections;
    if (index >= list.length) return;
    final lat = list[index].property?.latitude;
    final lng = list[index].property?.longitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return;
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15),
      ),
    );
  }

  void _refreshMarkers(int selectedIdx) {
    final allList = mappableInspections;
    markers.value = allList
        .asMap()
        .entries
        .where((e) {
          final p = e.value.property;
          return p?.latitude != null &&
              p?.longitude != null &&
              !(p!.latitude == 0 && p.longitude == 0);
        })
        .map((e) {
          final i = e.key;
          final inspection = e.value;
          return Marker(
            markerId: MarkerId(inspection.id),
            position: LatLng(
              inspection.property!.latitude!,
              inspection.property!.longitude!,
            ),
            icon: i == selectedIdx
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  )
                : BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: inspection.propertyAddress,
              snippet: '${inspection.typeLabel} · ${inspection.statusLabel}',
            ),
            onTap: () => onMarkerTapped(i),
          );
        })
        .toList();
  }

  void setupMarkers() => _refreshMarkers(selectedIndex.value);

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (inspectionsWithCoords.isNotEmpty) {
      final first = inspectionsWithCoords.first;
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              first.property!.latitude!,
              first.property!.longitude!,
            ),
            zoom: 14,
          ),
        ),
      );
    }
  }

  // Kept for backward compat
  final selectedInspection = Rxn<InspectionModel>();
}
