class DocumentRequirementModel {
  const DocumentRequirementModel({
    required this.id,
    required this.userId,
    this.businessProfileId,
    this.supportAnalysisResultId,
    required this.requiredDocumentType,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.linkedDocumentId,
    this.dueDate,
    this.sourceModule,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessProfileId;
  final String? supportAnalysisResultId;
  final String requiredDocumentType;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final String? linkedDocumentId;
  final DateTime? dueDate;
  final String? sourceModule;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get requiredDocumentTypeLabel =>
      _requirementDocumentTypeLabels[requiredDocumentType] ?? 'Diğer Belge';
  String get categoryLabel => _requirementCategoryLabels[category] ?? 'Genel';
  String get priorityLabel => _priorityLabels[priority] ?? 'Orta';
  String get statusLabel => _requirementStatusLabels[status] ?? 'Eksik';

  bool get isMissing => status == 'missing';
  bool get isCompleted => status == 'completed' || status == 'uploaded';
  bool get isHighPriority => priority == 'high';

  DocumentRequirementModel copyWith({
    String? id,
    String? userId,
    String? businessProfileId,
    bool clearBusinessProfileId = false,
    String? supportAnalysisResultId,
    bool clearSupportAnalysisResultId = false,
    String? requiredDocumentType,
    String? title,
    String? description,
    bool clearDescription = false,
    String? category,
    String? priority,
    String? status,
    String? linkedDocumentId,
    bool clearLinkedDocumentId = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? sourceModule,
    bool clearSourceModule = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentRequirementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessProfileId:
          clearBusinessProfileId ? null : businessProfileId ?? this.businessProfileId,
      supportAnalysisResultId: clearSupportAnalysisResultId
          ? null
          : supportAnalysisResultId ?? this.supportAnalysisResultId,
      requiredDocumentType: requiredDocumentType ?? this.requiredDocumentType,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      linkedDocumentId:
          clearLinkedDocumentId ? null : linkedDocumentId ?? this.linkedDocumentId,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      sourceModule: clearSourceModule ? null : sourceModule ?? this.sourceModule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DocumentRequirementModel.empty() {
    final now = DateTime.now();
    return DocumentRequirementModel(
      id: '',
      userId: '',
      requiredDocumentType: 'other',
      title: '',
      category: 'general',
      priority: 'medium',
      status: 'missing',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DocumentRequirementModel.fromJson(Map<String, dynamic> json) {
    return DocumentRequirementModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      businessProfileId:
          json['business_profile_id']?.toString() ?? json['businessProfileId']?.toString(),
      supportAnalysisResultId: json['support_analysis_result_id']?.toString() ??
          json['supportAnalysisResultId']?.toString(),
      requiredDocumentType: json['required_document_type']?.toString() ??
          json['requiredDocumentType']?.toString() ??
          'other',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'general',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'missing',
      linkedDocumentId:
          json['linked_document_id']?.toString() ?? json['linkedDocumentId']?.toString(),
      dueDate: _parseOptionalDate(json['due_date'] ?? json['dueDate']),
      sourceModule:
          json['source_module']?.toString() ?? json['sourceModule']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_profile_id': businessProfileId,
      'support_analysis_result_id': supportAnalysisResultId,
      'required_document_type': requiredDocumentType,
      'title': title.trim(),
      'description': description?.trim(),
      'category': category,
      'priority': priority,
      'status': status,
      'linked_document_id': linkedDocumentId,
      'due_date': _toIsoDate(dueDate),
      'source_module': sourceModule,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

final Map<String, String> _requirementDocumentTypeLabels = {
  'tax_certificate': 'Vergi Levhası',
  'activity_certificate': 'Faaliyet Belgesi',
  'signature_circular': 'İmza Sirküleri',
  'sme_declaration': 'KOBİ Beyannamesi',
  'capacity_report': 'Kapasite Raporu',
  'invoice': 'Fatura',
  'receipt': 'Dekont',
  'proforma_invoice': 'Proforma Fatura',
  'quotation': 'Teklif Formu',
  'technical_specification': 'Teknik Şartname / Teknik Doküman',
  'iso_certificate': 'ISO Belgesi',
  'tse_certificate': 'TSE Belgesi',
  'ce_certificate': 'CE Belgesi',
  'export_document': 'İhracat Belgesi',
  'bank_document': 'Banka / Finansman Belgesi',
  'contract': 'Sözleşme',
  'other': 'Diğer',
};

final Map<String, String> _requirementCategoryLabels = {
  'company': 'Şirket Belgeleri',
  'finance': 'Finansal Belgeler',
  'support': 'Destek Evrakları',
  'certification': 'Sertifikalar',
  'export': 'İhracat Belgeleri',
  'technical': 'Teknik Dokümanlar',
  'contract': 'Sözleşmeler',
  'general': 'Genel',
};

final Map<String, String> _priorityLabels = {
  'low': 'Düşük',
  'medium': 'Orta',
  'high': 'Yüksek',
};

final Map<String, String> _requirementStatusLabels = {
  'missing': 'Eksik',
  'uploaded': 'Yüklendi',
  'not_required': 'Gerekmiyor',
  'completed': 'Tamamlandı',
};

DateTime _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}

String? _toIsoDate(DateTime? value) => value?.toIso8601String().split('T').first;
