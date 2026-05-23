import '../../data/models/report_summary_model.dart';

class GeneratedReportDraft {
  const GeneratedReportDraft({
    required this.title,
    required this.summary,
    required this.keyFindings,
    required this.risks,
    required this.opportunities,
    required this.recommendedActions,
    required this.reportData,
    required this.sections,
    this.periodLabel,
  });

  final String title;
  final String summary;
  final List<String> keyFindings;
  final List<String> risks;
  final List<String> opportunities;
  final List<String> recommendedActions;
  final Map<String, dynamic> reportData;
  final List<GeneratedReportSectionDraft> sections;
  final String? periodLabel;
}

class GeneratedReportSectionDraft {
  const GeneratedReportSectionDraft({
    required this.sectionKey,
    required this.title,
    required this.content,
    required this.sortOrder,
    this.sectionData = const <String, dynamic>{},
  });

  final String sectionKey;
  final String title;
  final String content;
  final int sortOrder;
  final Map<String, dynamic> sectionData;
}

GeneratedReportDraft generateReportDraft({
  required String reportType,
  required ReportSummaryModel summary,
  required Map<String, dynamic> moduleData,
  DateTime? periodStart,
  DateTime? periodEnd,
}) {
  switch (reportType) {
    case 'business_health':
      return _buildBusinessHealthReport(summary, moduleData, periodStart, periodEnd);
    case 'financial_summary':
      return _buildFinancialSummaryReport(summary, moduleData, periodStart, periodEnd);
    case 'cashflow':
      return _buildCashflowReport(summary, moduleData, periodStart, periodEnd);
    case 'customer_risk':
      return _buildCustomerRiskReport(summary, moduleData, periodStart, periodEnd);
    case 'inventory_risk':
      return _buildInventoryRiskReport(summary, moduleData, periodStart, periodEnd);
    case 'support_eligibility':
      return _buildSupportReport(summary, moduleData, periodStart, periodEnd);
    case 'document_gap':
      return _buildDocumentGapReport(summary, moduleData, periodStart, periodEnd);
    case 'weekly_action_plan':
      return _buildActionPlanReport(
        summary,
        moduleData,
        periodStart,
        periodEnd,
        weekly: true,
      );
    case 'daily_action_plan':
    default:
      return _buildActionPlanReport(
        summary,
        moduleData,
        periodStart,
        periodEnd,
        weekly: false,
      );
  }
}

