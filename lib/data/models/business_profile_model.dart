class BusinessProfileModel {
  const BusinessProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    this.legalName,
    this.taxNumber,
    this.taxOffice,
    this.businessType,
    this.sector,
    this.naceCode,
    this.city,
    this.district,
    this.foundationYear,
    this.employeeCount,
    this.annualRevenueRange,
    this.monthlyExpenseRange,
    required this.doesManufacture,
    required this.doesExport,
    required this.wantsExport,
    required this.hasEcommerce,
    required this.hasPhysicalStore,
    required this.needsMachinery,
    required this.needsDigitalization,
    required this.needsCertification,
    required this.needsFinancing,
    this.targetInvestmentAmount,
    this.mainProducts,
    this.targetMarkets,
    required this.certifications,
    required this.profileCompletion,
    required this.onboardingCompleted,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? legalName;
  final String? taxNumber;
  final String? taxOffice;
  final String? businessType;
  final String? sector;
  final String? naceCode;
  final String? city;
  final String? district;
  final int? foundationYear;
  final int? employeeCount;
  final String? annualRevenueRange;
  final String? monthlyExpenseRange;
  final bool doesManufacture;
  final bool doesExport;
  final bool wantsExport;
  final bool hasEcommerce;
  final bool hasPhysicalStore;
  final bool needsMachinery;
  final bool needsDigitalization;
  final bool needsCertification;
  final bool needsFinancing;
  final double? targetInvestmentAmount;
  final String? mainProducts;
  final String? targetMarkets;
  final List<String> certifications;
  final int profileCompletion;
  final bool onboardingCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isComplete => profileCompletion >= 90;
  bool get isManufacturingBusiness => doesManufacture;
  bool get isExportPotential => doesExport || wantsExport;

  String get supportReadinessLevel {
    if (profileCompletion >= 90) {
      return 'Güçlü Profil';
    }
    if (profileCompletion >= 70) {
      return 'Analize Hazır';
    }
    if (profileCompletion >= 40) {
      return 'Geliştirilebilir Profil';
    }
    return 'Eksik Profil';
  }

  int calculateCompletion() {
    var score = 0;

    if (businessName.trim().isNotEmpty) score += 10;
    if ((businessType ?? '').trim().isNotEmpty) score += 8;
    if ((sector ?? '').trim().isNotEmpty) score += 10;
    if ((naceCode ?? '').trim().isNotEmpty) score += 10;
    if ((city ?? '').trim().isNotEmpty) score += 6;
    if (foundationYear != null) score += 6;
    if (employeeCount != null) score += 8;
    if ((annualRevenueRange ?? '').trim().isNotEmpty) score += 8;
    if (doesManufacture || doesExport || wantsExport) score += 8;
    if (needsMachinery ||
        needsDigitalization ||
        needsCertification ||
        needsFinancing) {
      score += 10;
    }
    if ((mainProducts ?? '').trim().isNotEmpty ||
        (targetMarkets ?? '').trim().isNotEmpty) {
      score += 8;
    }
    if ((taxNumber ?? '').trim().isNotEmpty || (legalName ?? '').trim().isNotEmpty) {
      score += 8;
    }

    return score.clamp(0, 100);
  }

  BusinessProfileModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? legalName,
    String? taxNumber,
    String? taxOffice,
    String? businessType,
    String? sector,
    String? naceCode,
    String? city,
    String? district,
    int? foundationYear,
    int? employeeCount,
    String? annualRevenueRange,
    String? monthlyExpenseRange,
    bool? doesManufacture,
    bool? doesExport,
    bool? wantsExport,
    bool? hasEcommerce,
    bool? hasPhysicalStore,
    bool? needsMachinery,
    bool? needsDigitalization,
    bool? needsCertification,
    bool? needsFinancing,
    double? targetInvestmentAmount,
    bool clearTargetInvestmentAmount = false,
    String? mainProducts,
    String? targetMarkets,
    List<String>? certifications,
    int? profileCompletion,
    bool? onboardingCompleted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      legalName: legalName ?? this.legalName,
      taxNumber: taxNumber ?? this.taxNumber,
      taxOffice: taxOffice ?? this.taxOffice,
      businessType: businessType ?? this.businessType,
      sector: sector ?? this.sector,
      naceCode: naceCode ?? this.naceCode,
      city: city ?? this.city,
      district: district ?? this.district,
      foundationYear: foundationYear ?? this.foundationYear,
      employeeCount: employeeCount ?? this.employeeCount,
      annualRevenueRange: annualRevenueRange ?? this.annualRevenueRange,
      monthlyExpenseRange: monthlyExpenseRange ?? this.monthlyExpenseRange,
      doesManufacture: doesManufacture ?? this.doesManufacture,
      doesExport: doesExport ?? this.doesExport,
      wantsExport: wantsExport ?? this.wantsExport,
      hasEcommerce: hasEcommerce ?? this.hasEcommerce,
      hasPhysicalStore: hasPhysicalStore ?? this.hasPhysicalStore,
      needsMachinery: needsMachinery ?? this.needsMachinery,
      needsDigitalization: needsDigitalization ?? this.needsDigitalization,
      needsCertification: needsCertification ?? this.needsCertification,
      needsFinancing: needsFinancing ?? this.needsFinancing,
      targetInvestmentAmount: clearTargetInvestmentAmount
          ? null
          : targetInvestmentAmount ?? this.targetInvestmentAmount,
      mainProducts: mainProducts ?? this.mainProducts,
      targetMarkets: targetMarkets ?? this.targetMarkets,
      certifications: certifications ?? this.certifications,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BusinessProfileModel.empty({
    String businessName = '',
    String userId = '',
  }) {
    final now = DateTime.now();
    return BusinessProfileModel(
      id: '',
      userId: userId,
      businessName: businessName,
      doesManufacture: false,
      doesExport: false,
      wantsExport: false,
      hasEcommerce: false,
      hasPhysicalStore: false,
      needsMachinery: false,
      needsDigitalization: false,
      needsCertification: false,
      needsFinancing: false,
      certifications: const [],
      profileCompletion: businessName.trim().isNotEmpty ? 10 : 0,
      onboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
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

    return BusinessProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      businessName:
          json['business_name']?.toString() ?? json['businessName']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? json['legalName']?.toString(),
      taxNumber: json['tax_number']?.toString() ?? json['taxNumber']?.toString(),
      taxOffice: json['tax_office']?.toString() ?? json['taxOffice']?.toString(),
      businessType:
          json['business_type']?.toString() ?? json['businessType']?.toString(),
      sector: json['sector']?.toString(),
      naceCode: json['nace_code']?.toString() ?? json['naceCode']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      foundationYear:
          (json['foundation_year'] as num?)?.toInt() ?? (json['foundationYear'] as num?)?.toInt(),
      employeeCount:
          (json['employee_count'] as num?)?.toInt() ?? (json['employeeCount'] as num?)?.toInt(),
      annualRevenueRange: json['annual_revenue_range']?.toString() ??
          json['annualRevenueRange']?.toString(),
      monthlyExpenseRange: json['monthly_expense_range']?.toString() ??
          json['monthlyExpenseRange']?.toString(),
      doesManufacture: json['does_manufacture'] as bool? ??
          json['doesManufacture'] as bool? ??
          false,
      doesExport:
          json['does_export'] as bool? ?? json['doesExport'] as bool? ?? false,
      wantsExport:
          json['wants_export'] as bool? ?? json['wantsExport'] as bool? ?? false,
      hasEcommerce:
          json['has_ecommerce'] as bool? ?? json['hasEcommerce'] as bool? ?? false,
      hasPhysicalStore: json['has_physical_store'] as bool? ??
          json['hasPhysicalStore'] as bool? ??
          false,
      needsMachinery: json['needs_machinery'] as bool? ??
          json['needsMachinery'] as bool? ??
          false,
      needsDigitalization: json['needs_digitalization'] as bool? ??
          json['needsDigitalization'] as bool? ??
          false,
      needsCertification: json['needs_certification'] as bool? ??
          json['needsCertification'] as bool? ??
          false,
      needsFinancing: json['needs_financing'] as bool? ??
          json['needsFinancing'] as bool? ??
          false,
      targetInvestmentAmount: (json['target_investment_amount'] as num?)?.toDouble() ??
          (json['targetInvestmentAmount'] as num?)?.toDouble(),
      mainProducts:
          json['main_products']?.toString() ?? json['mainProducts']?.toString(),
      targetMarkets:
          json['target_markets']?.toString() ?? json['targetMarkets']?.toString(),
      certifications: parseList(json['certifications']),
      profileCompletion: (json['profile_completion'] as num?)?.toInt() ??
          (json['profileCompletion'] as num?)?.toInt() ??
          0,
      onboardingCompleted: json['onboarding_completed'] as bool? ??
          json['onboardingCompleted'] as bool? ??
          false,
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName.trim(),
      'legal_name': legalName?.trim(),
      'tax_number': taxNumber?.trim(),
      'tax_office': taxOffice?.trim(),
      'business_type': businessType,
      'sector': sector?.trim(),
      'nace_code': naceCode?.trim(),
      'city': city?.trim(),
      'district': district?.trim(),
      'foundation_year': foundationYear,
      'employee_count': employeeCount,
      'annual_revenue_range': annualRevenueRange,
      'monthly_expense_range': monthlyExpenseRange,
      'does_manufacture': doesManufacture,
      'does_export': doesExport,
      'wants_export': wantsExport,
      'has_ecommerce': hasEcommerce,
      'has_physical_store': hasPhysicalStore,
      'needs_machinery': needsMachinery,
      'needs_digitalization': needsDigitalization,
      'needs_certification': needsCertification,
      'needs_financing': needsFinancing,
      'target_investment_amount': targetInvestmentAmount,
      'main_products': mainProducts?.trim(),
      'target_markets': targetMarkets?.trim(),
      'certifications': certifications,
      'profile_completion': calculateCompletion(),
      'onboarding_completed': calculateCompletion() >= 70,
      'notes': notes?.trim(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
