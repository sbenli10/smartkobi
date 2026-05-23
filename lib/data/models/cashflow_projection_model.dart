class CashflowProjectionModel {
  const CashflowProjectionModel({
    required this.openingBalance,
    required this.expectedInflow30d,
    required this.expectedOutflow30d,
    required this.netCash30d,
    required this.expectedInflow60d,
    required this.expectedOutflow60d,
    required this.netCash60d,
    required this.overdueInflowTotal,
    required this.upcomingOutflowTotal,
    required this.cashScore,
    required this.riskLevel,
    required this.aiSummary,
    required this.criticalDate,
    required this.suggestions,
  });

  final double openingBalance;
  final double expectedInflow30d;
  final double expectedOutflow30d;
  final double netCash30d;
  final double expectedInflow60d;
  final double expectedOutflow60d;
  final double netCash60d;
  final double overdueInflowTotal;
  final double upcomingOutflowTotal;
  final int cashScore;
  final String riskLevel;
  final String aiSummary;
  final DateTime? criticalDate;
  final List<String> suggestions;
}