GeneratedReportDraft _buildBusinessHealthReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final profile = _map(data['businessProfile']);
  final financial = _map(data['financial']);
  final cashflow = _map(data['cashflow']);
  final customer = _map(data['customerRisk']);
  final inventory = _map(data['inventoryRisk']);
  final support = _map(data['support']);
  final documents = _map(data['documents']);

  final keyFindings = <String>[
    'Aylık net sonuç ${_signedMoney(summary.netProfit)} seviyesinde görünüyor.',
    'Nakit skoru ${summary.cashScore}/100 olarak değerlendirildi.',
    'Bekleyen tahsilat ${_money(summary.pendingReceivables)}, vadesi geçmiş tahsilat ${_money(summary.overdueReceivables)} düzeyinde.',
  ];
  final risks = _collectRisks(summary, customer, inventory, documents, support);
  final opportunities = _collectOpportunities(summary, support, inventory);
  final actions = _collectActions(summary, support, documents);

  return GeneratedReportDraft(
    title: 'KOBİ Sağlık Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        '${summary.executiveSummary} Bu çıktı ön analiz ve yönetim özeti amacıyla hazırlanmıştır.',
    keyFindings: keyFindings,
    risks: risks,
    opportunities: opportunities,
    recommendedActions: actions,
    reportData: {
      'uyari': 'Bu rapor ön analiz ve karar destek amacıyla hazırlanmıştır.',
      'metrikler': _baseMetrics(summary),
      'isletme_profili': profile,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'executive_summary',
        title: 'Yönetici Özeti',
        content: summary.executiveSummary,
        sortOrder: 0,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'financial_status',
        title: 'Finansal Durum',
        content:
            'Aylık gelir ${_money(summary.monthlyIncome)}, aylık gider ${_money(summary.monthlyExpense)} ve net sonuç ${_signedMoney(summary.netProfit)} olarak özetlenmiştir.',
        sortOrder: 1,
        sectionData: financial,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'cashflow',
        title: 'Nakit Akışı',
        content:
            '30 günlük net nakit görünümü ${_signedMoney(summary.netCash30d)} seviyesindedir. Nakit skoru ${summary.cashScore}/100 olup kısa vadeli akış düzenli takip edilmelidir.',
        sortOrder: 2,
        sectionData: cashflow,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'customer_risk',
        title: 'Cari ve Tahsilat',
        content:
            'Bekleyen tahsilatlar ${_money(summary.pendingReceivables)}, vadesi geçmiş tahsilatlar ${_money(summary.overdueReceivables)} düzeyindedir. Öncelik sıralaması cari risk üzerinden yapılmalıdır.',
        sortOrder: 3,
        sectionData: customer,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'inventory_status',
        title: 'Stok Durumu',
        content:
            'Kritik stoktaki ürün sayısı ${summary.criticalStockCount}, stokta olmayan ürün sayısı ${summary.outOfStockCount} olarak değerlendirilmiştir.',
        sortOrder: 4,
        sectionData: inventory,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'support_documents',
        title: 'Destek ve Belge Hazırlığı',
        content:
            'Destek uygunluk skoru ${summary.supportOverallScore}/100 ve profil tamamlama oranı %${summary.profileCompletion} seviyesindedir. Eksik belge sayısı ${summary.missingDocumentsCount} olarak izlenmiştir.',
        sortOrder: 5,
        sectionData: {
          'support': support,
          'documents': documents,
        },
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'risks',
        title: 'Riskler',
        content: risks.join('\n'),
        sortOrder: 6,
        sectionData: {'items': risks},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'actions',
        title: 'Önerilen Aksiyonlar',
        content: actions.join('\n'),
        sortOrder: 7,
        sectionData: {'items': actions},
      ),
    ],
  );
}

GeneratedReportDraft _buildFinancialSummaryReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final financial = _map(data['financial']);
  final expenses = _listMap(financial['gider_kalemleri']);
  final topExpense = expenses.isEmpty ? null : expenses.first;
  final actions = <String>[
    'Giderlerin gelir içindeki payı yüksek görünüyorsa en büyük kalemler ayrıca kontrol edilmelidir.',
    'Bekleyen ödemeler nakit planıyla birlikte gözden geçirilmelidir.',
    'Kârlılığı baskılayan düzenli giderler için tasarruf veya fiyatlama güncellemesi değerlendirilebilir.',
  ];
  return GeneratedReportDraft(
    title: 'Finansal Özet Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        'Gelir, gider ve net sonuç görünümü yönetici özeti olarak derlenmiştir. Bu rapor kesin muhasebe veya vergi kararı yerine ön analiz amaçlı kullanılmalıdır.',
    keyFindings: [
      'Aylık gelir ${_money(summary.monthlyIncome)} seviyesindedir.',
      'Aylık gider ${_money(summary.monthlyExpense)} seviyesindedir.',
      'Net sonuç ${_signedMoney(summary.netProfit)} olarak hesaplanmıştır.',
    ],
    risks: [
      if (summary.netProfit < 0)
        'Net sonuç negatif görünüyor. Gider kalemleri ve fiyat yapısı birlikte incelenmelidir.',
      if (summary.monthlyExpense > summary.monthlyIncome * 0.8 && summary.monthlyIncome > 0)
        'Gider/gelir oranı yüksek seyrediyor.',
      if (topExpense != null)
        'En yüksek gider kalemi ${topExpense['baslik']} başlığında yoğunlaşıyor olabilir.',
    ],
    opportunities: [
      if (summary.netProfit >= 0) 'Net sonuç pozitif tarafta olduğu için büyüme planları daha kontrollü ele alınabilir.',
      'Gider dağılımı düzenli izlendiğinde verimlilik fırsatları görünür hale gelir.',
    ],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'finans_detayi': financial,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'income_expense',
        title: 'Gelir-Gider Özeti',
        content:
            'Gelir ${_money(summary.monthlyIncome)} ve gider ${_money(summary.monthlyExpense)} olarak özetlenmiştir.',
        sortOrder: 0,
        sectionData: financial,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'net_profit',
        title: 'Net Kâr/Zarar',
        content:
            'Dönem net sonucu ${_signedMoney(summary.netProfit)} seviyesindedir. Bu görünüm düzenli kayıt girişi ile daha anlamlı hale gelir.',
        sortOrder: 1,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'expense_status',
        title: 'Giderlerin Durumu',
        content: topExpense == null
            ? 'Gider dağılımı için yeterli veri bulunamadı.'
            : 'En yüksek gider ağırlığı ${topExpense['baslik']} kaleminde görünüyor.',
        sortOrder: 2,
        sectionData: {'gider_kalemleri': expenses},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'payments',
        title: 'Bekleyen Ödemeler',
        content:
            'Kısa vadeli ödeme planı ile tahsilat takvimi birlikte izlenmelidir. Bu özet kesin ödeme talimatı yerine ön planlama amaçlıdır.',
        sortOrder: 3,
        sectionData: _map(data['cashflow']),
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'recommendations',
        title: 'Öneriler',
        content: actions.join('\n'),
        sortOrder: 4,
        sectionData: {'items': actions},
      ),
    ],
  );
}

