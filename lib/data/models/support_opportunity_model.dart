class SupportOpportunityModel {
  const SupportOpportunityModel({
    required this.id,
    required this.userId,
    this.analysisResultId,
    this.businessProfileId,
    required this.supportType,
    required this.title,
    this.description,
    required this.eligibilityScore,
    required this.eligibilityStatus,
    required this.missingRequirements,
    required this.nextSteps,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? analysisResultId;
  final String? businessProfileId;
  final String supportType;
  final String title;
  final String? description;
  final int eligibilityScore;
  final String eligibilityStatus;
  final List<String> missingRequirements;
  final List<String> nextSteps;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get supportTypeLabel {
    switch (supportType) {
      case 'kosgeb':
        return 'KOSGEB';
      case 'tubitak':
        return 'TÜBİTAK / Ar-Ge';
      case 'export':
        return 'İhracat Destekleri';
      case 'certification':
        return 'Belgelendirme';
      case 'digitalization':
        return 'Dijitalleşme';
      case 'financing':
        return 'Finansman / Eximbank';
      default:
        return 'Diğer';
    }
  }

  String get eligibilityStatusLabel {
    switch (eligibilityStatus) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      case 'low':
        return 'Düşük';
      default:
        return 'Bilgi Gerekli';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'Yüksek Öncelik';
      case 'low':
        return 'Düşük Öncelik';
      default:
        return 'Orta Öncelik';
    }
  }

  SupportOpportunityModel copyWith({
    String? id,
    String? userId,
    String? analysisResultId,
    bool clearAnalysisResultId = false,
    String? businessProfileId,
    bool clearBusinessProfileId = false,
    String? supportType,
    String? title,
    String? description,
    bool clearDescription = false,
    int? eligibilityScore,
    String? eligibilityStatus,
    List<String>? missingRequirements,
    List<String>? nextSteps,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportOpportunityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      analysisResultId:
          clearAnalysisResultId ? null : analysisResultId ?? this.analysisResultId,
      businessProfileId: clearBusinessProfileId
          ? null
          : businessProfileId ?? this.businessProfileId,
      supportType: supportType ?? this.supportType,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      eligibilityScore: eligibilityScore ?? this.eligibilityScore,
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      missingRequirements: missingRequirements ?? this.missingRequirements,
      nextSteps: nextSteps ?? this.nextSteps,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SupportOpportunityModel.fromJson(Map<String, dynamic> json) {
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

    return SupportOpportunityModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      analysisResultId: json['analysis_result_id']?.toString(),
      businessProfileId: json['business_profile_id']?.toString(),
      supportType: json['support_type']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      eligibilityScore: (json['eligibility_score'] as num?)?.toInt() ?? 0,
      eligibilityStatus: json['eligibility_status']?.toString() ?? 'needs_info',
      missingRequirements: parseList(json['missing_requirements']),
      nextSteps: parseList(json['next_steps']),
      priority: json['priority']?.toString() ?? 'medium',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'analysis_result_id': analysisResultId,
      'business_profile_id': businessProfileId,
      'support_type': supportType,
      'title': title,
      'description': description,
      'eligibility_score': eligibilityScore,
      'eligibility_status': eligibilityStatus,
      'missing_requirements': missingRequirements,
      'next_steps': nextSteps,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
