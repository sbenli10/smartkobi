import '../../data/models/business_document_model.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/document_requirement_model.dart';
import '../../data/models/support_analysis_result_model.dart';

int countUploadedDocuments(List<BusinessDocumentModel> documents) {
  return documents.where((document) => document.isUploaded).length;
}

int countMissingRequirements(List<DocumentRequirementModel> requirements) {
  return requirements.where((item) => item.isMissing).length;
}

int countExpiredDocuments(List<BusinessDocumentModel> documents) {
  return documents.where((document) => document.isExpired).length;
}

int countWillExpireDocuments(List<BusinessDocumentModel> documents) {
  return documents.where((document) => document.willExpireSoon).length;
}

int countHighPriorityMissing(List<DocumentRequirementModel> requirements) {
  return requirements.where((item) => item.isMissing && item.isHighPriority).length;
}

int calculateSupportReadinessScore({
  required List<BusinessDocumentModel> documents,
  required List<DocumentRequirementModel> requirements,
}) {
  final uploaded = countUploadedDocuments(documents);
  final completedRequirements = requirements.where((item) => item.isCompleted).length;
  final highPriorityMissing = countHighPriorityMissing(requirements);
  final expired = countExpiredDocuments(documents);
  final missing = countMissingRequirements(requirements);

  final rawScore =
      35 + (uploaded * 8) + (completedRequirements * 7) - (highPriorityMissing * 12) - (expired * 10) - (missing * 4);
  return rawScore.clamp(0, 100).toInt();
}

String generateDocumentAiInsight({
  required List<BusinessDocumentModel> documents,
  required List<DocumentRequirementModel> requirements,
}) {
  if (documents.isEmpty && requirements.isEmpty) {
    return 'İlk belgenizi yüklediğinizde destek ve başvuru hazırlık süreciniz daha görünür hale gelir.';
  }

  final highPriorityMissing = countHighPriorityMissing(requirements);
  if (highPriorityMissing > 0) {
    return 'Başvuru hazırlığı için yüksek öncelikli eksik belgeleriniz var.';
  }

  final expired = countExpiredDocuments(documents);
  if (expired > 0) {
    return 'Süresi geçen belgeleri güncellemeniz önerilir.';
  }

  final willExpire = countWillExpireDocuments(documents);
  if (willExpire > 0) {
    return 'Süresi yaklaşan belgeleri erkenden yenilemeniz destek başvurularında rahatlık sağlar.';
  }

  if (countMissingRequirements(requirements) > 0) {
    return 'Vergi levhası, faaliyet belgesi ve KOBİ beyannamesi destek başvurularında sık kullanılan belgelerdir.';
  }

  return 'Belgeleriniz tamamlandıkça destek analiziniz daha güvenilir hale gelir.';
}

List<DocumentRequirementModel> generateDefaultRequirementsForProfile(
  BusinessProfileModel? profile,
) {
  if (profile == null || profile.businessName.trim().isEmpty) {
    return const [];
  }

  final now = DateTime.now();
  final requirements = <DocumentRequirementModel>[
    _draftRequirement(
      title: 'Vergi Levhası',
      requiredDocumentType: 'tax_certificate',
      category: 'company',
      priority: 'high',
      description: 'Şirket temel belge klasörünüzde güncel vergi levhası bulundurmanız önerilir.',
      sourceModule: 'business_profile',
      createdAt: now,
    ),
    _draftRequirement(
      title: 'Faaliyet Belgesi',
      requiredDocumentType: 'activity_certificate',
      category: 'company',
      priority: 'high',
      description: 'Resmî faaliyet belgesi birçok destek ve başvuru dosyasında istenir.',
      sourceModule: 'business_profile',
      createdAt: now,
    ),
    _draftRequirement(
      title: 'İmza Sirküleri',
      requiredDocumentType: 'signature_circular',
      category: 'company',
      priority: 'medium',
      description: 'İmza sirküleri veya imza beyannamesi başvuru klasörünü güçlendirir.',
      sourceModule: 'business_profile',
      createdAt: now,
    ),
    _draftRequirement(
      title: 'KOBİ Beyannamesi',
      requiredDocumentType: 'sme_declaration',
      category: 'support',
      priority: 'high',
      description: 'KOBİ desteklerinde sık kullanılan beyannameyi hazırlı listede tutmanız önerilir.',
      sourceModule: 'business_profile',
      createdAt: now,
    ),
  ];

  if (profile.doesManufacture) {
    requirements.addAll([
      _draftRequirement(
        title: 'Kapasite Raporu',
        requiredDocumentType: 'capacity_report',
        category: 'technical',
        priority: 'high',
        description: 'Üretim yapan işletmeler için kapasite raporu hazırlığı yararlı olur.',
        sourceModule: 'business_profile',
        createdAt: now,
      ),
      _draftRequirement(
        title: 'Teknik Dokümanlar',
        requiredDocumentType: 'technical_specification',
        category: 'technical',
        priority: 'medium',
        description: 'Makine, proses veya ürün teknik dokümanlarının ayrı klasörde tutulması önerilir.',
        sourceModule: 'business_profile',
        createdAt: now,
      ),
    ]);
  }

  if (profile.doesExport || profile.wantsExport) {
    requirements.add(
      _draftRequirement(
        title: 'İhracat Belgeleri',
        requiredDocumentType: 'export_document',
        category: 'export',
        priority: 'high',
        description: 'Hedef pazar ve ihracat süreci için temel ihracat belgelerini hazır tutmanız önerilir.',
        sourceModule: 'business_profile',
        createdAt: now,
      ),
    );
  }

  if (profile.needsCertification || profile.doesExport || profile.wantsExport) {
    requirements.addAll([
      _draftRequirement(
        title: 'ISO Belgesi',
        requiredDocumentType: 'iso_certificate',
        category: 'certification',
        priority: 'medium',
        description: 'Belgelendirme planınız varsa ISO dosyalarını tek merkezde toplamanız iyi olur.',
        sourceModule: 'business_profile',
        createdAt: now,
      ),
      _draftRequirement(
        title: 'TSE Belgesi',
        requiredDocumentType: 'tse_certificate',
        category: 'certification',
        priority: 'medium',
        description: 'Ürün ve süreç uygunluğu için TSE evraklarını hazırlık listesinde tutabilirsiniz.',
        sourceModule: 'business_profile',
        createdAt: now,
      ),
      _draftRequirement(
        title: 'CE Belgesi',
        requiredDocumentType: 'ce_certificate',
        category: 'certification',
        priority: 'medium',
        description: 'İhracat veya teknik uygunluk için CE klasörü oluşturmanız önerilir.',
        sourceModule: 'business_profile',
        createdAt: now,
      ),
    ]);
  }

  return requirements;
}