GeneratedReportDraft _buildCashflowReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final cashflow = _map(data['cashflow']);
  final actions = <String>[
    'Yaklaşan ödemeler ile beklenen tahsilatlar aynı takvimde kontrol edilmelidir.',
    'Büyük harcama kararları verilmeden önce 30 ve 60 günlük görünüm birlikte değerlendirilmelidir.',
    'Geciken tahsilatlar varsa cari öncelik listesi hızla güncellenmelidir.',
  ];
  final risks = <String>[
    if (summary.cashScore < 60) 'Nakit skoru orta veya yüksek risk bandında görünüyor.',
    if (summary.netCash30d < 0) '30 günlük net nakit görünümü negatif tarafta.',
    if (summary.overdueReceivables > 0) 'Vadesi geçmiş tahsilatlar nakit akışını zayıflatıyor olabilir.',
  ];

  return GeneratedReportDraft(
    title: 'Nakit Akışı Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        'Nakit planı kısa vadeli karar desteği için hazırlanmıştır. Kesin ödeme veya yatırım kararı öncesinde güncel tahsilat ve ödeme kayıtları ayrıca kontrol edilmelidir.',
    keyFindings: [
      'Nakit skoru ${summary.cashScore}/100 seviyesindedir.',
      '30 günlük net görünüm ${_signedMoney(summary.netCash30d)} olarak hesaplanmıştır.',
      'Vadesi geçmiş tahsilatlar ${_money(summary.overdueReceivables)} düzeyindedir.',
    ],
    risks: risks,
    opportunities: [
      if (summary.cashScore >= 70) 'Nakit dengesi kısa vadede yönetilebilir seviyede olabilir.',
      'Ödeme tarihleri yeniden sıralanarak geçici rahatlama sağlanabilir.',
    ],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'nakit_detayi': cashflow,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'cash_score',
        title: 'Nakit Skoru',
        content: 'Mevcut nakit skoru ${summary.cashScore}/100 olarak değerlendirilmiştir.',
        sortOrder: 0,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'projection_30',
        title: '30 Günlük Tahmin',
        content:
            '30 günlük net görünüm ${_signedMoney(summary.netCash30d)} seviyesindedir.',
        sortOrder: 1,
        sectionData: cashflow,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'projection_60',
        title: '60 Günlük Tahmin',
        content:
            '60 günlük giriş ve çıkış görünümü karar desteği amaçlı izlenmelidir.',
        sortOrder: 2,
        sectionData: cashflow,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'overdue',
        title: 'Geciken Tahsilatlar',
        content:
            'Geciken tahsilatlar kısa vadeli planı etkileyebilir. Tahsilat önceliği cari risk düzeyine göre sıralanmalıdır.',
        sortOrder: 3,
        sectionData: _map(data['customerRisk']),
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'payments',
        title: 'Yaklaşan Ödemeler',
        content:
            'Ödeme takvimi tek başına kesin karar yerine tahsilat planı ile birlikte okunmalıdır.',
        sortOrder: 4,
        sectionData: cashflow,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'decision_note',
        title: 'Harcama Kararı Notu',
        content:
            'Yeni harcama kararı öncesinde tahsilat hızına, yaklaşan ödemelere ve nakit skoruna birlikte bakılması önerilir.',
        sortOrder: 5,
      ),
    ],
  );
}

