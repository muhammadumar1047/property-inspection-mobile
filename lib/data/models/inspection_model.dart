class InspectionListResponse {
  final bool success;
  final InspectionPageData data;

  InspectionListResponse({required this.success, required this.data});

  factory InspectionListResponse.fromJson(Map<String, dynamic> json) =>
      InspectionListResponse(
        success: json['success'],
        data: InspectionPageData.fromJson(json['data']),
      );
}

class InspectionPageData {
  final List<InspectionModel> data;
  final int totalCount;

  InspectionPageData({required this.data, required this.totalCount});

  factory InspectionPageData.fromJson(Map<String, dynamic> json) =>
      InspectionPageData(
        data: (json['data'] as List)
            .map((e) => InspectionModel.fromJson(e))
            .toList(),
        totalCount: json['totalCount'] ?? 0,
      );
}

class InspectionModel {
  final String id;
  final String agencyId;
  final String propertyId;
  final String propertyAddress;
  final String propertySubhurb;
  final String inspectorName;
  final int inspectionType;
  final int inspectionStatus;
  final String inspectionDate;
  final String inspectionTime;
  final PropertyModel? property;

  InspectionModel({
    required this.id,
    required this.agencyId,
    required this.propertyId,
    required this.propertyAddress,
    required this.propertySubhurb,
    required this.inspectorName,
    required this.inspectionType,
    required this.inspectionStatus,
    required this.inspectionDate,
    required this.inspectionTime,
    this.property,
  });

  bool get isPending => inspectionStatus == 1;
  bool get isCompleted => inspectionStatus == 4;

  String get statusLabel {
    if (inspectionStatus == 1) return 'Pending';
    if (inspectionStatus == 4) return 'Completed';
    return 'Unknown';
  }

  String get typeLabel {
    switch (inspectionType) {
      case 1:
        return 'Entry';
      case 2:
        return 'Exit';
      case 3:
        return 'Routine';
      default:
        return 'Inspection';
    }
  }

  DateTime get parsedDate => DateTime.tryParse(inspectionDate) ?? DateTime.now();

  factory InspectionModel.fromJson(Map<String, dynamic> json) =>
      InspectionModel(
        id: json['id'] ?? '',
        agencyId: json['agencyId'] ?? '',
        propertyId: json['propertyId'] ?? '',
        propertyAddress: json['propertyAddress'] ?? '',
        propertySubhurb: json['propertySubhurb'] ?? '',
        inspectorName: json['inspectorName'] ?? '',
        inspectionType: json['inspectionType'] ?? 0,
        inspectionStatus: json['inspectionStatus'] ?? 0,
        inspectionDate: json['inspectionDate'] ?? '',
        inspectionTime: json['inspectionTime'] ?? '',
        property: json['property'] != null
            ? PropertyModel.fromJson(json['property'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'agencyId': agencyId,
        'propertyId': propertyId,
        'propertyAddress': propertyAddress,
        'propertySubhurb': propertySubhurb,
        'inspectorName': inspectorName,
        'inspectionType': inspectionType,
        'inspectionStatus': inspectionStatus,
        'inspectionDate': inspectionDate,
        'inspectionTime': inspectionTime,
        'property': property?.toJson(),
      };
}

class PropertyModel {
  final String name;
  final String address1;
  final String cityOrSuburb;
  final String? propertyImages;
  final double? latitude;
  final double? longitude;

  PropertyModel({
    required this.name,
    required this.address1,
    required this.cityOrSuburb,
    this.propertyImages,
    this.latitude,
    this.longitude,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
        name: json['name'] ?? '',
        address1: json['address1'] ?? '',
        cityOrSuburb: json['cityOrSuburb'] ?? '',
        propertyImages: json['propertyImages'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address1': address1,
        'cityOrSuburb': cityOrSuburb,
        'propertyImages': propertyImages,
        'latitude': latitude,
        'longitude': longitude,
      };
}
