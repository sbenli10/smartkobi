import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/dashboard/dashboard_daily_action_engine.dart';
import '../../features/dashboard/dashboard_summary_model.dart';
import '../models/business_context_summary_model.dart';
import '../models/business_profile_model.dart';
import '../models/report_summary_model.dart';
import '../repositories/business_profile_repository.dart';
import '../repositories/documents_repository.dart';
import '../repositories/support_analysis_repository.dart';
import 'business_context_service.dart';

class ReportDataService {
  ReportDataService({
    SupabaseClient? client,
    BusinessContextService? contextService,
    BusinessProfileRepository? businessProfileRepository,
    DocumentsRepository? documentsRepository,
    SupportAnalysisRepository? supportAnalysisRepository,
  })  : _client = client ?? Supabase.instance.client,
        _contextService = contextService ?? BusinessContextService(client: client),
        _businessProfileRepository =
            businessProfileRepository ?? BusinessProfileRepository(client: client),
        _documentsRepository = documentsRepository ?? DocumentsRepository(client: client),
        _supportAnalysisRepository =
            supportAnalysisRepository ?? SupportAnalysisRepository(client: client);

  final SupabaseClient _client;
  final BusinessContextService _contextService;
  final BusinessProfileRepository _businessProfileRepository;
  final DocumentsRepository _documentsRepository;
  final SupportAnalysisRepository _supportAnalysisRepository;

  Future<ReportSummaryModel> buildReportSummary({
    DateTime? start,
    DateTime? end,
  }) async {
    final context = await _contextService.buildContextSummary();
    BusinessProfileModel? profile;
    try {
      profile = await _businessProfileRepository.fetchMyBusinessProfile();
    } catch (_) {
      profile = null;
    }

    final dashboardSummary = DashboardSummary(
      monthlyIncome: context.monthlyIncome,
      monthlyExpense: context.monthlyExpense,
      netProfit: context.netProfit,
      pendingReceivables: context.pendingReceivables,
      overdueReceivables: context.overdueReceivables,
      upcomingPayments7d: context.expectedCashOutflow30d / 4,
      expectedInflow30d: context.expectedCashInflow30d,
      expectedOutflow30d: context.expectedCashOutflow30d,
      cashScore: context.cashScore,
      criticalStockCount: context.criticalStockCount,
      outOfStockCount: context.outOfStockCount,
      lowMarginProductCount: context.lowMarginProductCount,
      missingDocumentsCount: context.missingDocumentsCount,
      highPriorityMissingDocuments: context.highPriorityMissingDocuments,
      supportScore: context.supportOverallScore,
      profileCompletion: profile?.profileCompletion ?? context.profileCompletion,
      totalDocuments: context.totalDocuments,
      expiredDocumentsCount: context.expiredDocumentsCount,
      hasAnyBusinessData: _hasAnyBusinessData(context, profile),
    );

    final dailyActions = buildDailyActions(dashboardSummary);
    final topActions = dailyActions.map((item) => item.title).take(5).toList();

    return ReportSummaryModel(
      monthlyIncome: context.monthlyIncome,
      monthlyExpense: context.monthlyExpense,
      netProfit: context.netProfit,
      pendingReceivables: context.pendingReceivables,
      overdueReceivables: context.overdueReceivables,
      cashScore: context.cashScore,
      netCash30d: context.netCash30d,
      criticalStockCount: context.criticalStockCount,
      outOfStockCount: context.outOfStockCount,
      missingDocumentsCount: context.missingDocumentsCount,
      supportOverallScore: context.supportOverallScore,
      profileCompletion: profile?.profileCompletion ?? context.profileCompletion,
      dailyActionCount: dailyActions.length,
      overallRiskLevel: _toRiskLabel(context.overallRiskLevel),
      executiveSummary: context.summaryText ?? _buildExecutiveSummary(context),
      topRisks: context.topRisks.take(5).toList(),
      topActions: topActions,
    );
  }