GeneratedReportDraft _buildCustomerRiskReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final customer = _map(data['customerRisk']);
  final risky = _listMap(customer['riskli_musteriler']);
  final actions = <String>[
    'Vadesi geçmiş ve bakiyesi yüksek müşteriler ilk sırada ele alınmalıdır.',
    'Hatırlatma süreci yazılı ve tarihli şekilde ilerletilmelidir.',
    'Tahsilat planı nakit raporuyla birlikte okunmalıdır.',
  ];
  return GeneratedReportDraft(
    title: 'Cari / Tahsilat Risk Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        'Cari hareketlerden türetilen bu çıktı tahsilat önceliği için karar destek amacı taşır. Kesin hukuki takip planı yerine ön sıralama üretir.',
    keyFindings: [
      'Bekleyen tahsilatlar ${_money(summary.pendingReceivables)} düzeyindedir.',
      'Vadesi geçmiş tahsilatlar ${_money(summary.overdueReceivables)} düzeyindedir.',
      'Riskli müşteri sayısı ${risky.length} olarak öne çıkmıştır.',
    ],
    risks: [
      if (summary.overdueReceivables > 0) 'Vadesi geçmiş tahsilatlar kısa vadeli nakit akışını zayıflatabilir.',
      if (risky.isEmpty) 'Risk sıralaması için yeterli müşteri verisi sınırlı olabilir.',
    ],
    opportunities: [
      'Tahsilat takvimi düzenli izlendiğinde nakit planı güçlenebilir.',
    ],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'cari_detayi': customer,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'customer_total',
        title: 'Toplam Müşteri',
        content: 'Kayıtlı müşteri sayısı ${customer['toplam_musteri'] ?? 0} olarak görünmektedir.',
        sortOrder: 0,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'pending_receivables',
        title: 'Bekleyen Tahsilatlar',
        content: 'Bekleyen tahsilat toplamı ${_money(summary.pendingReceivables)} seviyesindedir.',
        sortOrder: 1,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'overdue_receivables',
        title: 'Geciken Tahsilatlar',
        content:
            'Vadesi geçmiş tahsilat toplamı ${_money(summary.overdueReceivables)} olarak izlenmektedir.',
        sortOrder: 2,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'risky_customers',
        title: 'Riskli Müşteriler',
        content: risky.isEmpty
            ? 'Riskli müşteri görünümü için yeterli veri bulunamadı.'
            : 'Riskli müşteriler tahsilat önceliği için özetlenmiştir.',
        sortOrder: 3,
        sectionData: {'items': risky},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'priority',
        title: 'Tahsilat Önceliği',
        content:
            'Öncelik sıralaması vadesi geçmiş tutar, toplam bakiye ve risk düzeyi birlikte değerlendirilerek oluşturulmalıdır.',
        sortOrder: 4,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'reminders',
        title: 'Hatırlatma Aksiyonları',
        content: actions.join('\n'),
        sortOrder: 5,
        sectionData: {'items': actions},
      ),
    ],
  );
}

