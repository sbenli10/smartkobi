class SupportAnalysisResultModel {
  const SupportAnalysisResultModel({
    required this.id,
    required this.userId,
    this.businessProfileId,
    this.businessId,
    required this.analysisTitle,
    required this.overallScore,
    required this.overallStatus,
    required this.kosgebScore,
    required this.tubitakScore,
    required this.exportSupportScore,
    required this.certificationSupportScore,
    required this.digitalizationSupportScore,
    required this.financingSupportScore,
    required this.missingProfileFields,
    required this.missingDocuments,
    required this.recommendedActions,
    required this.riskNotes,
    required this.opportunityNotes,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessProfileId;
  final String? businessId;
  final String analysisTitle;
  final int overallScore;
  final String overallStatus;
  final int kosgebScore;
  final int tubitakScore;
  final int exportSupportScore;
  final int certificationSupportScore;
  final int digitalizationSupportScore;
  final int financingSupportScore;
  final List<String> missingProfileFields;
  final List<String> missingDocuments;
  final List<String> recommendedActions;
  final List<String> riskNotes;
  final List<String> opportunityNotes;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isHighPotential => overallStatus == 'high_potential';
  bool get isMediumPotential => overallStatus == 'medium_potential';
  bool get isLowPotential => overallStatus == 'low_potential';
  bool get needsProfile => overallStatus == 'needs_profile';

  String get statusLabel {
    switch (overallStatus) {
      case 'high_potential':
        return 'Yüksek Potansiyel';
      case 'medium_potential':
        return 'Orta Potansiyel';
      case 'low_potential':
        return 'Düşük Potansiyel';
      default:
        return 'Profil Bilgisi Gerekli';
    }
  }

  String get scoreLabel {
    if (overallScore >= 75) {
      return 'Güçlü ön uygunluk';
    }
    if (overallScore >= 45) {
      return 'Geliştirilebilir potansiyel';
    }
    if (overallScore > 0) {
      return 'Sınırlı ön uygunluk';
    }
    return 'Analiz için profil gerekli';
  }

  SupportAnalysisResultModel copyWith({
    String? id,
    String? userId,
    String? businessProfileId,
    bool clearBusinessProfileId = false,
    String? businessId,
    bool clearBusinessId = false,
    String? analysisTitle,
    int? overallScore,
    String? overallStatus,
    int? kosgebScore,
    int? tubitakScore,
    int? exportSupportScore,
    int? certificationSupportScore,
    int? digitalizationSupportScore,
    int? financingSupportScore,
    List<String>? missingProfileFields,
    List<String>? missingDocuments,
    List<String>? recommendedActions,
    List<String>? riskNotes,
    List<String>? opportunityNotes,
    String? summary,
    bool clearSummary = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportAnalysisResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessProfileId:
          clearBusinessProfileId ? null : businessProfileId ?? this.businessProfileId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      analysisTitle: analysisTitle ?? this.analysisTitle,
      overallScore: overallScore ?? this.overallScore,
      overallStatus: overallStatus ?? this.overallStatus,
      kosgebScore: kosgebScore ?? this.kosgebScore,
      tubitakScore: tubitakScore ?? this.tubitakScore,
      exportSupportScore: exportSupportScore ?? this.exportSupportScore,
      certificationSupportScore:
          certificationSupportScore ?? this.certificationSupportScore,
      digitalizationSupportScore:
          digitalizationSupportScore ?? this.digitalizationSupportScore,
      financingSupportScore: financingSupportScore ?? this.financingSupportScore,
      missingProfileFields: missingProfileFields ?? this.missingProfileFields,
      missingDocuments: missingDocuments ?? this.missingDocuments,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      riskNotes: riskNotes ?? this.riskNotes,
      opportunityNotes: opportunityNotes ?? this.opportunityNotes,
      summary: clearSummary ? null : summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SupportAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return SupportAnalysisResultModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessProfileId: json['business_profile_id']?.toString(),
      businessId: json['business_id']?.toString(),
      analysisTitle: json['analysis_title']?.toString() ?? 'Destek Analizi',
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
      overallStatus: json['overall_status']?.toString() ?? 'needs_profile',
      kosgebScore: (json['kosgeb_score'] as num?)?.toInt() ?? 0,
      tubitakScore: (json['tubitak_score'] as num?)?.toInt() ?? 0,
      exportSupportScore: (json['export_support_score'] as num?)?.toInt() ?? 0,
      certificationSupportScore:
          (json['certification_support_score'] as num?)?.toInt() ?? 0,
      digitalizationSupportScore:
          (json['digitalization_support_score'] as num?)?.toInt() ?? 0,
      financingSupportScore:
          (json['financing_support_score'] as num?)?.toInt() ?? 0,
      missingProfileFields: parseList(json['missing_profile_fields']),
      missingDocuments: parseList(json['missing_documents']),
      recommendedActions: parseList(json['recommended_actions']),
      riskNotes: parseList(json['risk_notes']),
      opportunityNotes: parseList(json['opportunity_notes']),
      summary: json['summary']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_profile_id': businessProfileId,
      'business_id': businessId,
      'analysis_title': analysisTitle,
      'overall_score': overallScore,
      'overall_status': overallStatus,
      'kosgeb_score': kosgebScore,
      'tubitak_score': tubitakScore,
      'export_support_score': exportSupportScore,
      'certification_support_score': certificationSupportScore,
      'digitalization_support_score': digitalizationSupportScore,
      'financing_support_score': financingSupportScore,
      'missing_profile_fields': missingProfileFields,
      'missing_documents': missingDocuments,
      'recommended_actions': recommendedActions,
      'risk_notes': riskNotes,
      'opportunity_notes': opportunityNotes,
      'summary': summary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