  Future<Map<String, dynamic>> buildFinancialData({
    DateTime? start,
    DateTime? end,
  }) async {
    final user = _requireUser();
    final fallback = <String, dynamic>{
      'gelir_kalemleri': <Map<String, dynamic>>[],
      'gider_kalemleri': <Map<String, dynamic>>[],
      'gelir_kayit_sayisi': 0,
      'gider_kayit_sayisi': 0,
      'veri_durumu': 'veri bulunamadı',
    };

    try {
      var query = _client.from('transactions').select();
      query = query.eq('user_id', user.id);
      if (start != null) {
        query = query.gte('transaction_date', _isoDate(start));
      }
      if (end != null) {
        query = query.lte('transaction_date', _isoDate(end));
      }
      final rows = await query.order('transaction_date', ascending: false);
      final items = (rows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      final incomeByCategory = <String, double>{};
      final expenseByCategory = <String, double>{};
      var incomeCount = 0;
      var expenseCount = 0;

      for (final row in items) {
        final category = _cleanLabel(row['category'], fallback: 'Diğer');
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        final type = row['type']?.toString() ?? '';
        if (type == 'income') {
          incomeByCategory[category] = (incomeByCategory[category] ?? 0) + amount;
          incomeCount += 1;
        } else if (type == 'expense') {
          expenseByCategory[category] = (expenseByCategory[category] ?? 0) + amount;
          expenseCount += 1;
        }
      }

      return {
        'gelir_kalemleri': _sortedAmountMap(incomeByCategory),
        'gider_kalemleri': _sortedAmountMap(expenseByCategory),
        'gelir_kayit_sayisi': incomeCount,
        'gider_kayit_sayisi': expenseCount,
        'veri_durumu': items.isEmpty ? 'veri bulunamadı' : 'hazır',
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> buildCashflowData({
    DateTime? start,
    DateTime? end,
  }) async {
    final user = _requireUser();
    final fallback = <String, dynamic>{
      'otuz_gunluk_giris': 0.0,
      'otuz_gunluk_cikis': 0.0,
      'altmis_gunluk_giris': 0.0,
      'altmis_gunluk_cikis': 0.0,
      'yaklasan_odemeler': <Map<String, dynamic>>[],
      'geciken_tahsilatlar': <Map<String, dynamic>>[],
      'veri_durumu': 'veri bulunamadı',
    };

    try {
      final rows = await _client
          .from('cashflow_entries')
          .select()
          .eq('user_id', user.id)
          .order('expected_date');

      final items = (rows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      final now = DateTime.now();
      final day30 = now.add(const Duration(days: 30));
      final day60 = now.add(const Duration(days: 60));
      double inflow30 = 0;
      double outflow30 = 0;
      double inflow60 = 0;
      double outflow60 = 0;
      final upcomingPayments = <Map<String, dynamic>>[];

      for (final row in items) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        final expectedDate =
            DateTime.tryParse(row['expected_date']?.toString() ?? '') ?? now;
        final entryType = row['entry_type']?.toString() ?? '';
        final status = row['status']?.toString() ?? '';

        if (!expectedDate.isAfter(day30)) {
          if (entryType == 'inflow') {
            inflow30 += amount;
          } else if (entryType == 'outflow') {
            outflow30 += amount;
          }
        }
        if (!expectedDate.isAfter(day60)) {
          if (entryType == 'inflow') {
            inflow60 += amount;
          } else if (entryType == 'outflow') {
            outflow60 += amount;
          }
        }

        if (entryType == 'outflow' && status != 'paid' && !expectedDate.isBefore(now)) {
          upcomingPayments.add({
            'baslik': _cleanLabel(row['title'], fallback: 'Planlı ödeme'),
            'tutar': amount,
            'tarih': _isoDate(expectedDate),
          });
        }
      }

      final customerRisk = await buildCustomerRiskData(start: start, end: end);

      return {
        'otuz_gunluk_giris': inflow30,
        'otuz_gunluk_cikis': outflow30,
        'altmis_gunluk_giris': inflow60,
        'altmis_gunluk_cikis': outflow60,
        'yaklasan_odemeler': upcomingPayments.take(8).toList(),
        'geciken_tahsilatlar': customerRisk['riskli_musteriler'] ?? const [],
        'veri_durumu': items.isEmpty ? 'veri bulunamadı' : 'hazır',
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> buildCustomerRiskData({
    DateTime? start,
    DateTime? end,
  }) async {
    final user = _requireUser();
    final fallback = <String, dynamic>{
      'toplam_musteri': 0,
      'bekleyen_tahsilat': 0.0,
      'geciken_tahsilat': 0.0,
      'riskli_musteriler': <Map<String, dynamic>>[],
      'veri_durumu': 'veri bulunamadı',
    };

    try {
      final customerRows = await _client
          .from('customers')
          .select('id, name, current_balance, risk_level, next_collection_date')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      final transactionRows = await _client
          .from('customer_transactions')
          .select('customer_id, amount, title, payment_status, due_date, type')
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false);

      final customers = (customerRows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final transactions = (transactionRows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      double pending = 0;
      double overdue = 0;
      final risky = <Map<String, dynamic>>[];
      final byCustomer = <String, List<Map<String, dynamic>>>{};

      for (final row in transactions) {
        final type = row['type']?.toString() ?? '';
        if (type != 'receivable') {
          continue;
        }
        final status = row['payment_status']?.toString() ?? 'pending';
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        final customerId = row['customer_id']?.toString() ?? '';
        byCustomer.putIfAbsent(customerId, () => <Map<String, dynamic>>[]).add(row);
        if (status == 'pending') {
          pending += amount;
        }
        if (status == 'overdue') {
          overdue += amount;
        }
      }

      for (final customer in customers) {
        final id = customer['id']?.toString() ?? '';
        final items = byCustomer[id] ?? const <Map<String, dynamic>>[];
        final overdueAmount = items.fold<double>(0, (sum, item) {
          return sum +
              ((item['payment_status']?.toString() == 'overdue')
                  ? (item['amount'] as num?)?.toDouble() ?? 0
                  : 0);
        });
        if (overdueAmount <= 0 &&
            (customer['risk_level']?.toString() ?? 'low') != 'high') {
          continue;
        }
        risky.add({
          'musteri': _cleanLabel(customer['name'], fallback: 'Müşteri'),
          'risk': _customerRiskLabel(customer['risk_level']?.toString()),
          'geciken_tutar': overdueAmount,
          'bakiye': (customer['current_balance'] as num?)?.toDouble() ?? 0,
          'sonraki_tahsilat':
              _cleanLabel(customer['next_collection_date'], fallback: 'Planlanmadı'),
        });
      }

      risky.sort((a, b) => ((b['geciken_tutar'] as num?) ?? 0)
          .compareTo((a['geciken_tutar'] as num?) ?? 0));

      return {
        'toplam_musteri': customers.length,
        'bekleyen_tahsilat': pending,
        'geciken_tahsilat': overdue,
        'riskli_musteriler': risky.take(10).toList(),
        'veri_durumu': customers.isEmpty && transactions.isEmpty ? 'veri bulunamadı' : 'hazır',
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> buildInventoryRiskData({
    DateTime? start,
    DateTime? end,
  }) async {
    final user = _requireUser();
    final fallback = <String, dynamic>{
      'toplam_urun': 0,
      'kritik_urunler': <Map<String, dynamic>>[],
      'stokta_olmayanlar': <Map<String, dynamic>>[],
      'dusuk_marjli_urunler': <Map<String, dynamic>>[],
      'veri_durumu': 'veri bulunamadı',
    };

    try {
      final rows = await _client
          .from('inventory_items')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final items = (rows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      final critical = <Map<String, dynamic>>[];
      final outOfStock = <Map<String, dynamic>>[];
      final lowMargin = <Map<String, dynamic>>[];

      for (final row in items) {
        final name = _cleanLabel(row['name'], fallback: 'Ürün');
        final quantity = (row['stock_quantity'] as num?)?.toDouble() ?? 0;
        final minLevel = (row['min_stock_level'] as num?)?.toDouble() ?? 0;
        final purchasePrice = (row['purchase_price'] as num?)?.toDouble() ?? 0;
        final salePrice = (row['sale_price'] as num?)?.toDouble() ?? 0;
        final margin =
            purchasePrice > 0 ? ((salePrice - purchasePrice) / purchasePrice) * 100 : 0;

        if (quantity <= minLevel) {
          critical.add({
            'urun': name,
            'stok': quantity,
            'minimum': minLevel,
          });
        }
        if (quantity <= 0) {
          outOfStock.add({
            'urun': name,
            'stok': quantity,
          });
        }
        if (salePrice > 0 && margin < 15) {
          lowMargin.add({
            'urun': name,
            'marj_orani': margin,
            'alis': purchasePrice,
            'satis': salePrice,
          });
        }
      }

      return {
        'toplam_urun': items.length,
        'kritik_urunler': critical.take(12).toList(),
        'stokta_olmayanlar': outOfStock.take(12).toList(),
        'dusuk_marjli_urunler': lowMargin.take(12).toList(),
        'veri_durumu': items.isEmpty ? 'veri bulunamadı' : 'hazır',
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> buildSupportData({
    DateTime? start,
    DateTime? end,
  }) async {
    final fallback = <String, dynamic>{
      'genel_skor': 0,
      'durum': 'veri bulunamadı',
      'firsatlar': <String>[],
      'eksikler': <String>[],
      'onerilen_adimlar': <String>[],
      'destek_basliklari': <Map<String, dynamic>>[],
    };

    try {
      final analysis = await _supportAnalysisRepository.fetchLatestAnalysis();
      if (analysis == null) {
        return fallback;
      }
      final opportunities =
          await _supportAnalysisRepository.fetchOpportunities(analysis.id);

      return {
        'genel_skor': analysis.overallScore,
        'durum': analysis.statusLabel,
        'firsatlar': analysis.opportunityNotes,
        'eksikler': [
          ...analysis.missingProfileFields,
          ...analysis.missingDocuments,
        ],
        'onerilen_adimlar': analysis.recommendedActions,
        'destek_basliklari': opportunities
            .take(8)
            .map(
              (item) => {
                'baslik': item.title,
                'uygunluk': item.eligibilityScore,
                'durum': item.eligibilityStatusLabel,
                'oncelik': item.priorityLabel,
              },
            )
            .toList(),
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> buildDocumentData({
    DateTime? start,
    DateTime? end,
  }) async {
    final fallback = <String, dynamic>{
      'toplam_belge': 0,
      'eksik_belgeler': <String>[],
      'suresi_gecen_belgeler': <String>[],
      'suresi_yaklasan_belgeler': <String>[],
      'hazirlik_skoru': 0,
      'veri_durumu': 'veri bulunamadı',
    };

    try {
      final documents = await _documentsRepository.fetchDocuments();
      final requirements = await _documentsRepository.fetchRequirements();
      final summary = await _documentsRepository.buildDocumentSummary();

      return {
        'toplam_belge': summary.totalDocuments,
        'eksik_belgeler': requirements
            .where((item) => item.isMissing)
            .take(12)
            .map((item) => item.title)
            .toList(),
        'suresi_gecen_belgeler': documents
            .where((item) => item.isExpired)
            .take(12)
            .map((item) => item.title)
            .toList(),
        'suresi_yaklasan_belgeler': documents
            .where((item) => item.willExpireSoon)
            .take(12)
            .map((item) => item.title)
            .toList(),
        'hazirlik_skoru': summary.supportReadyScore,
        'veri_durumu': documents.isEmpty && requirements.isEmpty ? 'veri bulunamadı' : 'hazır',
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> buildBusinessProfileData({
    DateTime? start,
    DateTime? end,
  }) async {
    final fallback = <String, dynamic>{
      'isletme_adi': 'İşletme bilgisi bulunamadı',
      'sektor': 'Belirtilmedi',
      'nace': 'Belirtilmedi',
      'calisan': 'Belirtilmedi',
      'ciro_araligi': 'Belirtilmedi',
      'profil_tamamlama': 0,
      'veri_durumu': 'veri bulunamadı',
    };

    try {
      final profile = await _businessProfileRepository.fetchMyBusinessProfile();
      if (profile == null) {
        return fallback;
      }
      return {
        'id': profile.id,
        'isletme_adi': profile.businessName.trim().isEmpty
            ? 'İşletme bilgisi bulunamadı'
            : profile.businessName,
        'sektor': _cleanLabel(profile.sector, fallback: 'Belirtilmedi'),
        'nace': _cleanLabel(profile.naceCode, fallback: 'Belirtilmedi'),
        'calisan': profile.employeeCount?.toString() ?? 'Belirtilmedi',
        'ciro_araligi': _cleanLabel(profile.annualRevenueRange, fallback: 'Belirtilmedi'),
        'profil_tamamlama': profile.profileCompletion,
        'ihracat_hedefi': profile.wantsExport || profile.doesExport,
        'makine_ihtiyaci': profile.needsMachinery,
        'dijitallesme_ihtiyaci': profile.needsDigitalization,
        'sertifikasyon_ihtiyaci': profile.needsCertification,
        'finansman_ihtiyaci': profile.needsFinancing,
        'veri_durumu': 'hazır',
      };
    } catch (_) {
      return fallback;
    }
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  bool _hasAnyBusinessData(
    BusinessContextSummaryModel context,
    BusinessProfileModel? profile,
  ) {
    return context.hasFinancialData ||
        context.pendingReceivables > 0 ||
        context.overdueReceivables > 0 ||
        context.criticalStockCount > 0 ||
        context.totalDocuments > 0 ||
        context.missingDocumentsCount > 0 ||
        (profile?.profileCompletion ?? 0) > 0;
  }

  String _buildExecutiveSummary(BusinessContextSummaryModel context) {
    if (!context.hasFinancialData &&
        context.pendingReceivables <= 0 &&
        context.criticalStockCount <= 0) {
      return 'Rapor üretimi için yeterli işletme verisi henüz oluşmadı. Gelir-gider, cari, stok ve belge kayıtları eklendikçe özet güçlenir.';
    }
    if (context.cashScore < 40 || context.netCash30d < 0) {
      return 'Kısa vadeli nakit görünümü dikkat gerektiriyor. Tahsilatların hızlandırılması ve ödemelerin planlanması önerilir.';
    }
    if (context.overdueReceivables > 0) {
      return 'Vadesi geçmiş tahsilatlar işletmenin günlük akışını etkileyebilir. Cari öncelik listesinin güncellenmesi yararlı olur.';
    }
    if (context.criticalStockCount > 0) {
      return 'Stok tarafında aksiyon gerektiren ürünler bulunuyor. Tedarik planı ve satış hızı birlikte gözden geçirilmelidir.';
    }
    return 'İşletme verileri genel olarak dengeli görünüyor. Düzenli takip ile finans, cari ve stok görünümü korunabilir.';
  }

  String _toRiskLabel(String level) {
    switch (level) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      default:
        return 'Düşük';
    }
  }

  List<Map<String, dynamic>> _sortedAmountMap(Map<String, double> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((entry) => {'baslik': entry.key, 'tutar': entry.value})
        .toList();
  }

  String _cleanLabel(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _customerRiskLabel(String? value) {
    switch (value) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      default:
        return 'Düşük';
    }
  }

  String _isoDate(DateTime value) => value.toIso8601String().split('T').first;
}