GeneratedReportDraft _buildInventoryRiskReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final inventory = _map(data['inventoryRisk']);
  final actions = <String>[
    'Kritik stoktaki ürünler tedarik süresine göre önceliklendirilebilir.',
    'Stokta olmayan ürünler satış kaybı etkisine göre ayrıca izlenmelidir.',
    'Düşük kâr marjlı ürünlerde alım ve satış fiyatı yeniden değerlendirilebilir.',
  ];
  return GeneratedReportDraft(
    title: 'Stok Risk Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        'Stok görünümü operasyonel karar desteği için derlenmiştir. Kesin sipariş kararı öncesinde satış hızı ve tedarik süresi ayrıca kontrol edilmelidir.',
    keyFindings: [
      'Kritik stoktaki ürün sayısı ${summary.criticalStockCount}.',
      'Stokta olmayan ürün sayısı ${summary.outOfStockCount}.',
      'Toplam ürün görünümü ${inventory['toplam_urun'] ?? 0} kayıt üzerinden hazırlanmıştır.',
    ],
    risks: [
      if (summary.criticalStockCount > 0) 'Kritik stoktaki ürünler kısa vadede satış sürekliliğini etkileyebilir.',
      if (summary.outOfStockCount > 0) 'Stokta olmayan ürünler müşteri kaybına yol açabilir.',
    ],
    opportunities: [
      'Minimum stok kuralları düzenli izlendiğinde operasyonel sürprizler azalır.',
    ],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'stok_detayi': inventory,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'total_products',
        title: 'Toplam Ürün',
        content: 'Stok havuzunda ${inventory['toplam_urun'] ?? 0} ürün görünmektedir.',
        sortOrder: 0,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'critical_stock',
        title: 'Kritik Stok',
        content:
            'Kritik stoktaki ürünler tedarik süresi dikkate alınarak izlenmelidir.',
        sortOrder: 1,
        sectionData: {'items': inventory['kritik_urunler'] ?? const []},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'out_of_stock',
        title: 'Stokta Olmayan Ürünler',
        content:
            'Stokta olmayan ürünler satış ve teslimat kalitesini etkileyebilir.',
        sortOrder: 2,
        sectionData: {'items': inventory['stokta_olmayanlar'] ?? const []},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'low_margin',
        title: 'Düşük Kâr Marjlı Ürünler',
        content:
            'Düşük marjlı ürünler fiyatlama ve satın alma gözden geçirmesi gerektirebilir.',
        sortOrder: 3,
        sectionData: {'items': inventory['dusuk_marjli_urunler'] ?? const []},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'supply_actions',
        title: 'Tedarik Önerileri',
        content: actions.join('\n'),
        sortOrder: 4,
        sectionData: {'items': actions},
      ),
    ],
  );
}

GeneratedReportDraft _buildSupportReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final support = _map(data['support']);
  final documentData = _map(data['documents']);
  final actions = _stringList(support['onerilen_adimlar']).isNotEmpty
      ? _stringList(support['onerilen_adimlar'])
      : <String>[
          'İşletme profili eksikleri tamamlanmalıdır.',
          'Destek başvurusu için kritik belgeler önceliklendirilebilir.',
          'Uygun destek başlıkları belge hazırlığı ile birlikte değerlendirilmelidir.',
        ];
  return GeneratedReportDraft(
    title: 'Destek Uygunluk Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        'Destek ve teşvik uygunluğu ön değerlendirme amaçlı özetlenmiştir. Resmî başvuru uygunluğu için güncel mevzuat ve belge kontrolleri ayrıca yapılmalıdır.',
    keyFindings: [
      'Genel destek skoru ${summary.supportOverallScore}/100 olarak görünmektedir.',
      'Profil tamamlama oranı %${summary.profileCompletion} seviyesindedir.',
      'Eksik belge sayısı ${summary.missingDocumentsCount} olarak izlenmektedir.',
    ],
    risks: [
      if (summary.profileCompletion < 70) 'Eksik profil bilgileri destek potansiyelini sınırlıyor olabilir.',
      if (summary.missingDocumentsCount > 0) 'Eksik belgeler başvuru hızını yavaşlatabilir.',
    ],
    opportunities: _stringList(support['firsatlar']).isNotEmpty
        ? _stringList(support['firsatlar'])
        : <String>['Uygun destek alanları profil tamamlandıkça daha görünür hale gelebilir.'],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'destek_detayi': support,
      'belge_detayi': documentData,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'overall_score',
        title: 'Genel Destek Skoru',
        content: 'Genel uygunluk görünümü ${summary.supportOverallScore}/100 seviyesindedir.',
        sortOrder: 0,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'kosgeb',
        title: 'KOSGEB Potansiyeli',
        content:
            'KOSGEB ve benzeri destek başlıkları işletme profili ve belge hazırlığına göre değerlendirilmelidir.',
        sortOrder: 1,
        sectionData: support,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'export_supports',
        title: 'İhracat Destekleri',
        content:
            'İhracat hedefi bulunan işletmeler için başlıklar ayrıca önceliklendirilebilir.',
        sortOrder: 2,
        sectionData: support,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'certification',
        title: 'Belgelendirme',
        content:
            'Belgelendirme hazırlığı, destek erişimi açısından güçlendirici olabilir.',
        sortOrder: 3,
        sectionData: documentData,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'digitalization',
        title: 'Dijitalleşme',
        content:
            'Dijitalleşme ihtiyacı bulunan işletmeler için proje hazırlığı destek potansiyelini artırabilir.',
        sortOrder: 4,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'gaps',
        title: 'Eksikler',
        content: _stringList(support['eksikler']).isEmpty
            ? 'Öne çıkan eksik bilgisi bulunamadı.'
            : _stringList(support['eksikler']).join('\n'),
        sortOrder: 5,
        sectionData: {'items': support['eksikler'] ?? const []},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'next_steps',
        title: 'Sonraki Adımlar',
        content: actions.join('\n'),
        sortOrder: 6,
        sectionData: {'items': actions},
      ),
    ],
  );
}

