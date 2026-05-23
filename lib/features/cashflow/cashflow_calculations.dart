import '../../data/models/cashflow_entry_model.dart';
import '../../data/models/cashflow_projection_model.dart';

double calculateExpectedInflow(List<CashflowEntryModel> entries, int days) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(Duration(days: days));

  return entries
      .where(
        (entry) =>
            entry.isInflow &&
            !entry.isPaid &&
            !entry.expectedDate.isBefore(start) &&
            !entry.expectedDate.isAfter(end),
      )
      .fold(0.0, (sum, entry) => sum + entry.amount);
}

double calculateExpectedOutflow(List<CashflowEntryModel> entries, int days) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(Duration(days: days));

  return entries
      .where(
        (entry) =>
            entry.isOutflow &&
            !entry.isPaid &&
            !entry.expectedDate.isBefore(start) &&
            !entry.expectedDate.isAfter(end),
      )
      .fold(0.0, (sum, entry) => sum + entry.amount);
}

double calculateNetCash(double openingBalance, double inflow, double outflow) {
  return openingBalance + inflow - outflow;
}

double calculateOverdueInflow(List<CashflowEntryModel> entries) {
  return entries
      .where((entry) => entry.isInflow && entry.isOverdue)
      .fold(0.0, (sum, entry) => sum + entry.amount);
}

double calculateUpcomingOutflow(List<CashflowEntryModel> entries, int days) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(Duration(days: days));

  return entries
      .where(
        (entry) =>
            entry.isOutflow &&
            !entry.expectedDate.isBefore(start) &&
            !entry.expectedDate.isAfter(end),
      )
      .fold(0.0, (sum, entry) => sum + entry.amount);
}

int calculateCashScore({
  required double netCash30d,
  required double netCash60d,
  required double overdueInflow,
  required double expectedInflow30d,
  required double upcomingOutflow30d,
  required List<CashflowEntryModel> entries,
}) {
  var score = 100;

  if (netCash30d < 0) {
    score -= 30;
  }
  if (netCash60d < 0) {
    score -= 20;
  }
  if (overdueInflow > 0) {
    score -= 15;
  }
  if (upcomingOutflow30d > expectedInflow30d) {
    score -= 15;
  }

  final lowConfidenceCount =
      entries.where((entry) => entry.confidenceLevel == 'low').length;
  if (lowConfidenceCount >= 3) {
    score -= 10;
  }

  return score.clamp(0, 100);
}

String detectCashRiskLevel(int cashScore) {
  if (cashScore >= 80) {
    return 'low';
  }
  if (cashScore >= 60) {
    return 'medium';
  }
  if (cashScore >= 40) {
    return 'high';
  }
  return 'critical';
}

DateTime? detectCriticalDate({
  required double openingBalance,
  required List<CashflowEntryModel> entries,
}) {
  final ordered = [...entries]..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
  var balance = openingBalance;

  for (final entry in ordered) {
    if (entry.isPaid || entry.status == 'cancelled') {
      continue;
    }

    balance += entry.isInflow ? entry.amount : -entry.amount;
    if (balance < 0) {
      return entry.expectedDate;
    }
  }

  return null;
}

String generateCashflowAiSummary({
  required List<CashflowEntryModel> entries,
  required double netCash30d,
  required double overdueInflow,
  required double upcomingOutflow30d,
  required double expectedInflow30d,
}) {
  if (entries.isEmpty) {
    return 'Nakit tahmini için beklenen tahsilat ve ödeme kayıtlarınızı ekleyin.';
  }
  if (overdueInflow > 0) {
    return 'Geciken tahsilatlar nakit akışınızı baskılıyor. Öncelikli tahsilat planı önerilir.';
  }
  if (netCash30d < 0) {
    return 'Önümüzdeki 30 gün içinde nakit açığı riski görünüyor.';
  }
  if (upcomingOutflow30d > expectedInflow30d) {
    return 'Yaklaşan ödemeler nedeniyle kısa vadeli nakit sıkışıklığı oluşabilir.';
  }
  return 'Önümüzdeki 30 gün için nakit akışınız dengeli görünüyor.';
}

