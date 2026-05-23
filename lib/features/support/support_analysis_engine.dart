import '../../data/models/business_profile_model.dart';

class SupportAnalysisDraft {
  const SupportAnalysisDraft({
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
    required this.summary,
    required this.opportunities,
    required this.checklist,
  });

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
  final String summary;
  final List<SupportOpportunityDraft> opportunities;
  final List<SupportChecklistDraft> checklist;
}

class SupportOpportunityDraft {
  const SupportOpportunityDraft({
    required this.supportType,
    required this.title,
    required this.description,
    required this.eligibilityScore,
    required this.eligibilityStatus,
    required this.missingRequirements,
    required this.nextSteps,
    required this.priority,
  });

  final String supportType;
  final String title;
  final String description;
  final int eligibilityScore;
  final String eligibilityStatus;
  final List<String> missingRequirements;
  final List<String> nextSteps;
  final String priority;
}

class SupportChecklistDraft {
  const SupportChecklistDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.dueDate,
  });

  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final DateTime? dueDate;
}

SupportAnalysisDraft analyzeSupportEligibility(BusinessProfileModel? profile) {
  final missingProfileFields = <String>{};
  final missingDocuments = <String>{};
  final recommendedActions = <String>{};
  final riskNotes = <String>{};
  final opportunityNotes = <String>{};
  final opportunities = <SupportOpportunityDraft>[];
  final checklist = <SupportChecklistDraft>[];

  if (profile == null || profile.profileCompletion < 40) {
    if (profile == null || (profile.sector ?? '').trim().isEmpty) {
      missingProfileFields.add('Sektör bilgisi');
    }
    if (profile == null || (profile.naceCode ?? '').trim().isEmpty) {
      missingProfileFields.add('NACE kodu');
    }
    if (profile == null || profile.employeeCount == null) {
      missingProfileFields.add('Çalışan sayısı');
    }
    if (profile == null || (profile.annualRevenueRange ?? '').trim().isEmpty) {
      missingProfileFields.add('Yıllık ciro aralığı');
    }

    recommendedActions.addAll(const [
      'İşletme Profili ekranında sektör, NACE kodu, çalışan sayısı ve ciro bilgilerinizi tamamlayın.',
      'Makine, dijitalleşme, belge ve finansman ihtiyaçlarınızı işaretleyin.',
    ]);

    checklist.addAll([
      const SupportChecklistDraft(
        title: 'İşletme profilini tamamlayın',
        description: 'Sektör, NACE kodu, çalışan sayısı ve ciro bilgilerini girin.',
        category: 'profile',
        status: 'pending',
        priority: 'high',
      ),
      const SupportChecklistDraft(
        title: 'İhtiyaç alanlarını netleştirin',
        description: 'Makine, dijitalleşme, belgelendirme ve finansman ihtiyaçlarını işaretleyin.',
        category: 'project',
        status: 'pending',
        priority: 'high',
      ),
    ]);

    return SupportAnalysisDraft(
      analysisTitle: 'Destek Analizi',
      overallScore: profile == null ? 0 : profile.profileCompletion.clamp(0, 30),
      overallStatus: 'needs_profile',
      kosgebScore: 20,
      tubitakScore: 15,
      exportSupportScore: 15,
      certificationSupportScore: 20,
      digitalizationSupportScore: 20,
      financingSupportScore: 20,
      missingProfileFields: missingProfileFields.toList(),
      missingDocuments: const [
        'Vergi levhası',
        'Faaliyet belgesi',
        'KOBİ beyannamesi',
      ],
      recommendedActions: recommendedActions.toList(),
      riskNotes: const [
        'Profil verileri eksik olduğu için ön uygunluk analizi sınırlı kaldı.',
      ],
      opportunityNotes: const [
        'Profil tamamlandığında destek eşleşmeleri daha net üretilebilir.',
      ],
      summary: 'Destek analizi için işletme profilinizi tamamlamanız gerekiyor.',
      opportunities: const [],
      checklist: checklist,
    );
  }

  final missingFieldMap = {
    'NACE kodu': (profile.naceCode ?? '').trim().isEmpty,
    'Çalışan sayısı': profile.employeeCount == null,
    'Yıllık ciro aralığı': (profile.annualRevenueRange ?? '').trim().isEmpty,
    'Yatırım tutarı': (profile.targetInvestmentAmount ?? 0) <= 0,
    'Ana ürün/hizmet bilgisi': (profile.mainProducts ?? '').trim().isEmpty,
    'Hedef pazar bilgisi': (profile.targetMarkets ?? '').trim().isEmpty,
  };
  for (final entry in missingFieldMap.entries) {
    if (entry.value) {
      missingProfileFields.add(entry.key);
    }
  }

  if ((profile.taxNumber ?? '').trim().isEmpty) {
    missingDocuments.add('Vergi levhası');
  }
  if ((profile.legalName ?? '').trim().isEmpty) {
    missingDocuments.add('Faaliyet belgesi');
  }
  if ((profile.naceCode ?? '').trim().isEmpty || profile.employeeCount == null) {
    missingDocuments.add('KOBİ beyannamesi');
  }
  if (profile.doesManufacture) {
    missingDocuments.add('Kapasite raporu');
  }
  if (profile.needsMachinery) {
    missingDocuments.add('Makine/teçhizat proforma faturası');
    missingDocuments.add('Teknik özellik dokümanı');
  }
  if (profile.needsCertification) {
    missingDocuments.add('ISO/TSE/CE belgeleri');
  }

  int bounded(int value) => value.clamp(0, 100);

  var kosgebScore = 25;
  if (profile.profileCompletion >= 70) kosgebScore += 15;
  if (profile.doesManufacture) kosgebScore += 15;
  if (profile.needsMachinery) kosgebScore += 12;
  if (profile.needsDigitalization) kosgebScore += 10;
  if (profile.needsCertification) kosgebScore += 8;
  if ((profile.targetInvestmentAmount ?? 0) > 0) kosgebScore += 10;
  if ((profile.businessType ?? '').trim().isNotEmpty) kosgebScore += 8;
  if ((profile.sector ?? '').trim().isNotEmpty && (profile.naceCode ?? '').trim().isNotEmpty) {
    kosgebScore += 12;
  }
  kosgebScore = bounded(kosgebScore);

  var tubitakScore = 15;
  final sectorLower = (profile.sector ?? '').toLowerCase();
  final mainProductsLower = (profile.mainProducts ?? '').toLowerCase();
  if (profile.needsDigitalization) tubitakScore += 18;
  if (profile.doesManufacture) tubitakScore += 10;
  if ((profile.mainProducts ?? '').trim().isNotEmpty) tubitakScore += 12;
  if ((profile.targetInvestmentAmount ?? 0) > 0) tubitakScore += 8;
  if (sectorLower.contains('teknoloji') ||
      sectorLower.contains('yazılım') ||
      sectorLower.contains('imalat') ||
      mainProductsLower.contains('otomasyon') ||
      mainProductsLower.contains('yazılım')) {
    tubitakScore += 22;
  }
  tubitakScore = bounded(tubitakScore);

  var exportScore = 10;
  if (profile.doesExport) exportScore += 30;
  if (profile.wantsExport) exportScore += 20;
  if ((profile.targetMarkets ?? '').trim().isNotEmpty) exportScore += 15;
  if (profile.certifications.any((c) {
    final lower = c.toLowerCase();
    return lower.contains('ce') || lower.contains('iso') || lower.contains('tse');
  })) {
    exportScore += 12;
  }
  if (profile.hasEcommerce || (profile.targetMarkets ?? '').toLowerCase().contains('b2b')) {
    exportScore += 10;
  }
  exportScore = bounded(exportScore);

  var certificationScore = 10;
  if (profile.needsCertification) certificationScore += 35;
  if (profile.doesManufacture) certificationScore += 20;
  if (profile.wantsExport || profile.doesExport) certificationScore += 15;
  if (profile.certifications.isEmpty) certificationScore += 10;
  certificationScore = bounded(certificationScore);

  var digitalizationScore = 15;
  if (profile.needsDigitalization) digitalizationScore += 35;
  if (!profile.hasEcommerce && (profile.targetMarkets ?? '').trim().isNotEmpty) {
    digitalizationScore += 12;
  }
  if ((profile.notes ?? '').toLowerCase().contains('dijital')) {
    digitalizationScore += 10;
  }
  if (profile.profileCompletion >= 70) {
    digitalizationScore += 8;
  }
  digitalizationScore = bounded(digitalizationScore);

  var financingScore = 15;
  if (profile.needsFinancing) financingScore += 30;
  if (profile.doesExport || profile.wantsExport) financingScore += 15;
  if ((profile.targetInvestmentAmount ?? 0) > 0) financingScore += 18;
  if ((profile.annualRevenueRange ?? '').trim().isNotEmpty) financingScore += 12;
  financingScore = bounded(financingScore);

  final weightedAverage = (
    kosgebScore * 0.22 +
    tubitakScore * 0.14 +
    exportScore * 0.18 +
    certificationScore * 0.14 +
    digitalizationScore * 0.16 +
    financingScore * 0.16
  );
  final completionPenalty = profile.profileCompletion < 70 ? 8 : 0;
  final overallScore = bounded(weightedAverage.round() - completionPenalty);
  final overallStatus = overallScore >= 75
      ? 'high_potential'
      : overallScore >= 45
          ? 'medium_potential'
          : 'low_potential';

  SupportOpportunityDraft buildOpportunity({
    required String type,
    required String title,
    required String description,
    required int score,
    required List<String> missingRequirements,
    required List<String> nextSteps,
  }) {
    final eligibilityStatus = score >= 75
        ? 'high'
        : score >= 45
            ? 'medium'
            : missingRequirements.isNotEmpty
                ? 'needs_info'
                : 'low';
    final priority = score >= 70
        ? 'high'
        : score >= 40
            ? 'medium'
            : 'low';
    return SupportOpportunityDraft(
      supportType: type,
      title: title,
      description: description,
      eligibilityScore: score,
      eligibilityStatus: eligibilityStatus,
      missingRequirements: missingRequirements,
      nextSteps: nextSteps,
      priority: priority,
    );
  }

  final kosgebMissing = <String>[
    if ((profile.naceCode ?? '').trim().isEmpty) 'NACE kodu',
    if (profile.employeeCount == null) 'Çalışan sayısı',
    if ((profile.annualRevenueRange ?? '').trim().isEmpty) 'Yıllık ciro aralığı',
    if ((profile.targetInvestmentAmount ?? 0) <= 0) 'Yatırım tutarı',
    if ((profile.mainProducts ?? '').trim().isEmpty) 'Ana ürün/hizmet bilgisi',
  ];
  opportunities.add(
    buildOpportunity(
      type: 'kosgeb',
      title: 'KOSGEB Ön Uygunluk Potansiyeli',
      description:
          'İşletme profilinize göre KOSGEB destekleri için ön değerlendirme yapılabilir.',
      score: kosgebScore,
      missingRequirements: kosgebMissing,
      nextSteps: const [
        'KOBİ beyannamesi ve işletme bilgilerini güncelleyin.',
        'Yatırım veya makine ihtiyacını netleştirin.',
        'Gider-faaliyet ilişkisini açıklamaya hazırlanın.',
      ],
    ),
  );

  final tubitakMissing = <String>[
    if ((profile.mainProducts ?? '').trim().isEmpty) 'Ana ürün/hizmet bilgisi',
    if ((profile.targetInvestmentAmount ?? 0) <= 0) 'Yatırım tutarı',
    if ((profile.notes ?? '').trim().isEmpty) 'Ar-Ge veya dijitalleşme proje notu',
  ];
  opportunities.add(
    buildOpportunity(
      type: 'tubitak',
      title: 'TÜBİTAK / Ar-Ge Potansiyeli',
      description:
          'Ar-Ge, dijitalleşme veya üretim geliştirme ihtiyacı olan işletmeler için ön potansiyel görünüyor.',
      score: tubitakScore,
      missingRequirements: tubitakMissing,
      nextSteps: const [
        'Ar-Ge veya dijitalleşme hedefinizi kısa proje cümlesiyle netleştirin.',
        'Ürün, süreç veya yazılım geliştirme ihtiyacını örnekleyin.',
      ],
    ),
  );

  final exportMissing = <String>[
    if ((profile.targetMarkets ?? '').trim().isEmpty) 'Hedef pazar bilgisi',
    if (profile.certifications.isEmpty) 'Sertifika bilgileri',
    if (!profile.doesExport && !profile.wantsExport) 'İhracat hedefi',
  ];
  opportunities.add(
    buildOpportunity(
      type: 'export',
      title: 'Ticaret Bakanlığı / İhracat Destekleri Potansiyeli',
      description:
          'İhracat veya yeni pazarlara açılma planları için destek potansiyeli görülebilir.',
      score: exportScore,
      missingRequirements: exportMissing,
      nextSteps: const [
        'Hedef pazar bilgilerini netleştirin.',
        'Ürün/hizmet tanıtım metinlerini hazırlayın.',
        'İhracat belgeleri ve sertifikaları kontrol edin.',
      ],
    ),
  );

  final certificationMissing = <String>[
    if (profile.certifications.isEmpty) 'Mevcut sertifika bilgileri',
    if ((profile.mainProducts ?? '').trim().isEmpty) 'Ürün grubu ve teknik gereklilikler',
  ];
  opportunities.add(
    buildOpportunity(
      type: 'certification',
      title: 'TSE / ISO / CE Belgelendirme İhtiyacı',
      description:
          'Belgelendirme ihtiyacı olan üretim veya ihracat odaklı işletmeler için ön analiz sunulur.',
      score: certificationScore,
      missingRequirements: certificationMissing,
      nextSteps: const [
        'Ürün gruplarını ve mevcut sertifikaları listeleyin.',
        'Belgelendirme için gerekli teknik dokümanları hazırlayın.',
      ],
    ),
  );

  final digitalizationMissing = <String>[
    if ((profile.mainProducts ?? '').trim().isEmpty) 'Ana ürün/hizmet bilgisi',
    if (!profile.hasEcommerce) 'Dijital satış veya kanal bilgisi',
  ];
  opportunities.add(
    buildOpportunity(
      type: 'digitalization',
      title: 'Dijitalleşme ve Verimlilik Desteği Potansiyeli',
      description:
          'Operasyon, satış veya süreç verimliliğini artıracak dijitalleşme yatırımları için ön potansiyel oluşabilir.',
      score: digitalizationScore,
      missingRequirements: digitalizationMissing,
      nextSteps: const [
        'Dijitalleşme ihtiyacını süreç bazında netleştirin.',
        'E-ticaret, yazılım veya otomasyon önceliğini belirleyin.',
      ],
    ),
  );

  final financingMissing = <String>[
    if ((profile.annualRevenueRange ?? '').trim().isEmpty) 'Yıllık ciro aralığı',
    if ((profile.targetInvestmentAmount ?? 0) <= 0) 'Yatırım tutarı',
    if (!profile.needsFinancing) 'Finansman ihtiyacı beyanı',
  ];
  opportunities.add(
    buildOpportunity(
      type: 'financing',
      title: 'Finansman / Eximbank Potansiyeli',
      description:
          'Yatırım, ihracat veya işletme sermayesi ihtiyacı için finansman desteği potansiyeli görülebilir.',
      score: financingScore,
      missingRequirements: financingMissing,
      nextSteps: const [
        'Yatırım veya işletme sermayesi ihtiyacını tutar bazında netleştirin.',
        'Gelir ölçeği ve ihracat hedefi bilgilerini güncelleyin.',
      ],
    ),
  );

  if (overallScore >= 75) {
    opportunityNotes.add('Profilinize göre birden fazla destek başlığında güçlü ön potansiyel görünüyor.');
  } else if (overallScore >= 45) {
    opportunityNotes.add('Bazı destek başlıklarında ön potansiyel var; eksik bilgiler tamamlandıkça netleşebilir.');
  } else {
    riskNotes.add('Destek potansiyeli sınırlı görünüyor; profil ve ihtiyaç tanımı güçlendirilmeli.');
  }

  if (missingProfileFields.isNotEmpty) {
    riskNotes.add('Eksik profil alanları ön uygunluk skorlarını aşağı çekiyor.');
  }
  if (missingDocuments.isNotEmpty) {
    riskNotes.add('Belge hazırlığı eksikleri başvuru sürecini yavaşlatabilir.');
  }
  if (profile.doesExport || profile.wantsExport) {
    opportunityNotes.add('İhracat hedefi, finansman ve belgelendirme tarafında ek fırsatlar açabilir.');
  }

  recommendedActions.addAll([
    if (missingProfileFields.isNotEmpty)
      'Eksik profil alanlarını tamamlayarak analiz doğruluğunu artırın.',
    if (missingDocuments.isNotEmpty)
      'Önce temel belge listenizi toparlayın ve başvuru klasörü oluşturun.',
    if (kosgebScore >= 60)
      'KOSGEB için yatırım, faaliyet ve KOBİ bilgilerinizi başvuru diline uygun netleştirin.',
    if (exportScore >= 55)
      'İhracat için hedef pazar ve sertifika hazırlığını öne alın.',
    if (digitalizationScore >= 55)
      'Dijitalleşme ihtiyacını satış, operasyon veya verimlilik başlıklarıyla somutlaştırın.',
  ]);

  for (final field in missingProfileFields.take(3)) {
    checklist.add(
      SupportChecklistDraft(
        title: '$field bilgisini tamamlayın',
        description: 'Destek analizi için bu bilgi önemli görünüyor.',
        category: 'profile',
        status: 'pending',
        priority: 'high',
      ),
    );
  }
  for (final document in missingDocuments.take(5)) {
    checklist.add(
      SupportChecklistDraft(
        title: '$document hazırlayın',
        description: 'Başvuru öncesi belge setinizi güçlendirmek için gereklidir.',
        category: 'document',
        status: 'pending',
        priority: 'medium',
      ),
    );
  }
  checklist.addAll(const [
    SupportChecklistDraft(
      title: 'Destek başlığına göre proje amacını yazın',
      description: 'Yatırım, dijitalleşme veya ihracat hedefinizi kısa cümlelerle hazırlayın.',
      category: 'project',
      status: 'pending',
      priority: 'medium',
    ),
    SupportChecklistDraft(
      title: 'Başvuru önceliğini belirleyin',
      description: 'İlk olarak hangi destek başlığına odaklanacağınıza karar verin.',
      category: 'application',
      status: 'pending',
      priority: 'medium',
    ),
  ]);

  final summary = overallScore >= 75
      ? 'Profilinize göre KOSGEB, dijitalleşme ve ilgili desteklerde güçlü bir ön potansiyel görünüyor.'
      : overallScore >= 45
          ? 'Profilinize göre bazı destek başlıklarında ön potansiyel var; eksik bilgi ve belgeler tamamlandığında tablo netleşir.'
          : 'Destek potansiyeliniz bazı alanlarda sınırlı görünüyor; önce profil ve belge hazırlığını güçlendirmek iyi olur.';

  return SupportAnalysisDraft(
    analysisTitle: 'Destek Analizi',
    overallScore: overallScore,
    overallStatus: overallStatus,
    kosgebScore: kosgebScore,
    tubitakScore: tubitakScore,
    exportSupportScore: exportScore,
    certificationSupportScore: certificationScore,
    digitalizationSupportScore: digitalizationScore,
    financingSupportScore: financingScore,
    missingProfileFields: missingProfileFields.toList(),
    missingDocuments: missingDocuments.toList(),
    recommendedActions: recommendedActions.toList(),
    riskNotes: riskNotes.toList(),
    opportunityNotes: opportunityNotes.toList(),
    summary: summary,
    opportunities: opportunities,
    checklist: checklist,
  );
}
