class BusinessDocumentModel {
  const BusinessDocumentModel({
    required this.id,
    required this.userId,
    this.businessProfileId,
    this.businessId,
    required this.title,
    required this.documentType,
    required this.category,
    this.fileName,
    this.filePath,
    this.fileMimeType,
    this.fileSizeBytes,
    required this.status,
    this.issueDate,
    this.expiryDate,
    this.issuer,
    this.referenceNumber,
    this.notes,
    required this.tags,
    this.sourceModule,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessProfileId;
  final String? businessId;
  final String title;
  final String documentType;
  final String category;
  final String? fileName;
  final String? filePath;
  final String? fileMimeType;
  final int? fileSizeBytes;
  final String status;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? issuer;
  final String? referenceNumber;
  final String? notes;
  final List<String> tags;
  final String? sourceModule;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get documentTypeLabel => _documentTypeLabels[documentType] ?? 'Diğer';
  String get categoryLabel => _categoryLabels[category] ?? 'Genel';
  String get statusLabel => _statusLabels[status] ?? 'Bilinmiyor';

  bool get isMissing => status == 'missing';
  bool get isUploaded => status == 'uploaded' || status == 'approved' || status == 'needs_review';
  bool get isExpired {
    if (status == 'expired') {
      return true;
    }
    if (expiryDate == null) {
      return false;
    }
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    return expiryDate!.isBefore(date);
  }

  bool get willExpireSoon {
    if (status == 'will_expire' || expiryDate == null || isExpired) {
      return status == 'will_expire';
    }
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final limit = date.add(const Duration(days: 30));
    return !expiryDate!.isBefore(date) && !expiryDate!.isAfter(limit);
  }

  bool get hasFile => (filePath?.trim().isNotEmpty ?? false) || (fileName?.trim().isNotEmpty ?? false);

  String get formattedFileSize {
    final size = fileSizeBytes ?? 0;
    if (size <= 0) {
      return '-';
    }
    if (size < 1024) {
      return '$size B';
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  BusinessDocumentModel copyWith({
    String? id,
    String? userId,
    String? businessProfileId,
    bool clearBusinessProfileId = false,
    String? businessId,
    bool clearBusinessId = false,
    String? title,
    String? documentType,
    String? category,
    String? fileName,
    bool clearFileName = false,
    String? filePath,
    bool clearFilePath = false,
    String? fileMimeType,
    bool clearFileMimeType = false,
    int? fileSizeBytes,
    bool clearFileSizeBytes = false,
    String? status,
    DateTime? issueDate,
    bool clearIssueDate = false,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? issuer,
    bool clearIssuer = false,
    String? referenceNumber,
    bool clearReferenceNumber = false,
    String? notes,
    bool clearNotes = false,
    List<String>? tags,
    String? sourceModule,
    bool clearSourceModule = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessDocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessProfileId:
          clearBusinessProfileId ? null : businessProfileId ?? this.businessProfileId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      category: category ?? this.category,
      fileName: clearFileName ? null : fileName ?? this.fileName,
      filePath: clearFilePath ? null : filePath ?? this.filePath,
      fileMimeType: clearFileMimeType ? null : fileMimeType ?? this.fileMimeType,
      fileSizeBytes: clearFileSizeBytes ? null : fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      issueDate: clearIssueDate ? null : issueDate ?? this.issueDate,
      expiryDate: clearExpiryDate ? null : expiryDate ?? this.expiryDate,
      issuer: clearIssuer ? null : issuer ?? this.issuer,
      referenceNumber:
          clearReferenceNumber ? null : referenceNumber ?? this.referenceNumber,
      notes: clearNotes ? null : notes ?? this.notes,
      tags: tags ?? this.tags,
      sourceModule: clearSourceModule ? null : sourceModule ?? this.sourceModule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BusinessDocumentModel.empty() {
    final now = DateTime.now();
    return BusinessDocumentModel(
      id: '',
      userId: '',
      title: '',
      documentType: 'other',
      category: 'general',
      status: 'uploaded',
      tags: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory BusinessDocumentModel.fromJson(Map<String, dynamic> json) {
    return BusinessDocumentModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      businessProfileId:
          json['business_profile_id']?.toString() ?? json['businessProfileId']?.toString(),
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString(),
      title: json['title']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? json['documentType']?.toString() ?? 'other',
      category: json['category']?.toString() ?? 'general',
      fileName: json['file_name']?.toString() ?? json['fileName']?.toString(),
      filePath: json['file_path']?.toString() ?? json['filePath']?.toString(),
      fileMimeType:
          json['file_mime_type']?.toString() ?? json['fileMimeType']?.toString(),
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ??
          (json['fileSizeBytes'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'uploaded',
      issueDate: _parseOptionalDate(json['issue_date'] ?? json['issueDate']),
      expiryDate: _parseOptionalDate(json['expiry_date'] ?? json['expiryDate']),
      issuer: json['issuer']?.toString(),
      referenceNumber:
          json['reference_number']?.toString() ?? json['referenceNumber']?.toString(),
      notes: json['notes']?.toString(),
      tags: _parseStringList(json['tags']),
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
      'business_id': businessId,
      'title': title.trim(),
      'document_type': documentType,
      'category': category,
      'file_name': fileName?.trim(),
      'file_path': filePath?.trim(),
      'file_mime_type': fileMimeType?.trim(),
      'file_size_bytes': fileSizeBytes,
      'status': status,
      'issue_date': _toIsoDate(issueDate),
      'expiry_date': _toIsoDate(expiryDate),
      'issuer': issuer?.trim(),
      'reference_number': referenceNumber?.trim(),
      'notes': notes?.trim(),
      'tags': tags,
      'source_module': sourceModule,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

final Map<String, String> _documentTypeLabels = {
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

final Map<String, String> _categoryLabels = {
  'company': 'Şirket Belgeleri',
  'finance': 'Finansal Belgeler',
  'support': 'Destek Evrakları',
  'certification': 'Sertifikalar',
  'export': 'İhracat Belgeleri',
  'technical': 'Teknik Dokümanlar',
  'contract': 'Sözleşmeler',
  'general': 'Genel',
};

final Map<String, String> _statusLabels = {
  'missing': 'Eksik',
  'uploaded': 'Yüklendi',
  'needs_review': 'İncelenecek',
  'approved': 'Uygun',
  'expired': 'Süresi Geçti',
  'will_expire': 'Süresi Yaklaşıyor',
  'rejected': 'Uygun Değil',
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

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

String? _toIsoDate(DateTime? value) => value?.toIso8601String().split('T').first;