List<String> generateCashflowSuggestions({
  required List<CashflowEntryModel> entries,
  required double overdueInflow,
  required double expectedInflow30d,
  required double upcomingOutflow30d,
}) {
  if (entries.isEmpty) {
    return const [
      'Beklenen tahsilat ve ödeme kayıtlarınızı ekleyerek tahmin doğruluğunu başlatın.',
      'Yeni gider öncesi 30 günlük net nakit görünümünü kontrol edin.',
    ];
  }

  final suggestions = <String>[
    'Düzenli tahsilat ve ödeme kayıtları girildikçe tahmin doğruluğu artar.',
    'Yeni gider öncesi 30 günlük net nakit kontrol edilmeli.',
  ];

  if (overdueInflow > 0) {
    suggestions.insert(0, 'Geciken tahsilatlar önceliklendirilmeli.');
  }

  if (upcomingOutflow30d > expectedInflow30d) {
    suggestions.add('Yaklaşan büyük ödemeler için kasa planı yapılmalı.');
  }

  return suggestions;
}

CashflowScenarioAnalysis analyzeExpenseScenario({
  required String title,
  required double plannedExpenseAmount,
  required DateTime plannedExpenseDate,
  required double openingBalance,
  required CashflowProjectionModel projection,
}) {
  final adjusted30d = projection.netCash30d - plannedExpenseAmount;
  final adjusted60d = projection.netCash60d - plannedExpenseAmount;
  final adjustedScore = calculateCashScore(
    netCash30d: adjusted30d,
    netCash60d: adjusted60d,
    overdueInflow: projection.overdueInflowTotal,
    expectedInflow30d: projection.expectedInflow30d,
    upcomingOutflow30d: projection.upcomingOutflowTotal + plannedExpenseAmount,
    entries: const [],
  );
  final riskLevel = detectCashRiskLevel(adjustedScore);

  late final String summary;
  late final String recommendation;

  if (adjustedScore < 40 || adjusted30d < 0) {
    summary = 'Bu harcama mevcut 30 günlük nakit akışına göre yüksek riskli görünüyor.';
    recommendation =
        'Tahsilatlar kesinleşmeden bu harcamanın ertelenmesi veya parçalanması önerilir.';
  } else if (adjustedScore < 60) {
    summary = 'Bu harcama nakit akışı üzerinde belirgin baskı oluşturabilir.';
    recommendation =
        'Ödeme takvimi yeniden planlanmalı ve büyük tahsilatlar öne çekilmelidir.';
  } else if (adjustedScore < 80) {
    summary = 'Bu harcama yönetilebilir ancak dikkat gerektiriyor.';
    recommendation =
        'Harcamayı yapmadan önce beklenen tahsilatların tarihlerinin netleşmesi önerilir.';
  } else {
    summary = 'Bu harcama mevcut projeksiyona göre düşük riskli görünüyor.';
    recommendation =
        'Harcamayı yapabilirsiniz; yine de 30 günlük nakit akışını izlemeyi sürdürün.';
  }

  return CashflowScenarioAnalysis(
    title: title,
    amount: plannedExpenseAmount,
    date: plannedExpenseDate,
    riskLevel: riskLevel,
    resultSummary: summary,
    recommendation: recommendation,
    resultingCashScore: adjustedScore,
    resultingNetCash30d: openingBalance +
        projection.expectedInflow30d -
        (projection.expectedOutflow30d + plannedExpenseAmount),
  );
}

class CashflowScenarioAnalysis {
  const CashflowScenarioAnalysis({
    required this.title,
    required this.amount,
    required this.date,
    required this.riskLevel,
    required this.resultSummary,
    required this.recommendation,
    required this.resultingCashScore,
    required this.resultingNetCash30d,
  });

  final String title;
  final double amount;
  final DateTime date;
  final String riskLevel;
  final String resultSummary;
  final String recommendation;
  final int resultingCashScore;
  final double resultingNetCash30d;
}
