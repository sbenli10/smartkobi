class BusinessReportModel {
  const BusinessReportModel({
    required this.id,
    required this.userId,
    this.businessProfileId,
    this.businessId,
    required this.reportType,
    required this.title,
    this.periodLabel,
    this.periodStart,
    this.periodEnd,
    required this.status,
    this.summary,
    required this.keyFindings,
    required this.risks,
    required this.opportunities,
    required this.recommendedActions,
    required this.reportData,
    this.pdfFilePath,
    this.pdfFileName,
    this.generatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessProfileId;
  final String? businessId;
  final String reportType;
  final String title;
  final String? periodLabel;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String status;
  final String? summary;
  final List<String> keyFindings;
  final List<String> risks;
  final List<String> opportunities;
  final List<String> recommendedActions;
  final Map<String, dynamic> reportData;
  final String? pdfFilePath;
  final String? pdfFileName;
  final DateTime? generatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get reportTypeLabel => _reportTypeLabels[reportType] ?? 'Özel Rapor';

  String get statusLabel => _statusLabels[status] ?? 'Bilinmiyor';

  bool get isReady => status == 'ready';

  bool get isFailed => status == 'failed';

  bool get hasPdf =>
      (pdfFilePath?.trim().isNotEmpty ?? false) ||
      (pdfFileName?.trim().isNotEmpty ?? false);

  String get formattedPeriod {
    if ((periodLabel ?? '').trim().isNotEmpty) {
      return periodLabel!.trim();
    }
    if (periodStart != null && periodEnd != null) {
      return '${_formatDate(periodStart)} - ${_formatDate(periodEnd)}';
    }
    if (periodStart != null) {
      return _formatDate(periodStart);
    }
    return 'Genel görünüm';
  }

  BusinessReportModel copyWith({
    String? id,
    String? userId,
    String? businessProfileId,
    bool clearBusinessProfileId = false,
    String? businessId,
    bool clearBusinessId = false,
    String? reportType,
    String? title,
    String? periodLabel,
    bool clearPeriodLabel = false,
    DateTime? periodStart,
    bool clearPeriodStart = false,
    DateTime? periodEnd,
    bool clearPeriodEnd = false,
    String? status,
    String? summary,
    bool clearSummary = false,
    List<String>? keyFindings,
    List<String>? risks,
    List<String>? opportunities,
    List<String>? recommendedActions,
    Map<String, dynamic>? reportData,
    String? pdfFilePath,
    bool clearPdfFilePath = false,
    String? pdfFileName,
    bool clearPdfFileName = false,
    DateTime? generatedAt,
    bool clearGeneratedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessProfileId:
          clearBusinessProfileId ? null : businessProfileId ?? this.businessProfileId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      reportType: reportType ?? this.reportType,
      title: title ?? this.title,
      periodLabel: clearPeriodLabel ? null : periodLabel ?? this.periodLabel,
      periodStart: clearPeriodStart ? null : periodStart ?? this.periodStart,
      periodEnd: clearPeriodEnd ? null : periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      summary: clearSummary ? null : summary ?? this.summary,
      keyFindings: keyFindings ?? this.keyFindings,
      risks: risks ?? this.risks,
      opportunities: opportunities ?? this.opportunities,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      reportData: reportData ?? this.reportData,
      pdfFilePath: clearPdfFilePath ? null : pdfFilePath ?? this.pdfFilePath,
      pdfFileName: clearPdfFileName ? null : pdfFileName ?? this.pdfFileName,
      generatedAt: clearGeneratedAt ? null : generatedAt ?? this.generatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BusinessReportModel.fromJson(Map<String, dynamic> json) {
    return BusinessReportModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      businessProfileId:
          json['business_profile_id']?.toString() ?? json['businessProfileId']?.toString(),
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString(),
      reportType: json['report_type']?.toString() ?? json['reportType']?.toString() ?? 'custom',
      title: json['title']?.toString() ?? '',
      periodLabel: json['period_label']?.toString() ?? json['periodLabel']?.toString(),
      periodStart: _parseNullableDate(json['period_start'] ?? json['periodStart']),
      periodEnd: _parseNullableDate(json['period_end'] ?? json['periodEnd']),
      status: json['status']?.toString() ?? 'draft',
      summary: json['summary']?.toString(),
      keyFindings: _parseStringList(json['key_findings'] ?? json['keyFindings']),
      risks: _parseStringList(json['risks']),
      opportunities: _parseStringList(json['opportunities']),
      recommendedActions:
          _parseStringList(json['recommended_actions'] ?? json['recommendedActions']),
      reportData: _parseMap(json['report_data'] ?? json['reportData']),
      pdfFilePath: json['pdf_file_path']?.toString() ?? json['pdfFilePath']?.toString(),
      pdfFileName: json['pdf_file_name']?.toString() ?? json['pdfFileName']?.toString(),
      generatedAt: _parseNullableDateTime(json['generated_at'] ?? json['generatedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_profile_id': businessProfileId,
      'business_id': businessId,
      'report_type': reportType,
      'title': title,
      'period_label': periodLabel,
      'period_start': _toIsoDate(periodStart),
      'period_end': _toIsoDate(periodEnd),
      'status': status,
      'summary': summary,
      'key_findings': keyFindings,
      'risks': risks,
      'opportunities': opportunities,
      'recommended_actions': recommendedActions,
      'report_data': reportData,
      'pdf_file_path': pdfFilePath,
      'pdf_file_name': pdfFileName,
      'generated_at': generatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

final Map<String, String> _reportTypeLabels = {
  'business_health': 'KOBİ Sağlık Raporu',
  'financial_summary': 'Finansal Özet Raporu',
  'cashflow': 'Nakit Akışı Raporu',
  'customer_risk': 'Cari / Tahsilat Risk Raporu',
  'inventory_risk': 'Stok Risk Raporu',
  'support_eligibility': 'Destek Uygunluk Raporu',
  'document_gap': 'Eksik Belge Raporu',
  'daily_action_plan': 'Günlük İş Planı Raporu',
  'weekly_action_plan': 'Haftalık İş Planı Raporu',
  'custom': 'Özel Rapor',
};

final Map<String, String> _statusLabels = {
  'draft': 'Taslak',
  'ready': 'Hazır',
  'generating': 'Hazırlanıyor',
  'failed': 'Hata',
  'archived': 'Arşivlendi',
};

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

Map<String, dynamic> _parseMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}

String? _toIsoDate(DateTime? value) => value?.toIso8601String().split('T').first;

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day.$month.$year';
}