GeneratedReportDraft _buildDocumentGapReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end,
) {
  final documents = _map(data['documents']);
  final missing = _stringList(documents['eksik_belgeler']);
  final actions = <String>[
    'Yüksek öncelikli eksikler ilk sırada tamamlanmalıdır.',
    'Süresi geçen belgeler yenilenmeden başvuru süreçleri başlatılmamalıdır.',
    'Belge sıralaması destek planına göre gözden geçirilmelidir.',
  ];
  return GeneratedReportDraft(
    title: 'Eksik Belge Raporu',
    periodLabel: _periodLabel(start, end),
    summary:
        'Belge hazırlık görünümü operasyonel önceliklendirme amacıyla hazırlanmıştır. Resmî başvuru öncesinde belge güncelliği ayrıca doğrulanmalıdır.',
    keyFindings: [
      'Belge hazırlık skoru ${documents['hazirlik_skoru'] ?? 0}/100 düzeyindedir.',
      'Eksik belge sayısı ${missing.length} olarak görünmektedir.',
      'Toplam belge sayısı ${documents['toplam_belge'] ?? 0} kayıttır.',
    ],
    risks: [
      if (missing.isNotEmpty) 'Eksik belgeler süreçleri geciktirebilir.',
      if (_stringList(documents['suresi_gecen_belgeler']).isNotEmpty)
        'Süresi geçen belgeler öncelikli yenileme gerektiriyor olabilir.',
    ],
    opportunities: [
      'Belge klasörü düzenli tutulduğunda destek ve finans süreçleri daha hızlı ilerleyebilir.',
    ],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'belge_detayi': documents,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'readiness_score',
        title: 'Belge Hazırlık Skoru',
        content:
            'Belge hazırlık skoru ${documents['hazirlik_skoru'] ?? 0}/100 düzeyindedir.',
        sortOrder: 0,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'missing_documents',
        title: 'Eksik Belgeler',
        content: missing.isEmpty ? 'Eksik belge görünmüyor.' : missing.join('\n'),
        sortOrder: 1,
        sectionData: {'items': missing},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'expired_documents',
        title: 'Süresi Geçen Belgeler',
        content: _stringList(documents['suresi_gecen_belgeler']).isEmpty
            ? 'Süresi geçen belge görünmüyor.'
            : _stringList(documents['suresi_gecen_belgeler']).join('\n'),
        sortOrder: 2,
        sectionData: {'items': documents['suresi_gecen_belgeler'] ?? const []},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'expiring_documents',
        title: 'Süresi Yaklaşan Belgeler',
        content: _stringList(documents['suresi_yaklasan_belgeler']).isEmpty
            ? 'Süresi yaklaşan belge görünmüyor.'
            : _stringList(documents['suresi_yaklasan_belgeler']).join('\n'),
        sortOrder: 3,
        sectionData: {'items': documents['suresi_yaklasan_belgeler'] ?? const []},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'support_requirements',
        title: 'Destek Başvurusu İçin Gerekenler',
        content:
            'Destek başvurusu öncesinde eksik ve süresi geçen belgeler tamamlanmalı, profil bilgileri güncel tutulmalıdır.',
        sortOrder: 4,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'priority_order',
        title: 'Önerilen Sıralama',
        content: actions.join('\n'),
        sortOrder: 5,
        sectionData: {'items': actions},
      ),
    ],
  );
}

