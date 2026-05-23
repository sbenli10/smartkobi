import '../../data/models/ai_advisor_response_model.dart';
import '../../data/models/business_context_summary_model.dart';
import 'advisor_scope_guard.dart';

AiAdvisorResponseModel generateFallbackAdvisorResponse({
  required String question,
  required BusinessContextSummaryModel context,
}) {
  final scope = classifyAdvisorQuestion(question);
  final topic = scope.topic;
  final module = advisorTopicToModule(topic);
  final now = DateTime.now();

  if (scope.decision == AdvisorScopeDecision.outOfScope) {
    return buildOutOfScopeResponse(question);
  }

  if (scope.decision == AdvisorScopeDecision.ambiguous) {
    return buildAmbiguousResponse(question);
  }

  if (!_hasAnyData(context)) {
    return AiAdvisorResponseModel(
      answer:
          'Henüz yeterli işletme verisi yok. Gelir-gider, cari, stok ve nakit kayıtlarınızı ekledikçe SmartKOBİ daha isabetli öneriler sunar.',
      riskLevel: 'medium',
      suggestedActions: const [
        'İlk gelir ve gider kayıtlarını ekleyin.',
        'Cari ve stok modüllerindeki temel kayıtları tamamlayın.',
      ],
      relatedModule: module,
      usedFallback: true,
      createdAt: now,
    );
  }
  switch (topic) {
    case AdvisorTopic.cashflow:
      return AiAdvisorResponseModel(
        answer: [
          'Durum: ${context.cashScore < 60 ? 'Nakit akışınız dikkat gerektiriyor.' : 'Nakit görünümünüz genel olarak dengeli görünüyor.'}',
          'Risk/Fırsat: ${context.netCash30d < 0 ? '30 günlük net nakit negatif görünüyor.' : '30 günlük net nakit şu an pozitif tarafta.'}',
          'Neden: ${context.expectedCashOutflow30d > context.expectedCashInflow30d ? 'Beklenen ödemeler tahsilatların üzerinde.' : 'Tahsilat ve ödeme dengesi kısa vadede yönetilebilir seviyede.'}',
          'Önerilen aksiyon: ${context.overdueReceivables > 0 ? 'Geciken tahsilatları önceliklendirin ve yeni büyük harcamaları gözden geçirin.' : 'Yeni gider öncesi 30 günlük tahmini tekrar kontrol edin.'}',
          'Sonraki adım: Nakit AI ekranında 30 günlük tahmini ve yaklaşan ödemeleri inceleyin.',
        ].join('\n'),
        riskLevel: context.cashScore < 40
            ? 'critical'
            : context.cashScore < 60
                ? 'high'
                : context.cashScore < 80
                    ? 'medium'
                    : 'low',
        suggestedActions: [
          if (context.overdueReceivables > 0) 'Geciken tahsilatları bugün önceliklendirin.',
          'Yaklaşan büyük ödemeler için kısa vadeli nakit planı oluşturun.',
          'Yeni harcama öncesi Nakit AI senaryo analizini kullanın.',
        ],
        relatedModule: 'cashflow',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.customers:
      if (context.pendingReceivables <= 0 && context.overdueReceivables <= 0) {
        return AiAdvisorResponseModel(
          answer: [
            'Durum: Cari ve tahsilat önceliği için müşteri bakiyeleri ile vade tarihleri gerekir.',
            'Öncelik: Şu an sıralama yapacak yeterli tahsilat verisi görünmüyor.',
            'Neden: Bekleyen veya geciken tahsilat kaydı bulunmadığında müşteri önceliği netleşmez.',
            'Önerilen aksiyon: Cari ekranında müşterilerinizi, bakiyeleri ve tahsilat tarihlerini ekleyin.',
            'Sonraki adım: Müşteri detayında tahsilat hareketi oluşturarak sıralamayı güçlendirin.',
          ].join('\n'),
          riskLevel: 'medium',
          suggestedActions: const [
            'Müşteri bakiyelerini ve vade tarihlerini Cari ekranına ekleyin.',
            'Tahsilat hareketlerinde bekleyen ve geciken durumlarını işaretleyin.',
          ],
          relatedModule: 'customers',
          usedFallback: true,
          createdAt: now,
        );
      }

      return AiAdvisorResponseModel(
        answer: [
          'Durum: Tahsilat önceliği cari risklere göre belirlenmeli.',
          'Öncelik: ${context.overdueReceivables > 0 ? 'Önce vadesi geçmiş ve bakiyesi yüksek müşterilerle başlayın.' : 'Önce bakiyesi yüksek ve vadesi yaklaşan müşterileri öne alın.'}',
          'Neden: ${context.overdueReceivables > 0 ? 'Geciken tahsilatlar nakit akışınızı doğrudan etkiler.' : 'Bekleyen tahsilatlar kısa vadeli nakit görünümünü etkileyebilir.'}',
          'Önerilen aksiyon: Cari ekranında geciken müşterileri filtreleyin ve ödeme hatırlatması gönderin.',
          'Sonraki adım: Müşteri detayında WhatsApp veya e-posta hatırlatma metni oluşturun.',
        ].join('\n'),
        riskLevel: context.overdueReceivables > 0 || context.customerRiskCount > 0
            ? 'high'
            : 'medium',
        suggestedActions: [
          if (context.overdueReceivables > 0)
            'Önce geciken tahsilatı olan müşterileri önceliklendirin.',
          'Yüksek cari bakiyesi olan müşteriler için kısa tahsilat planı oluşturun.',
          'Vadesi yaklaşan müşterilere proaktif hatırlatma gönderin.',
        ],
        relatedModule: 'customers',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.inventory:
      return AiAdvisorResponseModel(
        answer: [
          'Durum: ${context.hasInventoryRisk ? 'Stok tarafında kontrol edilmesi gereken ürünler var.' : 'Stok görünümünüz dengeli görünüyor.'}',
          'Risk/Fırsat: ${context.criticalStockCount > 0 || context.outOfStockCount > 0 ? 'Kritik stoktaki ürünler satış kaybına neden olabilir.' : 'Stok planı korunursa tedarik sürekliliği desteklenebilir.'}',
          'Neden: ${context.lowMarginProductCount > 0 ? 'Bazı ürünlerin kâr marjı düşük görünüyor.' : 'Kritik ve düşük marjlı ürün sayısı sınırlı görünüyor.'}',
          'Önerilen aksiyon: Minimum stok seviyesine yaklaşan ürünler için tedarik planı oluşturun.',
          'Sonraki adım: Stok ekranında kritik ve düşük marjlı ürün filtrelerini açın.',
        ].join('\n'),
        riskLevel: context.outOfStockCount > 0
            ? 'high'
            : context.criticalStockCount > 0 || context.lowMarginProductCount > 0
                ? 'medium'
                : 'low',
        suggestedActions: [
          if (context.criticalStockCount > 0) 'Kritik stoktaki ürünler için sipariş planı hazırlayın.',
          if (context.lowMarginProductCount > 0)
            'Düşük marjlı ürünlerde alış ve satış fiyatlarını gözden geçirin.',
        ],
        relatedModule: 'inventory',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.support:
    case AdvisorTopic.documents:
      return AiAdvisorResponseModel(
        answer: [
          'Durum: ${context.supportOverallScore > 0 ? 'Destek analizi verilerinize göre ön uygunluk tablosu oluştu.' : 'Destek uygunluğu için önce işletme profilinizi ve analiz verinizi oluşturmanız gerekiyor.'}',
          'Risk/Fırsat: ${context.highPriorityMissingDocuments > 0 ? 'Başvuru hazırlığı için yüksek öncelikli eksik belgeleriniz var.' : context.expiredDocumentsCount > 0 ? 'Süresi geçen belgeler hazırlık sürecini zayıflatabilir.' : context.supportOverallScore >= 75 ? 'Bazı destek başlıklarında güçlü potansiyel görünüyor.' : context.supportOverallScore >= 45 ? 'Bazı desteklerde geliştirilebilir bir potansiyel var.' : 'Eksik bilgi ve belge nedeniyle tablo henüz sınırlı görünüyor.'}',
          'Neden: ${context.topSupportOpportunities.isNotEmpty ? context.topSupportOpportunities.first : context.missingSupportDocuments.isNotEmpty ? '${context.missingSupportDocuments.first} belgesi hazırlık listesinde öne çıkıyor.' : 'Sektör, NACE kodu, çalışan sayısı, ciro ve belge hazırlığı bu değerlendirmede belirleyicidir.'}',
          'Önerilen aksiyon: ${context.supportRecommendedActions.isNotEmpty ? context.supportRecommendedActions.first : context.missingDocumentsCount > 0 ? 'Belgelerim ekranında eksik belge listenizi tamamlayın.' : 'Destek Analizi ekranındaki eksik profil ve belge alanlarını tamamlayın.'}',
          'Sonraki adım: ${context.missingSupportDocuments.isNotEmpty ? '${context.missingSupportDocuments.first} belgesinden başlayarak başvuru klasörünüzü hazırlayın.' : context.totalDocuments > 0 ? 'Belgelerim ekranında süresi yaklaşan ve eksik belgeleri gözden geçirin.' : 'Destek Analizi ekranında fırsatlar ve hazırlık checklistini gözden geçirin.'}',
        ].join('\n'),
        riskLevel: context.supportOverallScore >= 75
            ? 'low'
            : context.supportOverallScore >= 45
                ? 'medium'
                : 'high',
        suggestedActions: [
          if (context.supportRecommendedActions.isNotEmpty)
            ...context.supportRecommendedActions.take(2),
          if (context.missingSupportDocuments.isNotEmpty)
            'Eksik belge listenizi tamamlayın.',
          if (context.expiredDocumentsCount > 0)
            'Süresi geçen belgeleri yenileyin.',
          if (context.supportRecommendedActions.isEmpty &&
              context.missingSupportDocuments.isEmpty)
            'Destek Analizi ekranında ilk analizi başlatın.',
        ],
        relatedModule: 'support',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.sales:
    case AdvisorTopic.pricing:
      return AiAdvisorResponseModel(
        answer: [
          'Durum: Satış ve fiyatlandırma tarafında kısa bir ön değerlendirme yapıldı.',
          'Risk/Fırsat: ${context.lowMarginProductCount > 0 ? 'Bazı ürünlerde düşük marj satış kârlılığını baskılayabilir.' : 'Fiyat ve marj yönetimi büyüme fırsatı yaratabilir.'}',
          'Neden: ${context.monthlyIncome > 0 ? 'Gelir, marj ve ürün görünümü birlikte değerlendirildi.' : 'Satış tarafında daha güçlü yorum için düzenli veri girişi gerekir.'}',
          'Önerilen aksiyon: Düşük marjlı ürünler ve sık satış yapılan kalemlerde fiyat yapısını gözden geçirin.',
          'Sonraki adım: Stok ve Finans ekranlarında ürün bazlı marj ve gider etkisini inceleyin.',
        ].join('\n'),
        riskLevel: context.lowMarginProductCount > 0 ? 'medium' : 'low',
        suggestedActions: const [
          'En çok satan ürünlerde marj kontrolü yapın.',
          'İskonto ve zam etkisini satış verileriyle birlikte değerlendirin.',
        ],
        relatedModule: 'finance',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.reporting:
      final latestReportName = _reportTypeLabel(context.latestReportType);
      final reportSuggestion = _chooseRecommendedReport(context);
      return AiAdvisorResponseModel(
        answer: [
          'Durum: Rapor ihtiyacınız işletmenin önceliğine göre şekillenmeli.',
          'Öneri: ${reportSuggestion['title']} sizin için iyi bir başlangıç olabilir.',
          'Neden: ${reportSuggestion['reason']}',
          'Mevcut görünüm: ${context.latestReportSummary ?? (latestReportName == null ? 'Henüz oluşturulmuş bir rapor görünmüyor.' : 'Son raporunuz $latestReportName olarak görünüyor.')}',
          'Sonraki adım: Raporlar ekranında ilgili raporu oluşturup yönetici özetini ve önerilen aksiyonları inceleyin.',
        ].join('\n'),
        riskLevel: context.overallRiskLevel == 'high' ? 'high' : 'medium',
        suggestedActions: [
          'Önce ${reportSuggestion['title']} oluşturun.',
          if (context.latestReportActions.isNotEmpty) context.latestReportActions.first,
          'PDF çıktısı ile raporu kaydedin ve paylaşılabilir hale getirin.',
        ],
        relatedModule: 'reports',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.finance:
    case AdvisorTopic.tax:
      final expenseRatio = context.monthlyIncome > 0
          ? context.monthlyExpense / context.monthlyIncome
          : 0;
      return AiAdvisorResponseModel(
        answer: [
          'Durum: Finansal kayıtlarınız üzerinden ön değerlendirme yapıldı.',
          'Risk/Fırsat: ${expenseRatio > 0.7 ? 'Gider/gelir oranı yüksek görünüyor.' : 'Net kâr görünümü şu an yönetilebilir seviyede.'}',
          'Neden: ${context.netProfit < 0 ? 'Bu ay giderler gelirleri aşmış görünüyor.' : 'Bu ay net kâr tarafında pozitif görünüm var.'}',
          'Önerilen aksiyon: En yüksek gider kategorilerini gözden geçirip kârlılığı baskılayan kalemleri ayırın.',
          'Sonraki adım: Finans ekranında bekleyen ödemeler ve gider dağılımını inceleyin.',
        ].join('\n'),
        riskLevel: context.netProfit < 0 || expenseRatio > 0.8
            ? 'high'
            : expenseRatio > 0.65
                ? 'medium'
                : 'low',
        suggestedActions: const [
          'Bu ayın en yüksek gider kategorilerini not alın.',
          'Net kârı baskılayan kalemler için kısa tasarruf planı oluşturun.',
        ],
        relatedModule: 'finance',
        usedFallback: true,
        createdAt: now,
      );
    case AdvisorTopic.generalBusiness:
    case AdvisorTopic.outOfScope:
      return AiAdvisorResponseModel(
        answer: [
          'Durum: İşletmenizin genel görünümü için kısa bir ön analiz hazırlandı.',
          'Risk/Fırsat: ${context.topRisks.isNotEmpty ? context.topRisks.first : 'Belirgin bir kırmızı bayrak görünmüyor, ancak kayıt derinliği artırılabilir.'}',
          'Neden: ${context.summaryText ?? 'Mevcut finans, cari, stok ve nakit verileri birlikte değerlendirildi.'}',
          'Önerilen aksiyon: ${context.topOpportunities.isNotEmpty ? context.topOpportunities.first : 'Kayıt düzenini güçlendirmek karar kalitesini artırabilir.'}',
          'Sonraki adım: Finans, Cari, Stok ve Nakit AI modüllerindeki eksik kayıtları tamamlayın.',
        ].join('\n'),
        riskLevel: context.overallRiskLevel == 'high' ? 'high' : 'medium',
        suggestedActions: [
          if (context.topRisks.isNotEmpty) context.topRisks.first,
          if (context.topOpportunities.isNotEmpty) context.topOpportunities.first,
          'Bu ay işletmemin durumu nasıl? sorusuyla yeni bir özet isteyin.',
        ],
        relatedModule: 'general',
        usedFallback: true,
        createdAt: now,
      );
  }
}

Map<String, String> _chooseRecommendedReport(BusinessContextSummaryModel context) {
  if (context.missingDocumentsCount > 0 || context.expiredDocumentsCount > 0) {
    return {
      'title': 'Eksik Belge Raporu',
      'reason': 'Belge hazırlığı ve başvuru eksikleri şu an karar kalitesini doğrudan etkiliyor.',
    };
  }
  if (context.supportOverallScore > 0 &&
      (context.supportOverallScore < 70 || context.profileCompletion < 70)) {
    return {
      'title': 'Destek Uygunluk Raporu',
      'reason': 'Destek potansiyeli ile profil eksiklerinin birlikte görülmesi faydalı olur.',
    };
  }
  if (context.overdueReceivables > 0 || context.pendingReceivables > 0) {
    return {
      'title': 'Cari / Tahsilat Risk Raporu',
      'reason': 'Tahsilat önceliği kısa vadeli nakit görünümünü etkiliyor.',
    };
  }
  if (context.cashScore < 60 || context.netCash30d < 0) {
    return {
      'title': 'Nakit Akışı Raporu',
      'reason': 'Kısa vadeli nakit planı şu an en kritik görünüm olabilir.',
    };
  }
  if (context.criticalStockCount > 0 || context.outOfStockCount > 0) {
    return {
      'title': 'Stok Risk Raporu',
      'reason': 'Stok riski operasyon akışını etkileyebilecek seviyede olabilir.',
    };
  }
  return {
    'title': 'KOBİ Sağlık Raporu',
    'reason': 'İşletmenin genel finans, cari, stok, destek ve belge görünümünü tek yerde toplar.',
  };
}

String? _reportTypeLabel(String? type) {
  switch (type) {
    case 'business_health':
      return 'KOBİ Sağlık Raporu';
    case 'financial_summary':
      return 'Finansal Özet Raporu';
    case 'cashflow':
      return 'Nakit Akışı Raporu';
    case 'customer_risk':
      return 'Cari / Tahsilat Risk Raporu';
    case 'inventory_risk':
      return 'Stok Risk Raporu';
    case 'support_eligibility':
      return 'Destek Uygunluk Raporu';
    case 'document_gap':
      return 'Eksik Belge Raporu';
    case 'daily_action_plan':
      return 'Günlük İş Planı Raporu';
    case 'weekly_action_plan':
      return 'Haftalık İş Planı Raporu';
    default:
      return null;
  }
}

AiAdvisorResponseModel buildOutOfScopeResponse(String question) {
  return AiAdvisorResponseModel(
    answer:
        'Ben SmartKOBİ Danışmanıyım. Finans, nakit akışı, cari, stok, destekler, satış, maliyet ve işletme kararları konusunda yardımcı olabilirim. Bu konu SmartKOBİ kapsamı dışında kalıyor. İsterseniz işletmenizle ilgili bir soru sorabilirsiniz.',
    riskLevel: 'low',
    suggestedActions: const [
      'Nakit akışım riskli mi?',
      'Bu ay yeni harcama yapabilir miyim?',
      'Hangi müşteriden tahsilat yapmalıyım?',
      'Hangi ürünler kritik stokta?',
    ],
    relatedModule: 'general',
    usedFallback: true,
    createdAt: DateTime.now(),
  );
}

AiAdvisorResponseModel buildAmbiguousResponse(String question) {
  return AiAdvisorResponseModel(
    answer:
        'Bu soruyu işletmenizle ilgili olarak mı değerlendirmemi istersiniz? Eğer maliyet, satış, nakit akışı veya yatırım açısından soruyorsanız detay vererek tekrar yazabilirsiniz.',
    riskLevel: 'low',
    suggestedActions: const [
      'İşletme için bu harcamayı yapabilir miyim?',
      'Bu alım nakit akışımı zorlar mı?',
      'Satış ve maliyet açısından değerlendirir misin?',
    ],
    relatedModule: 'general',
    usedFallback: true,
    createdAt: DateTime.now(),
  );
}

bool _hasAnyData(BusinessContextSummaryModel context) {
  return context.hasFinancialData ||
      context.pendingReceivables > 0 ||
      context.expectedCashInflow30d > 0 ||
      context.expectedCashOutflow30d > 0 ||
      context.criticalStockCount > 0 ||
      context.customerRiskCount > 0;
}
