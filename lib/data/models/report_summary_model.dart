class ReportSummaryModel {
  const ReportSummaryModel({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netProfit,
    required this.pendingReceivables,
    required this.overdueReceivables,
    required this.cashScore,
    required this.netCash30d,
    required this.criticalStockCount,
    required this.outOfStockCount,
    required this.missingDocumentsCount,
    required this.supportOverallScore,
    required this.profileCompletion,
    required this.dailyActionCount,
    required this.overallRiskLevel,
    required this.executiveSummary,
    required this.topRisks,
    required this.topActions,
  });

  final double monthlyIncome;
  final double monthlyExpense;
  final double netProfit;
  final double pendingReceivables;
  final double overdueReceivables;
  final int cashScore;
  final double netCash30d;
  final int criticalStockCount;
  final int outOfStockCount;
  final int missingDocumentsCount;
  final int supportOverallScore;
  final int profileCompletion;
  final int dailyActionCount;
  final String overallRiskLevel;
  final String executiveSummary;
  final List<String> topRisks;
  final List<String> topActions;
}