GeneratedReportDraft _buildActionPlanReport(
  ReportSummaryModel summary,
  Map<String, dynamic> data,
  DateTime? start,
  DateTime? end, {
  required bool weekly,
}) {
  final customer = _map(data['customerRisk']);
  final inventory = _map(data['inventoryRisk']);
  final documents = _map(data['documents']);
  final support = _map(data['support']);
  final financial = _map(data['financial']);
  final actions = summary.topActions.isNotEmpty
      ? summary.topActions
      : <String>[
          'Gelir ve gider kayıtlarını güncel tutun.',
          'Cari tahsilat listesini önceliklendirin.',
          'Stok ve belge eksiklerini kontrol edin.',
        ];

  return GeneratedReportDraft(
    title: weekly ? 'Haftalık İş Planı Raporu' : 'Günlük İş Planı Raporu',
    periodLabel: _periodLabel(start, end) ?? (weekly ? 'Haftalık görünüm' : 'Günlük görünüm'),
    summary:
        '${summary.executiveSummary} Bu plan karar desteği sunar; kesin operasyon talimatı yerine önceliklendirme önerir.',
    keyFindings: [
      'Öne çıkan aksiyon sayısı ${summary.dailyActionCount}.',
      'Cari risk ve nakit görünümü birlikte ele alınmalıdır.',
      'Belge ve destek hazırlığı günlük operasyon planını etkileyebilir.',
    ],
    risks: summary.topRisks.isEmpty
        ? <String>['Yeterli veri bulunamadı. Daha güçlü plan için kayıtlarınızı tamamlayın.']
        : summary.topRisks,
    opportunities: [
      'Öncelikleri tek listede toplamak ekip içi takibi kolaylaştırabilir.',
    ],
    recommendedActions: actions,
    reportData: {
      'metrikler': _baseMetrics(summary),
      'eylem_listesi': actions,
    },
    sections: [
      GeneratedReportSectionDraft(
        sectionKey: 'priorities',
        title: weekly ? 'Bu Haftanın Öncelikleri' : 'Bugünkü Öncelikler',
        content: actions.join('\n'),
        sortOrder: 0,
        sectionData: {'items': actions},
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'collection_actions',
        title: 'Tahsilat Aksiyonları',
        content:
            'Tahsilat planı vadesi geçmiş kayıtlar ve yüksek bakiye taşıyan müşteriler üzerinden önceliklendirilebilir.',
        sortOrder: 1,
        sectionData: customer,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'payment_plan',
        title: 'Ödeme Planı',
        content:
            'Ödemeler kısa vadeli nakit görünümü ile birlikte ele alınmalıdır.',
        sortOrder: 2,
        sectionData: _map(data['cashflow']),
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'stock_actions',
        title: 'Stok Aksiyonları',
        content:
            'Kritik stoktaki ürünler ve düşük marjlı kalemler birlikte gözden geçirilmelidir.',
        sortOrder: 3,
        sectionData: inventory,
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'document_support_actions',
        title: 'Belge/Destek Aksiyonları',
        content:
            'Eksik belge ve destek hazırlığı aksiyonları operasyon takvimine eklenmelidir.',
        sortOrder: 4,
        sectionData: {
          'documents': documents,
          'support': support,
        },
      ),
      GeneratedReportSectionDraft(
        sectionKey: 'ai_summary',
        title: 'AI/Kural Bazlı Özet',
        content:
            'Mevcut kayıtlar, finansal görünüm ve operasyonel riskler birlikte değerlendirilerek bu öncelik listesi oluşturulmuştur.',
        sortOrder: 5,
        sectionData: financial,
      ),
    ],
  );
}

Map<String, dynamic> _baseMetrics(ReportSummaryModel summary) {
  return {
    'aylik_gelir': summary.monthlyIncome,
    'aylik_gider': summary.monthlyExpense,
    'net_kar_zarar': summary.netProfit,
    'bekleyen_tahsilat': summary.pendingReceivables,
    'vadesi_gecmis_tahsilat': summary.overdueReceivables,
    'nakit_skoru': summary.cashScore,
    'net_nakit_30_gun': summary.netCash30d,
    'kritik_stok_sayisi': summary.criticalStockCount,
    'stokta_olmayan_sayisi': summary.outOfStockCount,
    'eksik_belge_sayisi': summary.missingDocumentsCount,
    'destek_skoru': summary.supportOverallScore,
    'profil_tamamlama': summary.profileCompletion,
    'risk_duzeyi': summary.overallRiskLevel,
  };
}

