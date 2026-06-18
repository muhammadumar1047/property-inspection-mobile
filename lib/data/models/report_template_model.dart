class ReportTemplateResponse {
  final bool success;
  final ReportTemplate data;

  ReportTemplateResponse({required this.success, required this.data});

  factory ReportTemplateResponse.fromJson(Map<String, dynamic> json) =>
      ReportTemplateResponse(
        success: json['success'] ?? false,
        data: ReportTemplate.fromJson(json['data']),
      );

  Map<String, dynamic> toJson() => {'success': success, 'data': data.toJson()};
}

class ReportTemplate {
  final String inspectionId;
  final String reportType;
  final String notes;
  final List<ReportArea> reportAreas;

  ReportTemplate({
    required this.inspectionId,
    required this.reportType,
    required this.notes,
    required this.reportAreas,
  });

  factory ReportTemplate.fromJson(Map<String, dynamic> json) => ReportTemplate(
        inspectionId: json['inspectionId'] ?? '',
        reportType: json['reportType'] ?? '',
        notes: json['notes'] ?? '',
        reportAreas: (json['reportAreas'] as List? ?? [])
            .map((e) => ReportArea.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'inspectionId': inspectionId,
        'reportType': reportType,
        'notes': notes,
        'reportAreas': reportAreas.map((e) => e.toJson()).toList(),
      };
}

class ReportArea {
  final String name;
  final List<ReportItem> reportItems;

  ReportArea({required this.name, required this.reportItems});

  factory ReportArea.fromJson(Map<String, dynamic> json) => ReportArea(
        name: json['name'] ?? '',
        reportItems: (json['reportItems'] as List? ?? [])
            .map((e) => ReportItem.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'reportItems': reportItems.map((e) => e.toJson()).toList(),
      };
}

class ReportItem {
  final String name;
  final List<ReportItemCondition> reportItemConditions;
  final List<ReportItemComment> reportItemComments;
  final List<ReportMedia> reportMedia;

  ReportItem({
    required this.name,
    required this.reportItemConditions,
    required this.reportItemComments,
    required this.reportMedia,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) => ReportItem(
        name: json['name'] ?? '',
        reportItemConditions: (json['reportItemConditions'] as List? ?? [])
            .map((e) => ReportItemCondition.fromJson(e))
            .toList(),
        reportItemComments: (json['reportItemComments'] as List? ?? [])
            .map((e) => ReportItemComment.fromJson(e))
            .toList(),
        reportMedia: (json['reportMedia'] as List? ?? [])
            .map((e) => ReportMedia.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'reportItemConditions': reportItemConditions.map((e) => e.toJson()).toList(),
        'reportItemComments': reportItemComments.map((e) => e.toJson()).toList(),
        'reportMedia': reportMedia.map((e) => e.toJson()).toList(),
      };
}

class ReportItemCondition {
  final String description;
  final String type;
  dynamic value;

  ReportItemCondition({
    required this.description,
    required this.type,
    this.value,
  });

  factory ReportItemCondition.fromJson(Map<String, dynamic> json) =>
      ReportItemCondition(
        description: json['description'] ?? '',
        type: json['type'] ?? 'boolean',
        value: json['value'],
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'type': type,
        'value': value,
      };
}

class ReportItemComment {
  String text;
  ReportItemComment({required this.text});
  factory ReportItemComment.fromJson(Map<String, dynamic> json) =>
      ReportItemComment(text: json['text'] ?? '');
  Map<String, dynamic> toJson() => {'text': text};
}

class ReportMedia {
  String url;
  final String type;
  ReportMedia({required this.url, required this.type});
  factory ReportMedia.fromJson(Map<String, dynamic> json) =>
      ReportMedia(url: json['url'] ?? '', type: json['type'] ?? 'photo');
  Map<String, dynamic> toJson() => {'url': url, 'type': type};
}
