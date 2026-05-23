import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/cashflow/cashflow_calculations.dart';
import '../models/business_context_summary_model.dart';
import '../models/cashflow_entry_model.dart';
import '../models/support_opportunity_model.dart';

class BusinessContextService {
  BusinessContextService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<BusinessContextSummaryModel> buildContextSummary() async {
    final user = _requireUser();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    double monthlyIncome = 0;
    double monthlyExpense = 0;
    double pendingReceivables = 0;
    double overdueReceivables = 0;
    double expectedCashInflow30d = 0;
    double expectedCashOutflow30d = 0;
    int cashScore = 50;
    int criticalStockCount = 0;
    int outOfStockCount = 0;
    int lowMarginProductCount = 0;
    int customerRiskCount = 0;
    String? businessName = user.userMetadata?['business_name']?.toString();
    String? sector;
    String? naceCode;
    int? employeeCount;
    String? annualRevenueRange;
    bool doesManufacture = false;
    bool doesExport = false;
    bool wantsExport = false;
    bool needsMachinery = false;
    bool needsDigitalization = false;
    bool needsCertification = false;
    bool needsFinancing = false;
    int profileCompletion = 0;
    int supportOverallScore = 0;
    String supportOverallStatus = 'needs_profile';
    List<String> topSupportOpportunities = const [];
    List<String> missingSupportDocuments = const [];
    List<String> supportRecommendedActions = const [];
    int totalDocuments = 0;
    int missingDocumentsCount = 0;
    int expiredDocumentsCount = 0;
    int highPriorityMissingDocuments = 0;
    int supportReadinessScore = 0;
    String? latestReportType;
    String? latestReportSummary;
    List<String> latestReportRisks = const [];
    List<String> latestReportActions = const [];

    await _loadTransactions(
      userId: user.id,
      monthStart: monthStart,
      monthEnd: monthEnd,
      onResult: (income, expense) {
        monthlyIncome = income;
        monthlyExpense = expense;
      },
    );

    await _loadCustomerTransactions(
      userId: user.id,
      onResult: (pending, overdue) {
        pendingReceivables = pending;
        overdueReceivables = overdue;
      },
    );

    final cashEntries = await _loadCashflowEntries(user.id);
    if (cashEntries.isNotEmpty) {
      expectedCashInflow30d = calculateExpectedInflow(cashEntries, 30);
      expectedCashOutflow30d = calculateExpectedOutflow(cashEntries, 30);
      final netCash30d =
          calculateNetCash(0, expectedCashInflow30d, expectedCashOutflow30d);
      cashScore = calculateCashScore(
        netCash30d: netCash30d,
        netCash60d: calculateNetCash(
          0,
          calculateExpectedInflow(cashEntries, 60),
          calculateExpectedOutflow(cashEntries, 60),
        ),
        overdueInflow: calculateOverdueInflow(cashEntries),
        expectedInflow30d: expectedCashInflow30d,
        upcomingOutflow30d: calculateUpcomingOutflow(cashEntries, 30),
        entries: cashEntries,
      );
    } else {
      await _loadCashflowSnapshot(
        userId: user.id,
        onResult: (inflow30d, outflow30d, score) {
          expectedCashInflow30d = inflow30d;
          expectedCashOutflow30d = outflow30d;
          cashScore = score;
        },
      );
    }

    await _loadInventory(
      userId: user.id,
      onResult: (critical, outOfStock, lowMargin) {
        criticalStockCount = critical;
        outOfStockCount = outOfStock;
        lowMarginProductCount = lowMargin;
      },
    );

    await _loadCustomers(
      userId: user.id,
      onResult: (riskCount) {
        customerRiskCount = riskCount;
      },
    );

    await _loadBusinessProfile(
      userId: user.id,
      onResult: (
        fetchedBusinessName,
        fetchedSector,
        fetchedNaceCode,
        fetchedEmployeeCount,
        fetchedAnnualRevenueRange,
        fetchedDoesManufacture,
        fetchedDoesExport,
        fetchedWantsExport,
        fetchedNeedsMachinery,
        fetchedNeedsDigitalization,
        fetchedNeedsCertification,
        fetchedNeedsFinancing,
        fetchedProfileCompletion,
      ) {
        businessName = fetchedBusinessName;
        sector = fetchedSector;
        naceCode = fetchedNaceCode;
        employeeCount = fetchedEmployeeCount;
        annualRevenueRange = fetchedAnnualRevenueRange;
        doesManufacture = fetchedDoesManufacture;
        doesExport = fetchedDoesExport;
        wantsExport = fetchedWantsExport;
        needsMachinery = fetchedNeedsMachinery;
        needsDigitalization = fetchedNeedsDigitalization;
        needsCertification = fetchedNeedsCertification;
        needsFinancing = fetchedNeedsFinancing;
        profileCompletion = fetchedProfileCompletion;
      },
    );

    await _loadSupportAnalysis(
      userId: user.id,
      onResult: (
        fetchedSupportOverallScore,
        fetchedSupportOverallStatus,
        fetchedTopSupportOpportunities,
        fetchedMissingSupportDocuments,
        fetchedSupportRecommendedActions,
      ) {
        supportOverallScore = fetchedSupportOverallScore;
        supportOverallStatus = fetchedSupportOverallStatus;
        topSupportOpportunities = fetchedTopSupportOpportunities;
        missingSupportDocuments = fetchedMissingSupportDocuments;
        supportRecommendedActions = fetchedSupportRecommendedActions;
      },
    );

    await _loadDocumentsSummary(
      userId: user.id,
      onResult: (
        fetchedTotalDocuments,
        fetchedMissingDocumentsCount,
        fetchedExpiredDocumentsCount,
        fetchedHighPriorityMissingDocuments,
        fetchedSupportReadinessScore,
      ) {
        totalDocuments = fetchedTotalDocuments;
        missingDocumentsCount = fetchedMissingDocumentsCount;
        expiredDocumentsCount = fetchedExpiredDocumentsCount;
        highPriorityMissingDocuments = fetchedHighPriorityMissingDocuments;
        supportReadinessScore = fetchedSupportReadinessScore;
      },
    );

    await _loadLatestReport(
      userId: user.id,
      onResult: (reportType, reportSummary, reportRisks, reportActions) {
        latestReportType = reportType;
        latestReportSummary = reportSummary;
        latestReportRisks = reportRisks;
        latestReportActions = reportActions;
      },
    );

    final netProfit = monthlyIncome - monthlyExpense;
    final netCash30d = expectedCashInflow30d - expectedCashOutflow30d;
    final topRisks = _buildTopRisks(
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      overdueReceivables: overdueReceivables,
      netCash30d: netCash30d,
      criticalStockCount: criticalStockCount,
      customerRiskCount: customerRiskCount,
    );
    final topOpportunities = _buildTopOpportunities(
      overdueReceivables: overdueReceivables,
      lowMarginProductCount: lowMarginProductCount,
      cashScore: cashScore,
      expectedCashInflow30d: expectedCashInflow30d,
    );
    final summaryText = _buildSummaryText(
      netProfit: netProfit,
      cashScore: cashScore,
      overdueReceivables: overdueReceivables,
      criticalStockCount: criticalStockCount,
    );

    final summary = BusinessContextSummaryModel(
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      netProfit: netProfit,
      pendingReceivables: pendingReceivables,
      overdueReceivables: overdueReceivables,
      expectedCashInflow30d: expectedCashInflow30d,
      expectedCashOutflow30d: expectedCashOutflow30d,
      netCash30d: netCash30d,
      cashScore: cashScore,
      criticalStockCount: criticalStockCount,
      outOfStockCount: outOfStockCount,
      lowMarginProductCount: lowMarginProductCount,
      customerRiskCount: customerRiskCount,
      topRisks: topRisks,
      topOpportunities: topOpportunities,
      summaryText: summaryText,
      businessName: businessName,
      sector: sector,
      naceCode: naceCode,
      employeeCount: employeeCount,
      annualRevenueRange: annualRevenueRange,
      doesManufacture: doesManufacture,
      doesExport: doesExport,
      wantsExport: wantsExport,
      needsMachinery: needsMachinery,
      needsDigitalization: needsDigitalization,
      needsCertification: needsCertification,
      needsFinancing: needsFinancing,
      profileCompletion: profileCompletion,
      supportOverallScore: supportOverallScore,
      supportOverallStatus: supportOverallStatus,
      topSupportOpportunities: topSupportOpportunities,
      missingSupportDocuments: missingSupportDocuments,
      supportRecommendedActions: supportRecommendedActions,
      totalDocuments: totalDocuments,
      missingDocumentsCount: missingDocumentsCount,
      expiredDocumentsCount: expiredDocumentsCount,
      highPriorityMissingDocuments: highPriorityMissingDocuments,
      supportReadinessScore: supportReadinessScore,
      latestReportType: latestReportType,
      latestReportSummary: latestReportSummary,
      latestReportRisks: latestReportRisks,
      latestReportActions: latestReportActions,
    );

    await _saveSnapshot(user.id, summary);
    return summary;
  }