List<String> _collectRisks(
  ReportSummaryModel summary,
  Map<String, dynamic> customer,
  Map<String, dynamic> inventory,
  Map<String, dynamic> documents,
  Map<String, dynamic> support,
) {
  final risks = <String>[];
  if (summary.netCash30d < 0) {
    risks.add('30 günlük net nakit görünümü negatif seyrediyor.');
  }
  if (summary.overdueReceivables > 0) {
    risks.add('Vadesi geçmiş tahsilatlar kısa vadeli akışı baskılıyor olabilir.');
  }
  if (summary.criticalStockCount > 0) {
    risks.add('Kritik stoktaki ürünler operasyon akışını kesintiye uğratabilir.');
  }
  if (summary.missingDocumentsCount > 0) {
    risks.add('Eksik belgeler destek ve başvuru hazırlığını yavaşlatabilir.');
  }
  if ((support['genel_skor'] as num?)?.toInt() == 0) {
    risks.add('Destek görünümü için profil veya analiz verisi sınırlı olabilir.');
  }
  if (risks.isEmpty) {
    risks.add('Belirgin bir yüksek risk görünmüyor; yine de düzenli takip önerilir.');
  }
  return risks;
}

List<String> _collectOpportunities(
  ReportSummaryModel summary,
  Map<String, dynamic> support,
  Map<String, dynamic> inventory,
) {
  final opportunities = <String>[];
  if (summary.netProfit >= 0) {
    opportunities.add('Pozitif net sonuç, kontrollü büyüme kararları için alan yaratabilir.');
  }
  if (_stringList(support['firsatlar']).isNotEmpty) {
    opportunities.addAll(_stringList(support['firsatlar']).take(2));
  }
  if (_listMap(inventory['dusuk_marjli_urunler']).isNotEmpty) {
    opportunities.add('Düşük marjlı ürünlerde fiyatlama iyileştirmesi kârlılığı artırabilir.');
  }
  if (opportunities.isEmpty) {
    opportunities.add('Düzenli veri girişi arttıkça daha güçlü fırsat alanları görünür hale gelir.');
  }
  return opportunities;
}

List<String> _collectActions(
  ReportSummaryModel summary,
  Map<String, dynamic> support,
  Map<String, dynamic> documents,
) {
  final actions = <String>[];
  if (summary.overdueReceivables > 0) {
    actions.add('Vadesi geçmiş tahsilatlar için öncelik listesi oluşturun.');
  }
  if (summary.netCash30d < 0) {
    actions.add('Önümüzdeki 30 gün için ödeme ve tahsilat takvimini birlikte gözden geçirin.');
  }
  if (summary.criticalStockCount > 0) {
    actions.add('Kritik stoktaki ürünler için tedarik planını netleştirin.');
  }
  if (_stringList(documents['eksik_belgeler']).isNotEmpty) {
    actions.add('Eksik belgeleri yüksek öncelikten başlayarak tamamlayın.');
  }
  if (_stringList(support['onerilen_adimlar']).isNotEmpty) {
    actions.addAll(_stringList(support['onerilen_adimlar']).take(2));
  }
  if (actions.isEmpty) {
    actions.addAll(summary.topActions);
  }
  if (actions.isEmpty) {
    actions.add('Gelir-gider, cari, stok ve belge kayıtlarını güncel tutun.');
  }
  return actions;
}

String? _periodLabel(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return null;
  }
  final startText = start == null ? null : _date(start);
  final endText = end == null ? null : _date(end);
  if (startText != null && endText != null) {
    return '$startText - $endText';
  }
  return startText ?? endText;
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day.$month.$year';
}

String _money(double value) {
  return '${value.toStringAsFixed(2)} TL';
}

String _signedMoney(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_money(value)}';
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _listMap(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.map((key, itemValue) => MapEntry(key.toString(), itemValue)))
        .toList();
  }
  return const [];
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
