class ReportSectionModel {
  const ReportSectionModel({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.sectionKey,
    required this.title,
    this.content,
    required this.sortOrder,
    required this.sectionData,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String reportId;
  final String sectionKey;
  final String title;
  final String? content;
  final int sortOrder;
  final Map<String, dynamic> sectionData;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportSectionModel copyWith({
    String? id,
    String? userId,
    String? reportId,
    String? sectionKey,
    String? title,
    String? content,
    bool clearContent = false,
    int? sortOrder,
    Map<String, dynamic>? sectionData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportSectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportId: reportId ?? this.reportId,
      sectionKey: sectionKey ?? this.sectionKey,
      title: title ?? this.title,
      content: clearContent ? null : content ?? this.content,
      sortOrder: sortOrder ?? this.sortOrder,
      sectionData: sectionData ?? this.sectionData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReportSectionModel.fromJson(Map<String, dynamic> json) {
    return ReportSectionModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      reportId: json['report_id']?.toString() ?? json['reportId']?.toString() ?? '',
      sectionKey: json['section_key']?.toString() ?? json['sectionKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ??
          (json['sortOrder'] as num?)?.toInt() ??
          0,
      sectionData: _reportSectionParseMap(json['section_data'] ?? json['sectionData']),
      createdAt: _reportSectionParseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _reportSectionParseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'report_id': reportId,
      'section_key': sectionKey,
      'title': title,
      'content': content,
      'sort_order': sortOrder,
      'section_data': sectionData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

Map<String, dynamic> _reportSectionParseMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

DateTime _reportSectionParseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
