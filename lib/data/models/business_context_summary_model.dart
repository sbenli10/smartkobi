class BusinessContextSummaryModel {
  const BusinessContextSummaryModel({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netProfit,
    required this.pendingReceivables,
    required this.overdueReceivables,
    required this.expectedCashInflow30d,
    required this.expectedCashOutflow30d,
    required this.netCash30d,
    required this.cashScore,
    required this.criticalStockCount,
    required this.outOfStockCount,
    required this.lowMarginProductCount,
    required this.customerRiskCount,
    required this.topRisks,
    required this.topOpportunities,
    required this.summaryText,
    this.businessName,
    this.sector,
    this.naceCode,
    this.employeeCount,
    this.annualRevenueRange,
    required this.doesManufacture,
    required this.doesExport,
    required this.wantsExport,
    required this.needsMachinery,
    required this.needsDigitalization,
    required this.needsCertification,
    required this.needsFinancing,
    required this.profileCompletion,
    required this.supportOverallScore,
    required this.supportOverallStatus,
    required this.topSupportOpportunities,
    required this.missingSupportDocuments,
    required this.supportRecommendedActions,
    required this.totalDocuments,
    required this.missingDocumentsCount,
    required this.expiredDocumentsCount,
    required this.highPriorityMissingDocuments,
    required this.supportReadinessScore,
    this.latestReportType,
    this.latestReportSummary,
    required this.latestReportRisks,
    required this.latestReportActions,
  });

  final double monthlyIncome;
  final double monthlyExpense;
  final double netProfit;
  final double pendingReceivables;
  final double overdueReceivables;
  final double expectedCashInflow30d;
  final double expectedCashOutflow30d;
  final double netCash30d;
  final int cashScore;
  final int criticalStockCount;
  final int outOfStockCount;
  final int lowMarginProductCount;
  final int customerRiskCount;
  final List<String> topRisks;
  final List<String> topOpportunities;
  final String? summaryText;
  final String? businessName;
  final String? sector;
  final String? naceCode;
  final int? employeeCount;
  final String? annualRevenueRange;
  final bool doesManufacture;
  final bool doesExport;
  final bool wantsExport;
  final bool needsMachinery;
  final bool needsDigitalization;
  final bool needsCertification;
  final bool needsFinancing;
  final int profileCompletion;
  final int supportOverallScore;
  final String supportOverallStatus;
  final List<String> topSupportOpportunities;
  final List<String> missingSupportDocuments;
  final List<String> supportRecommendedActions;
  final int totalDocuments;
  final int missingDocumentsCount;
  final int expiredDocumentsCount;
  final int highPriorityMissingDocuments;
  final int supportReadinessScore;
  final String? latestReportType;
  final String? latestReportSummary;
  final List<String> latestReportRisks;
  final List<String> latestReportActions;

  bool get hasFinancialData => monthlyIncome > 0 || monthlyExpense > 0 || netProfit != 0;
  bool get hasCashflowRisk => cashScore < 60 || netCash30d < 0 || overdueReceivables > 0;
  bool get hasCustomerRisk => customerRiskCount > 0 || overdueReceivables > 0;
  bool get hasInventoryRisk =>
      criticalStockCount > 0 || outOfStockCount > 0 || lowMarginProductCount > 0;

  String get overallRiskLevel {
    if (cashScore < 40 || netCash30d < 0 || overdueReceivables > 0) {
      return 'high';
    }
    if (cashScore < 70 || hasCustomerRisk || hasInventoryRisk) {
      return 'medium';
    }
    return 'low';
  }

  BusinessContextSummaryModel copyWith({
    double? monthlyIncome,
    double? monthlyExpense,
    double? netProfit,
    double? pendingReceivables,
    double? overdueReceivables,
    double? expectedCashInflow30d,
    double? expectedCashOutflow30d,
    double? netCash30d,
    int? cashScore,
    int? criticalStockCount,
    int? outOfStockCount,
    int? lowMarginProductCount,
    int? customerRiskCount,
    List<String>? topRisks,
    List<String>? topOpportunities,
    String? summaryText,
    bool clearSummaryText = false,
    String? businessName,
    String? sector,
    String? naceCode,
    int? employeeCount,
    String? annualRevenueRange,
    bool? doesManufacture,
    bool? doesExport,
    bool? wantsExport,
    bool? needsMachinery,
    bool? needsDigitalization,
    bool? needsCertification,
    bool? needsFinancing,
    int? profileCompletion,
    int? supportOverallScore,
    String? supportOverallStatus,
    List<String>? topSupportOpportunities,
    List<String>? missingSupportDocuments,
    List<String>? supportRecommendedActions,
    int? totalDocuments,
    int? missingDocumentsCount,
    int? expiredDocumentsCount,
    int? highPriorityMissingDocuments,
    int? supportReadinessScore,
    String? latestReportType,
    bool clearLatestReportType = false,
    String? latestReportSummary,
    bool clearLatestReportSummary = false,
    List<String>? latestReportRisks,
    List<String>? latestReportActions,
  }) {
    return BusinessContextSummaryModel(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      netProfit: netProfit ?? this.netProfit,
      pendingReceivables: pendingReceivables ?? this.pendingReceivables,
      overdueReceivables: overdueReceivables ?? this.overdueReceivables,
      expectedCashInflow30d: expectedCashInflow30d ?? this.expectedCashInflow30d,
      expectedCashOutflow30d: expectedCashOutflow30d ?? this.expectedCashOutflow30d,
      netCash30d: netCash30d ?? this.netCash30d,
      cashScore: cashScore ?? this.cashScore,
      criticalStockCount: criticalStockCount ?? this.criticalStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      lowMarginProductCount: lowMarginProductCount ?? this.lowMarginProductCount,
      customerRiskCount: customerRiskCount ?? this.customerRiskCount,
      topRisks: topRisks ?? this.topRisks,
      topOpportunities: topOpportunities ?? this.topOpportunities,
      summaryText: clearSummaryText ? null : summaryText ?? this.summaryText,
      businessName: businessName ?? this.businessName,
      sector: sector ?? this.sector,
      naceCode: naceCode ?? this.naceCode,
      employeeCount: employeeCount ?? this.employeeCount,
      annualRevenueRange: annualRevenueRange ?? this.annualRevenueRange,
      doesManufacture: doesManufacture ?? this.doesManufacture,
      doesExport: doesExport ?? this.doesExport,
      wantsExport: wantsExport ?? this.wantsExport,
      needsMachinery: needsMachinery ?? this.needsMachinery,
      needsDigitalization: needsDigitalization ?? this.needsDigitalization,
      needsCertification: needsCertification ?? this.needsCertification,
      needsFinancing: needsFinancing ?? this.needsFinancing,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      supportOverallScore: supportOverallScore ?? this.supportOverallScore,
      supportOverallStatus: supportOverallStatus ?? this.supportOverallStatus,
      topSupportOpportunities:
          topSupportOpportunities ?? this.topSupportOpportunities,
      missingSupportDocuments:
          missingSupportDocuments ?? this.missingSupportDocuments,
      supportRecommendedActions:
          supportRecommendedActions ?? this.supportRecommendedActions,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      missingDocumentsCount: missingDocumentsCount ?? this.missingDocumentsCount,
      expiredDocumentsCount: expiredDocumentsCount ?? this.expiredDocumentsCount,
      highPriorityMissingDocuments:
          highPriorityMissingDocuments ?? this.highPriorityMissingDocuments,
      supportReadinessScore: supportReadinessScore ?? this.supportReadinessScore,
      latestReportType:
          clearLatestReportType ? null : latestReportType ?? this.latestReportType,
      latestReportSummary: clearLatestReportSummary
          ? null
          : latestReportSummary ?? this.latestReportSummary,
      latestReportRisks: latestReportRisks ?? this.latestReportRisks,
      latestReportActions: latestReportActions ?? this.latestReportActions,
    );
  }

  factory BusinessContextSummaryModel.empty() {
    return const BusinessContextSummaryModel(
      monthlyIncome: 0,
      monthlyExpense: 0,
      netProfit: 0,
      pendingReceivables: 0,
      overdueReceivables: 0,
      expectedCashInflow30d: 0,
      expectedCashOutflow30d: 0,
      netCash30d: 0,
      cashScore: 50,
      criticalStockCount: 0,
      outOfStockCount: 0,
      lowMarginProductCount: 0,
      customerRiskCount: 0,
      topRisks: [],
      topOpportunities: [],
      summaryText: null,
      businessName: null,
      sector: null,
      naceCode: null,
      employeeCount: null,
      annualRevenueRange: null,
      doesManufacture: false,
      doesExport: false,
      wantsExport: false,
      needsMachinery: false,
      needsDigitalization: false,
      needsCertification: false,
      needsFinancing: false,
      profileCompletion: 0,
      supportOverallScore: 0,
      supportOverallStatus: 'needs_profile',
      topSupportOpportunities: [],
      missingSupportDocuments: [],
      supportRecommendedActions: [],
      totalDocuments: 0,
      missingDocumentsCount: 0,
      expiredDocumentsCount: 0,
      highPriorityMissingDocuments: 0,
      supportReadinessScore: 0,
      latestReportType: null,
      latestReportSummary: null,
      latestReportRisks: [],
      latestReportActions: [],
    );
  }

  factory BusinessContextSummaryModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    return BusinessContextSummaryModel(
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ??
          (json['monthlyIncome'] as num?)?.toDouble() ??
          0,
      monthlyExpense: (json['monthly_expense'] as num?)?.toDouble() ??
          (json['monthlyExpense'] as num?)?.toDouble() ??
          0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ??
          (json['netProfit'] as num?)?.toDouble() ??
          0,
      pendingReceivables: (json['pending_receivables'] as num?)?.toDouble() ??
          (json['pendingReceivables'] as num?)?.toDouble() ??
          0,
      overdueReceivables: (json['overdue_receivables'] as num?)?.toDouble() ??
          (json['overdueReceivables'] as num?)?.toDouble() ??
          0,
      expectedCashInflow30d:
          (json['expected_cash_inflow_30d'] as num?)?.toDouble() ??
              (json['expectedCashInflow30d'] as num?)?.toDouble() ??
              0,
      expectedCashOutflow30d:
          (json['expected_cash_outflow_30d'] as num?)?.toDouble() ??
              (json['expectedCashOutflow30d'] as num?)?.toDouble() ??
              0,
      netCash30d: (json['net_cash_30d'] as num?)?.toDouble() ??
          (json['netCash30d'] as num?)?.toDouble() ??
          0,
      cashScore: (json['cash_score'] as num?)?.toInt() ??
          (json['cashScore'] as num?)?.toInt() ??
          50,
      criticalStockCount: (json['critical_stock_count'] as num?)?.toInt() ??
          (json['criticalStockCount'] as num?)?.toInt() ??
          0,
      outOfStockCount: (json['out_of_stock_count'] as num?)?.toInt() ??
          (json['outOfStockCount'] as num?)?.toInt() ??
          0,
      lowMarginProductCount: (json['low_margin_product_count'] as num?)?.toInt() ??
          (json['lowMarginProductCount'] as num?)?.toInt() ??
          0,
      customerRiskCount: (json['customer_risk_count'] as num?)?.toInt() ??
          (json['customerRiskCount'] as num?)?.toInt() ??
          0,
      topRisks: parseList(json['top_risks'] ?? json['topRisks']),
      topOpportunities:
          parseList(json['top_opportunities'] ?? json['topOpportunities']),
      summaryText: json['summary_text']?.toString() ?? json['summaryText']?.toString(),
      businessName: json['business_name']?.toString() ?? json['businessName']?.toString(),
      sector: json['sector']?.toString(),
      naceCode: json['nace_code']?.toString() ?? json['naceCode']?.toString(),
      employeeCount: (json['employee_count'] as num?)?.toInt() ??
          (json['employeeCount'] as num?)?.toInt(),
      annualRevenueRange: json['annual_revenue_range']?.toString() ??
          json['annualRevenueRange']?.toString(),
      doesManufacture: json['does_manufacture'] as bool? ??
          json['doesManufacture'] as bool? ??
          false,
      doesExport:
          json['does_export'] as bool? ?? json['doesExport'] as bool? ?? false,
      wantsExport:
          json['wants_export'] as bool? ?? json['wantsExport'] as bool? ?? false,
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
      profileCompletion: (json['profile_completion'] as num?)?.toInt() ??
          (json['profileCompletion'] as num?)?.toInt() ??
          0,
      supportOverallScore: (json['support_overall_score'] as num?)?.toInt() ??
          (json['supportOverallScore'] as num?)?.toInt() ??
          0,
      supportOverallStatus: json['support_overall_status']?.toString() ??
          json['supportOverallStatus']?.toString() ??
          'needs_profile',
      topSupportOpportunities: parseList(
        json['top_support_opportunities'] ?? json['topSupportOpportunities'],
      ),
      missingSupportDocuments: parseList(
        json['missing_support_documents'] ?? json['missingSupportDocuments'],
      ),
      supportRecommendedActions: parseList(
        json['support_recommended_actions'] ??
            json['supportRecommendedActions'],
      ),
      totalDocuments: (json['total_documents'] as num?)?.toInt() ??
          (json['totalDocuments'] as num?)?.toInt() ??
          0,
      missingDocumentsCount: (json['missing_documents_count'] as num?)?.toInt() ??
          (json['missingDocumentsCount'] as num?)?.toInt() ??
          0,
      expiredDocumentsCount: (json['expired_documents_count'] as num?)?.toInt() ??
          (json['expiredDocumentsCount'] as num?)?.toInt() ??
          0,
      highPriorityMissingDocuments:
          (json['high_priority_missing_documents'] as num?)?.toInt() ??
              (json['highPriorityMissingDocuments'] as num?)?.toInt() ??
              0,
      supportReadinessScore: (json['support_readiness_score'] as num?)?.toInt() ??
          (json['supportReadinessScore'] as num?)?.toInt() ??
          0,
      latestReportType:
          json['latest_report_type']?.toString() ?? json['latestReportType']?.toString(),
      latestReportSummary: json['latest_report_summary']?.toString() ??
          json['latestReportSummary']?.toString(),
      latestReportRisks:
          parseList(json['latest_report_risks'] ?? json['latestReportRisks']),
      latestReportActions:
          parseList(json['latest_report_actions'] ?? json['latestReportActions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_income': monthlyIncome,
      'monthly_expense': monthlyExpense,
      'net_profit': netProfit,
      'pending_receivables': pendingReceivables,
      'overdue_receivables': overdueReceivables,
      'expected_cash_inflow_30d': expectedCashInflow30d,
      'expected_cash_outflow_30d': expectedCashOutflow30d,
      'net_cash_30d': netCash30d,
      'cash_score': cashScore,
      'critical_stock_count': criticalStockCount,
      'out_of_stock_count': outOfStockCount,
      'low_margin_product_count': lowMarginProductCount,
      'customer_risk_count': customerRiskCount,
      'top_risks': topRisks,
      'top_opportunities': topOpportunities,
      'summary_text': summaryText,
      'business_name': businessName,
      'sector': sector,
      'nace_code': naceCode,
      'employee_count': employeeCount,
      'annual_revenue_range': annualRevenueRange,
      'does_manufacture': doesManufacture,
      'does_export': doesExport,
      'wants_export': wantsExport,
      'needs_machinery': needsMachinery,
      'needs_digitalization': needsDigitalization,
      'needs_certification': needsCertification,
      'needs_financing': needsFinancing,
      'profile_completion': profileCompletion,
      'support_overall_score': supportOverallScore,
      'support_overall_status': supportOverallStatus,
      'top_support_opportunities': topSupportOpportunities,
      'missing_support_documents': missingSupportDocuments,
      'support_recommended_actions': supportRecommendedActions,
      'total_documents': totalDocuments,
      'missing_documents_count': missingDocumentsCount,
      'expired_documents_count': expiredDocumentsCount,
      'high_priority_missing_documents': highPriorityMissingDocuments,
      'support_readiness_score': supportReadinessScore,
      'latest_report_type': latestReportType,
      'latest_report_summary': latestReportSummary,
      'latest_report_risks': latestReportRisks,
      'latest_report_actions': latestReportActions,
    };
  }

  Map<String, dynamic> toSnapshotJson() {
    return {
      'monthly_income': monthlyIncome,
      'monthly_expense': monthlyExpense,
      'net_profit': netProfit,
      'pending_receivables': pendingReceivables,
      'overdue_receivables': overdueReceivables,
      'expected_cash_inflow_30d': expectedCashInflow30d,
      'expected_cash_outflow_30d': expectedCashOutflow30d,
      'net_cash_30d': netCash30d,
      'cash_score': cashScore,
      'critical_stock_count': criticalStockCount,
      'out_of_stock_count': outOfStockCount,
      'low_margin_product_count': lowMarginProductCount,
      'customer_risk_count': customerRiskCount,
      'top_risks': topRisks,
      'top_opportunities': topOpportunities,
      'summary_text': summaryText,
    };
  }
}
