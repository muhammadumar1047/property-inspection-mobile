class ReportTemplateResponse {
  final bool success;
  final ReportTemplate data;

  ReportTemplateResponse({required this.success, required this.data});

  factory ReportTemplateResponse.fromJson(Map<String, dynamic> json) =>
      ReportTemplateResponse(
        success: json['success'] ?? false,
        data: ReportTemplate.fromJson(json['data']),
      );
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
}

class ReportItemCondition {
  final String description;
  final String type; // boolean, text, number, date
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
}

class ReportItemComment {
  String text;
  ReportItemComment({required this.text});
  factory ReportItemComment.fromJson(Map<String, dynamic> json) =>
      ReportItemComment(text: json['text'] ?? '');
}

class ReportMedia {
  String url;
  final String type; // photo, video
  ReportMedia({required this.url, required this.type});
  factory ReportMedia.fromJson(Map<String, dynamic> json) =>
      ReportMedia(url: json['url'] ?? '', type: json['type'] ?? 'photo');
}