  Future<void> _loadTransactions({
    required String userId,
    required DateTime monthStart,
    required DateTime monthEnd,
    required void Function(double income, double expense) onResult,
  }) async {
    try {
      final data = await _client
          .from('transactions')
          .select('amount, type, transaction_date')
          .eq('user_id', userId)
          .gte('transaction_date', _isoDate(monthStart))
          .lte('transaction_date', _isoDate(monthEnd));

      var income = 0.0;
      var expense = 0.0;
      for (final row in (data as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final amount = (map['amount'] as num?)?.toDouble() ?? 0;
        if (map['type'] == 'income') {
          income += amount;
        } else if (map['type'] == 'expense') {
          expense += amount;
        }
      }
      onResult(income, expense);
    } catch (_) {}
  }

  Future<void> _loadCustomerTransactions({
    required String userId,
    required void Function(double pending, double overdue) onResult,
  }) async {
    try {
      final data = await _client
          .from('customer_transactions')
          .select('amount, type, payment_status')
          .eq('user_id', userId);

      var pending = 0.0;
      var overdue = 0.0;
      for (final row in (data as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final status = map['payment_status']?.toString() ?? 'pending';
        final type = map['type']?.toString() ?? 'receivable';
        final amount = (map['amount'] as num?)?.toDouble() ?? 0;
        if (type == 'receivable' && status == 'pending') {
          pending += amount;
        }
        if (type == 'receivable' && status == 'overdue') {
          overdue += amount;
        }
      }
      onResult(pending, overdue);
    } catch (_) {}
  }

  Future<List<CashflowEntryModel>> _loadCashflowEntries(String userId) async {
    try {
      final data = await _client
          .from('cashflow_entries')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['expected', 'confirmed', 'overdue']);
      return (data as List<dynamic>)
          .map((item) => CashflowEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadCashflowSnapshot({
    required String userId,
    required void Function(double inflow30d, double outflow30d, int score) onResult,
  }) async {
    try {
      final data = await _client
          .from('cashflow_snapshots')
          .select('expected_inflow_30d, expected_outflow_30d, cash_score')
          .eq('user_id', userId)
          .order('snapshot_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data != null) {
        onResult(
          (data['expected_inflow_30d'] as num?)?.toDouble() ?? 0,
          (data['expected_outflow_30d'] as num?)?.toDouble() ?? 0,
          (data['cash_score'] as num?)?.toInt() ?? 50,
        );
      }
    } catch (_) {}
  }

  Future<void> _loadInventory({
    required String userId,
    required void Function(int critical, int outOfStock, int lowMargin) onResult,
  }) async {
    try {
      final data = await _client
          .from('inventory_items')
          .select('stock_quantity, min_stock_level, purchase_price, sale_price')
          .eq('user_id', userId)
          .eq('is_active', true);

      var critical = 0;
      var outOfStock = 0;
      var lowMargin = 0;
      for (final row in (data as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final stockQuantity = (map['stock_quantity'] as num?)?.toDouble() ?? 0;
        final minStockLevel = (map['min_stock_level'] as num?)?.toDouble() ?? 0;
        final purchasePrice = (map['purchase_price'] as num?)?.toDouble() ?? 0;
        final salePrice = (map['sale_price'] as num?)?.toDouble() ?? 0;
        if (stockQuantity <= 0) {
          outOfStock++;
        }
        if (stockQuantity <= minStockLevel) {
          critical++;
        }
        if (purchasePrice > 0) {
          final margin = ((salePrice - purchasePrice) / purchasePrice) * 100;
          if (margin < 15) {
            lowMargin++;
          }
        }
      }
      onResult(critical, outOfStock, lowMargin);
    } catch (_) {}
  }

  Future<void> _loadCustomers({
    required String userId,
    required void Function(int riskCount) onResult,
  }) async {
    try {
      final data = await _client
          .from('customers')
          .select('risk_level')
          .eq('user_id', userId)
          .eq('risk_level', 'high');
      onResult((data as List<dynamic>).length);
    } catch (_) {}
  }

  Future<void> _loadBusinessProfile({
    required String userId,
    required void Function(
      String? businessName,
      String? sector,
      String? naceCode,
      int? employeeCount,
      String? annualRevenueRange,
      bool doesManufacture,
      bool doesExport,
      bool wantsExport,
      bool needsMachinery,
      bool needsDigitalization,
      bool needsCertification,
      bool needsFinancing,
      int profileCompletion,
    ) onResult,
  }) async {
    try {
      final data = await _client
          .from('business_profiles')
          .select(
            'business_name, sector, nace_code, employee_count, annual_revenue_range, '
            'does_manufacture, does_export, wants_export, needs_machinery, '
            'needs_digitalization, needs_certification, needs_financing, profile_completion',
          )
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        return;
      }

      onResult(
        data['business_name']?.toString(),
        data['sector']?.toString(),
        data['nace_code']?.toString(),
        (data['employee_count'] as num?)?.toInt(),
        data['annual_revenue_range']?.toString(),
        data['does_manufacture'] as bool? ?? false,
        data['does_export'] as bool? ?? false,
        data['wants_export'] as bool? ?? false,
        data['needs_machinery'] as bool? ?? false,
        data['needs_digitalization'] as bool? ?? false,
        data['needs_certification'] as bool? ?? false,
        data['needs_financing'] as bool? ?? false,
        (data['profile_completion'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {}
  }

  Future<void> _loadSupportAnalysis({
    required String userId,
    required void Function(
      int supportOverallScore,
      String supportOverallStatus,
      List<String> topSupportOpportunities,
      List<String> missingSupportDocuments,
      List<String> supportRecommendedActions,
    ) onResult,
  }) async {
    try {
      final latest = await _client
          .from('support_analysis_results')
          .select(
            'id, overall_score, overall_status, missing_documents, recommended_actions',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latest == null) {
        return;
      }

      final rows = await _client
          .from('support_opportunities')
          .select()
          .eq('user_id', userId)
          .eq('analysis_result_id', latest['id'])
          .order('eligibility_score', ascending: false)
          .limit(3);

      List<String> parseList(dynamic value) {
        if (value is List) {
          return value.map((item) => item.toString()).toList();
        }
        return const [];
      }

      final opportunities = (rows as List<dynamic>)
          .map((row) => SupportOpportunityModel.fromJson(row as Map<String, dynamic>))
          .map((item) => item.title)
          .toList();

      onResult(
        (latest['overall_score'] as num?)?.toInt() ?? 0,
        latest['overall_status']?.toString() ?? 'needs_profile',
        opportunities,
        parseList(latest['missing_documents']),
        parseList(latest['recommended_actions']),
      );
    } catch (_) {}
  }

  Future<void> _loadDocumentsSummary({
    required String userId,
    required void Function(
      int totalDocuments,
      int missingDocumentsCount,
      int expiredDocumentsCount,
      int highPriorityMissingDocuments,
      int supportReadinessScore,
    ) onResult,
  }) async {
    try {
      final documents = await _client
          .from('business_documents')
          .select('status, expiry_date')
          .eq('user_id', userId);
      final requirements = await _client
          .from('document_requirements')
          .select('status, priority')
          .eq('user_id', userId);

      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      var expired = 0;
      var uploaded = 0;
      for (final row in (documents as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final status = map['status']?.toString() ?? 'uploaded';
        final expiryDate = DateTime.tryParse(map['expiry_date']?.toString() ?? '');
        if (status == 'uploaded' || status == 'approved' || status == 'needs_review') {
          uploaded++;
        }
        if (status == 'expired' || (expiryDate != null && expiryDate.isBefore(date))) {
          expired++;
        }
      }

      var missing = 0;
      var completed = 0;
      var highPriorityMissing = 0;
      for (final row in (requirements as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final status = map['status']?.toString() ?? 'missing';
        final priority = map['priority']?.toString() ?? 'medium';
        if (status == 'missing') {
          missing++;
          if (priority == 'high') {
            highPriorityMissing++;
          }
        }
        if (status == 'completed' || status == 'uploaded') {
          completed++;
        }
      }

      final score = (35 +
              (uploaded * 8) +
              (completed * 7) -
              (highPriorityMissing * 12) -
              (expired * 10) -
              (missing * 4))
          .clamp(0, 100)
          .toInt();

      onResult((documents).length, missing, expired, highPriorityMissing, score);
    } catch (_) {}
  }

  Future<void> _loadLatestReport({
    required String userId,
    required void Function(
      String? reportType,
      String? reportSummary,
      List<String> reportRisks,
      List<String> reportActions,
    ) onResult,
  }) async {
    try {
      final data = await _client
          .from('business_reports')
          .select('report_type, summary, risks, recommended_actions, status')
          .eq('user_id', userId)
          .neq('status', 'archived')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) {
        return;
      }

      List<String> parseList(dynamic value) {
        if (value is List) {
          return value.map((item) => item.toString()).toList();
        }
        return const [];
      }

      onResult(
        data['report_type']?.toString(),
        data['summary']?.toString(),
        parseList(data['risks']),
        parseList(data['recommended_actions']),
      );
    } catch (_) {}
  }

  List<String> _buildTopRisks({
    required double monthlyIncome,
    required double monthlyExpense,
    required double overdueReceivables,
    required double netCash30d,
    required int criticalStockCount,
    required int customerRiskCount,
  }) {
    final risks = <String>[];
    if (overdueReceivables > 0) {
      risks.add('Geciken tahsilat yüksek');
    }
    if (netCash30d < 0) {
      risks.add('30 günlük net nakit negatif');
    }
    if (criticalStockCount > 0) {
      risks.add('Kritik stokta ürünler var');
    }
    if (monthlyIncome > 0 && monthlyExpense / monthlyIncome > 0.7) {
      risks.add('Gider/gelir oranı yüksek');
    }
    if (customerRiskCount > 0) {
      risks.add('Yüksek riskli cari hesaplar var');
    }
    return risks;
  }

  List<String> _buildTopOpportunities({
    required double overdueReceivables,
    required int lowMarginProductCount,
    required int cashScore,
    required double expectedCashInflow30d,
  }) {
    final opportunities = <String>[];
    if (overdueReceivables > 0) {
      opportunities.add('Tahsilat planı netleştirilirse nakit skoru iyileşebilir');
    }
    if (lowMarginProductCount > 0) {
      opportunities.add('Düşük kâr marjlı ürünlerde fiyat güncellemesi yapılabilir');
    }
    if (cashScore < 80 || expectedCashInflow30d == 0) {
      opportunities.add('Düzenli nakit kayıtları tahmin doğruluğunu artırır');
    }
    if (opportunities.isEmpty) {
      opportunities.add('Düzenli veri girişi karar kalitesini daha da güçlendirebilir');
    }
    return opportunities;
  }

  String _buildSummaryText({
    required double netProfit,
    required int cashScore,
    required double overdueReceivables,
    required int criticalStockCount,
  }) {
    if (overdueReceivables > 0) {
      return 'Geciken tahsilatlar ve kısa vadeli nakit görünümü birlikte takip edilmelidir.';
    }
    if (cashScore < 60) {
      return 'Nakit görünümü dikkat gerektiriyor; ödeme ve tahsilat dengesi sık izlenmelidir.';
    }
    if (criticalStockCount > 0) {
      return 'Stok tarafında kritik seviyeye inen ürünler satış sürekliliğini etkileyebilir.';
    }
    if (netProfit < 0) {
      return 'Bu ay giderler kârlılığı baskılıyor; gider kırılımını incelemek iyi olur.';
    }
    return 'Genel görünüm dengeli; kayıt düzeni korundukça öneriler daha da netleşir.';
  }

  Future<void> _saveSnapshot(String userId, BusinessContextSummaryModel summary) async {
    try {
      await _client.from('ai_business_context_snapshots').insert({
        'user_id': userId,
        'context_date': _isoDate(DateTime.now()),
        ...summary.toSnapshotJson(),
      });
    } catch (_) {}
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  String _isoDate(DateTime value) => value.toIso8601String().split('T').first;
}