List<DocumentRequirementModel> generateRequirementsFromSupportAnalysis(
  SupportAnalysisResultModel? analysis,
) {
  if (analysis == null) {
    return const [];
  }

  final now = DateTime.now();
  return analysis.missingDocuments.map((item) {
    final documentType = _guessDocumentTypeFromText(item);
    return _draftRequirement(
      title: _documentTitleFromType(documentType, fallback: item),
      requiredDocumentType: documentType,
      category: _categoryFromDocumentType(documentType),
      priority: _priorityFromAnalysisText(item),
      description: '$item belgesi destek analizi sırasında hazırlık ihtiyacı olarak öne çıktı.',
      sourceModule: 'support_analysis',
      createdAt: now,
    );
  }).toList();
}

DocumentRequirementModel _draftRequirement({
  required String title,
  required String requiredDocumentType,
  required String category,
  required String priority,
  required String description,
  required String sourceModule,
  required DateTime createdAt,
}) {
  return DocumentRequirementModel(
    id: '',
    userId: '',
    requiredDocumentType: requiredDocumentType,
    title: title,
    description: description,
    category: category,
    priority: priority,
    status: 'missing',
    sourceModule: sourceModule,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

String _priorityFromAnalysisText(String text) {
  final normalized = text.toLowerCase();
  if (normalized.contains('vergi') ||
      normalized.contains('faaliyet') ||
      normalized.contains('kobi') ||
      normalized.contains('kapasite')) {
    return 'high';
  }
  return 'medium';
}

String _guessDocumentTypeFromText(String text) {
  final normalized = text.toLowerCase();
  if (normalized.contains('vergi')) return 'tax_certificate';
  if (normalized.contains('faaliyet')) return 'activity_certificate';
  if (normalized.contains('imza')) return 'signature_circular';
  if (normalized.contains('kobi')) return 'sme_declaration';
  if (normalized.contains('kapasite')) return 'capacity_report';
  if (normalized.contains('proforma')) return 'proforma_invoice';
  if (normalized.contains('teknik')) return 'technical_specification';
  if (normalized.contains('iso')) return 'iso_certificate';
  if (normalized.contains('tse')) return 'tse_certificate';
  if (normalized.contains('ce')) return 'ce_certificate';
  if (normalized.contains('ihracat')) return 'export_document';
  if (normalized.contains('banka') || normalized.contains('finansman')) return 'bank_document';
  if (normalized.contains('sozlesme')) return 'contract';
  return 'other';
}

String _categoryFromDocumentType(String type) {
  switch (type) {
    case 'tax_certificate':
    case 'activity_certificate':
    case 'signature_circular':
      return 'company';
    case 'invoice':
    case 'receipt':
    case 'proforma_invoice':
    case 'bank_document':
      return 'finance';
    case 'sme_declaration':
      return 'support';
    case 'iso_certificate':
    case 'tse_certificate':
    case 'ce_certificate':
      return 'certification';
    case 'export_document':
      return 'export';
    case 'capacity_report':
    case 'technical_specification':
      return 'technical';
    case 'contract':
      return 'contract';
    default:
      return 'general';
  }
}

String _documentTitleFromType(String type, {required String fallback}) {
  switch (type) {
    case 'tax_certificate':
      return 'Vergi Levhası';
    case 'activity_certificate':
      return 'Faaliyet Belgesi';
    case 'signature_circular':
      return 'İmza Sirküleri';
    case 'sme_declaration':
      return 'KOBİ Beyannamesi';
    case 'capacity_report':
      return 'Kapasite Raporu';
    case 'proforma_invoice':
      return 'Proforma Fatura';
    case 'technical_specification':
      return 'Teknik Doküman';
    case 'iso_certificate':
      return 'ISO Belgesi';
    case 'tse_certificate':
      return 'TSE Belgesi';
    case 'ce_certificate':
      return 'CE Belgesi';
    case 'export_document':
      return 'İhracat Belgesi';
    case 'bank_document':
      return 'Banka / Finansman Belgesi';
    case 'contract':
      return 'Sözleşme';
    default:
      return fallback;
  }
}
