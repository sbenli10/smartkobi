class DashboardSummary {
  const DashboardSummary({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netProfit,
    required this.pendingReceivables,
    required this.overdueReceivables,
    required this.upcomingPayments7d,
    required this.expectedInflow30d,
    required this.expectedOutflow30d,
    required this.cashScore,
    required this.criticalStockCount,
    required this.outOfStockCount,
    required this.lowMarginProductCount,
    required this.missingDocumentsCount,
    required this.highPriorityMissingDocuments,
    required this.supportScore,
    required this.profileCompletion,
    required this.totalDocuments,
    required this.expiredDocumentsCount,
    required this.hasAnyBusinessData,
    this.openPriceAlertCount = 0, // 'required' kelimesi kaldırıldı, varsayılan 0 yapıldı.
  });

  final double monthlyIncome;
  final double monthlyExpense;
  final double netProfit;
  final double pendingReceivables;
  final double overdueReceivables;
  final double upcomingPayments7d;
  final double expectedInflow30d;
  final double expectedOutflow30d;
  final int openPriceAlertCount;
  final int cashScore;
  final int criticalStockCount;
  final int outOfStockCount;
  final int lowMarginProductCount;
  final int missingDocumentsCount;
  final int highPriorityMissingDocuments;
  final int supportScore;
  final int profileCompletion;
  final int totalDocuments;
  final int expiredDocumentsCount;
  final bool hasAnyBusinessData;

  String get overallRiskLevel {
    if (overdueReceivables > 0 ||
        cashScore < 40 ||
        criticalStockCount > 0 ||
        highPriorityMissingDocuments > 0) {
      return 'Acil';
    }
    if (cashScore < 60 ||
        upcomingPayments7d > expectedInflow30d / 4 ||
        outOfStockCount > 0 ||
        missingDocumentsCount > 0 ||
        openPriceAlertCount > 0) { // Fiyat artışı varsa risk seviyesi artar
      return 'Riskli';
    }
    if (cashScore < 80 || lowMarginProductCount > 0 || supportScore < 50) {
      return 'Dikkat';
    }
    return 'Güvenli';
  }

  String get dailySummaryText {
    if (!hasAnyBusinessData) {
      return 'Henüz yeterli veri yok. Gelir-gider, cari ve stok kayıtları eklendikçe SmartKOBİ daha net öneriler sunar.';
    }
    // Fiyat artışı tespit edildiyse, kârlılık uyarısı en üste alınır
    if (openPriceAlertCount > 0) {
      return 'Tedarikçi alış fiyatlarınızda artış var. Kâr marjınızı korumak için fiyatlarınızı kontrol etmeniz önerilir.';
    }
    if (overdueReceivables > 0 && cashScore < 60) {
      return 'Bugün önceliğiniz tahsilat ve nakit planı olmalı.';
    }
    if (criticalStockCount > 0) {
      return 'Bugün kritik stoktaki ürünleri ve tahsilat dengenizi kontrol etmeniz önerilir.';
    }
    if (highPriorityMissingDocuments > 0) {
      return 'Bugün belge hazırlığı ve destek başvurusu eksiklerine odaklanmanız iyi olur.';
    }
    return 'Verileriniz dengeli görünüyor. Tahsilat, stok ve belge kontrollerinizi güncel tutmanız önerilir.';
  }

  bool get shouldShowOnboarding => !hasAnyBusinessData;
}