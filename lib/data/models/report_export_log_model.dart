class ReportExportLogModel {
  const ReportExportLogModel({
    required this.id,
    required this.userId,
    this.reportId,
    required this.exportType,
    this.filePath,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? reportId;
  final String exportType;
  final String? filePath;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;

  factory ReportExportLogModel.fromJson(Map<String, dynamic> json) {
    return ReportExportLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      reportId: json['report_id']?.toString() ?? json['reportId']?.toString(),
      exportType: json['export_type']?.toString() ?? json['exportType']?.toString() ?? 'pdf',
      filePath: json['file_path']?.toString() ?? json['filePath']?.toString(),
      status: json['status']?.toString() ?? 'success',
      errorMessage: json['error_message']?.toString() ?? json['errorMessage']?.toString(),
      createdAt: _reportExportParseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'report_id': reportId,
      'export_type': exportType,
      'file_path': filePath,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

DateTime _reportExportParseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
