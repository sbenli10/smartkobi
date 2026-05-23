import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_context_summary_model.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/cashflow_projection_model.dart';
import '../../data/models/notification_summary_model.dart';
import '../../data/repositories/business_profile_repository.dart';
import '../../data/repositories/cashflow_repository.dart';
import '../../data/repositories/documents_repository.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/services/business_context_service.dart';
import '../ai/ai_chat_page.dart';
import '../ai/cashflow_page.dart';
import '../auth/login_page.dart';
import '../business_profile/business_profile_page.dart';
import '../cashflow/cashflow_calculations.dart';
import '../customers/customers_page.dart';
import '../documents/documents_page.dart';
import '../inventory/inventory_page.dart';
import '../notifications/notifications_page.dart';
import '../reports/reports_page.dart';
import '../support/support_analysis_page.dart';
import '../transactions/transactions_page.dart';
import 'dashboard_daily_action_engine.dart';
import 'dashboard_summary_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _contextService = BusinessContextService();
  final _businessProfileRepository = BusinessProfileRepository();
  final _documentsRepository = DocumentsRepository();
  final _cashflowRepository = CashflowRepository();
  final _notificationsRepository = NotificationsRepository();
  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL ');
  final _expenseAmountController = TextEditingController();
  final _expenseDescriptionController = TextEditingController();

  bool _loading = true;
  String? _errorMessage;
  BusinessContextSummaryModel _contextSummary = BusinessContextSummaryModel.empty();
  BusinessProfileModel? _businessProfile;
  DashboardSummary? _summary;
  NotificationSummaryModel _notificationSummary = NotificationSummaryModel.empty();
  CashflowProjectionModel? _projection;
  List<DashboardDailyAction> _dailyActions = const [];
  _QuickDecisionResult? _decisionResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _expenseAmountController.dispose();
    _expenseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final contextSummary = await _contextService.buildContextSummary();
      final businessProfile = await _businessProfileRepository.fetchMyBusinessProfile();
      try {
        await _notificationsRepository.generateAndSaveSmartReminders();
      } catch (_) {}
      NotificationSummaryModel notificationSummary;
      try {
        notificationSummary = await _notificationsRepository.fetchNotificationSummary();
      } catch (_) {
        notificationSummary = NotificationSummaryModel.empty();
      }

      DocumentSummary documentsSummary;
      try {
        documentsSummary = await _documentsRepository.buildDocumentSummary();
      } catch (_) {
        documentsSummary = const DocumentSummary(
          totalDocuments: 0,
          missingRequirements: 0,
          expiredDocuments: 0,
          willExpireDocuments: 0,
          uploadedDocuments: 0,
          highPriorityMissing: 0,
          supportReadyScore: 0,
          insight: '',
        );
      }

      CashflowProjectionModel? projection;
      try {
        projection = await _cashflowRepository.buildProjection();
      } catch (_) {
        projection = null;
      }

      double upcomingPayments7d = 0;
      try {
        final now = DateTime.now();
        final entries = await _cashflowRepository.fetchCashflowEntriesBetween(
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day).add(const Duration(days: 7)),
        );
        for (final entry in entries) {
          if (entry.isOutflow && !entry.isPaid) {
            upcomingPayments7d += entry.amount;
          }
        }
      } catch (_) {}

      final summary = DashboardSummary(
        monthlyIncome: contextSummary.monthlyIncome,
        monthlyExpense: contextSummary.monthlyExpense,
        netProfit: contextSummary.netProfit,
        pendingReceivables: contextSummary.pendingReceivables,
        overdueReceivables: contextSummary.overdueReceivables,
        upcomingPayments7d: upcomingPayments7d,
        expectedInflow30d: contextSummary.expectedCashInflow30d,
        expectedOutflow30d: contextSummary.expectedCashOutflow30d,
        cashScore: contextSummary.cashScore,
        criticalStockCount: contextSummary.criticalStockCount,
        outOfStockCount: contextSummary.outOfStockCount,
        lowMarginProductCount: contextSummary.lowMarginProductCount,
        missingDocumentsCount: contextSummary.missingDocumentsCount,
        highPriorityMissingDocuments: contextSummary.highPriorityMissingDocuments,
        supportScore: contextSummary.supportOverallScore,
        profileCompletion: businessProfile?.profileCompletion ?? contextSummary.profileCompletion,
        totalDocuments: contextSummary.totalDocuments > 0
            ? contextSummary.totalDocuments
            : documentsSummary.totalDocuments,
        expiredDocumentsCount: contextSummary.expiredDocumentsCount > 0
            ? contextSummary.expiredDocumentsCount
            : documentsSummary.expiredDocuments,
        hasAnyBusinessData: _hasAnyBusinessData(
          contextSummary: contextSummary,
          profile: businessProfile,
          documentsSummary: documentsSummary,
          projection: projection,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _contextSummary = contextSummary;
        _businessProfile = businessProfile;
        _projection = projection;
        _summary = summary;
        _notificationSummary = notificationSummary;
        _dailyActions = buildDailyActions(summary);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage =
            'Ana sayfa verileri alınamadı. Lütfen bağlantınızı kontrol edin.\n$error';
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPagePremium()),
    );
  }

  void _openTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionsPage()),
    );
  }

  void _openCustomers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomersPage()),
    );
  }

  void _openInventory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InventoryPage()),
    );
  }

  void _openAiChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiChatPage()),
    );
  }

  void _openBusinessProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BusinessProfilePage()),
    );
  }

  void _openSupportAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupportAnalysisPage()),
    );
  }

  void _openDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentsPage()),
    );
  }

  void _openCashflow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CashflowPage()),
    );
  }

  void _openReports([String? reportType]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsPage(initialReportType: reportType),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _handleActionTap(String module) {
    switch (module) {
      case 'customers':
        _openCustomers();
        break;
      case 'cashflow':
        _openCashflow();
        break;
      case 'inventory':
        _openInventory();
        break;
      case 'documents':
        _openDocuments();
        break;
      case 'profile':
        _openBusinessProfile();
        break;
      case 'advisor':
        _openAiChat();
        break;
      case 'support':
        _openSupportAnalysis();
        break;
      default:
        _openTransactions();
    }
  }

  void _runQuickDecision() {
    final summary = _summary;
    if (summary == null) {
      return;
    }
    final amount = double.tryParse(
      _expenseAmountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 0’dan büyük bir tutar girin.')),
      );
      return;
    }

    late final String riskLevel;
    late final String title;
    late final String description;

    if (_projection != null) {
      final analysis = analyzeExpenseScenario(
        title: _expenseDescriptionController.text.trim().isEmpty
            ? 'Planlanan harcama'
            : _expenseDescriptionController.text.trim(),
        plannedExpenseAmount: amount,
        plannedExpenseDate: DateTime.now(),
        openingBalance: _projection!.openingBalance,
        projection: _projection!,
      );

      if (analysis.riskLevel == 'critical' || analysis.riskLevel == 'high') {
        riskLevel = 'Yüksek risk';
        title = 'Önce tahsilatları netleştirin';
      } else if (analysis.riskLevel == 'medium') {
        riskLevel = 'Orta risk';
        title = 'Dikkatle ilerleyin';
      } else {
        riskLevel = 'Düşük risk';
        title = 'Harcama yönetilebilir görünüyor';
      }
      description = '${analysis.resultSummary} ${analysis.recommendation}'.trim();
    } else {
      final effectiveScore = summary.cashScore;
      final effectiveNetCash = summary.expectedInflow30d - summary.expectedOutflow30d;
      final adjustedScore =
          (effectiveScore - (amount > 25000 ? 30 : amount > 10000 ? 18 : 8)).clamp(0, 100);
      final adjustedNetCash = effectiveNetCash - amount;

      if (adjustedScore < 40 || adjustedNetCash < 0) {
        riskLevel = 'Yüksek risk';
        title = 'Önce tahsilatları netleştirin';
        description =
            'Bu harcama mevcut nakit görünümüne göre baskı oluşturabilir. Önce bekleyen tahsilatları kontrol etmeniz önerilir.';
      } else if (adjustedScore < 60) {
        riskLevel = 'Orta risk';
        title = 'Dikkatle ilerleyin';
        description =
            'Bu harcama orta riskli görünüyor. Ödeme tarihini ve kısa vadeli tahsilatları birlikte gözden geçirmeniz iyi olur.';
      } else {
        riskLevel = 'Düşük risk';
        title = 'Harcama yönetilebilir görünüyor';
        description =
            'Mevcut görünümde bu harcama yönetilebilir duruyor. Yine de önümüzdeki 30 günlük ödemeleri takip etmeyi sürdürün.';
      }
    }

    setState(() {
      _decisionResult = _QuickDecisionResult(
        title: title,
        riskLevel: riskLevel,
        description: description,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bugünkü İş Planınız',
      subtitle:
          'Öncelikli tahsilat, ödeme, stok ve nakit uyarılarınızı tek ekranda görün.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: _logout,
          tooltip: 'Çıkış Yap',
          icon: const Icon(Icons.logout),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _DashboardError(message: _errorMessage!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final showOnboarding = summary.shouldShowOnboarding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;

        final left = [
          _TodayHero(
            summary: summary,
            businessName: _businessProfile?.businessName ?? _contextSummary.businessName,
          ),
          const SizedBox(height: 16),
          if (showOnboarding)
            _OnboardingCard(
              onIncome: _openTransactions,
              onCustomer: _openCustomers,
              onProduct: _openInventory,
            )
          else
            _DailyActionsCard(
              actions: _dailyActions,
              onActionTap: _handleActionTap,
            ),
          const SizedBox(height: 16),
          _FinanceStrip(
            summary: summary,
            currency: _currency,
          ),
          const SizedBox(height: 16),
          _ReceivablePaymentRow(
            summary: summary,
            currency: _currency,
            onCustomers: _openCustomers,
            onCashflow: _openCashflow,
          ),
          const SizedBox(height: 16),
          _StockAlertsCard(
            summary: summary,
            onOpenInventory: _openInventory,
          ),
        ];

        final right = [
          _QuickDecisionCard(
            amountController: _expenseAmountController,
            descriptionController: _expenseDescriptionController,
            result: _decisionResult,
            onCheck: _runQuickDecision,
            onDetailedAnalysis: _openCashflow,
          ),
          const SizedBox(height: 16),
          _DailyCommentaryCard(text: summary.dailySummaryText),
          const SizedBox(height: 16),
          _DocumentSupportCard(
            summary: summary,
            onOpenDocuments: _openDocuments,
            onOpenSupport: _openSupportAnalysis,
            onOpenProfile: _openBusinessProfile,
          ),
          const SizedBox(height: 16),
          _ReportsOverviewCard(
            latestReportType: _contextSummary.latestReportType,
            latestReportSummary: _contextSummary.latestReportSummary,
            onOpenReports: _openReports,
          ),
          const SizedBox(height: 16),
          _NotificationsOverviewCard(
            summary: _notificationSummary,
            onOpenNotifications: _openNotifications,
            onRefreshReminders: _load,
          ),
          const SizedBox(height: 16),
          _QuickActionsCard(
            onIncome: _openTransactions,
            onExpense: _openTransactions,
            onCustomer: _openCustomers,
            onProduct: _openInventory,
            onCashflow: _openCashflow,
            onDocuments: _openDocuments,
            onAdvisor: _openAiChat,
          ),
        ];

        if (isWide) {
          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: left,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: right,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...left,
              const SizedBox(height: 16),
              ...right,
            ],
          ),
        );
      },
    );
  }

  bool _hasAnyBusinessData({
    required BusinessContextSummaryModel contextSummary,
    required BusinessProfileModel? profile,
    required DocumentSummary documentsSummary,
    required CashflowProjectionModel? projection,
  }) {
    return contextSummary.hasFinancialData ||
        contextSummary.pendingReceivables > 0 ||
        contextSummary.overdueReceivables > 0 ||
        contextSummary.criticalStockCount > 0 ||
        documentsSummary.totalDocuments > 0 ||
        documentsSummary.missingRequirements > 0 ||
        (profile?.profileCompletion ?? 0) > 0 ||
        projection != null;
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.summary,
    this.businessName,
  });

  final DashboardSummary summary;
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    final badgeColor = _riskColor(summary.overallRiskLevel);
    return SmartCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName?.trim().isNotEmpty == true
                      ? '$businessName için günlük görünüm'
                      : 'SmartKOBİ günlük görünümü',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'SmartKOBİ, işletmenizde bugün öncelik vermeniz gereken konuları özetler.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badgeColor.withValues(alpha: 0.22)),
            ),
            child: Text(
              summary.overallRiskLevel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyActionsCard extends StatelessWidget {
  const _DailyActionsCard({
    required this.actions,
    required this.onActionTap,
  });

  final List<DashboardDailyAction> actions;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Bugün Öncelik Verilecekler',
            subtitle: 'Bugünün en önemli tahsilat, ödeme, stok ve belge aksiyonları',
          ),
          const SizedBox(height: 14),
          if (actions.isEmpty)
            const Text('Bugün öne çıkan kritik bir aksiyon görünmüyor.')
          else
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DailyActionTile(
                  action: action,
                  onTap: () => onActionTap(action.module),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.onIncome,
    required this.onCustomer,
    required this.onProduct,
  });

  final VoidCallback onIncome;
  final VoidCallback onCustomer;
  final VoidCallback onProduct;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SmartKOBİ günlük iş planınızı hazırlamak için birkaç kayıt gerekiyor.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Gelir-gider, müşteri, stok ve nakit kayıtlarınızı ekledikçe bugün neye öncelik vermeniz gerektiğini burada göreceksiniz.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onIncome,
                icon: const Icon(Icons.add_chart),
                label: const Text('İlk Gelir/Gider Kaydını Ekle'),
              ),
              OutlinedButton.icon(
                onPressed: onCustomer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('İlk Müşteriyi Ekle'),
              ),
              OutlinedButton.icon(
                onPressed: onProduct,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('İlk Ürünü Ekle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyActionTile extends StatelessWidget {
  const _DailyActionTile({
    required this.action,
    required this.onTap,
  });

  final DashboardDailyAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(action.riskLevel == 'high' ? 'Acil' : 'Dikkat');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: riskColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${action.category} • ${action.priority == 'high' ? 'Öncelikli' : 'Takip'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _RiskBadge(label: action.riskLevel == 'high' ? 'Yüksek' : 'Orta', color: riskColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(action.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            action.recommendation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(action.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDecisionCard extends StatelessWidget {
  const _QuickDecisionCard({
    required this.amountController,
    required this.descriptionController,
    required this.result,
    required this.onCheck,
    required this.onDetailedAnalysis,
  });

  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final _QuickDecisionResult? result;
  final VoidCallback onCheck;
  final VoidCallback onDetailedAnalysis;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(result?.riskLevel ?? 'Dikkat');
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Bu Harcamayı Yapabilir miyim?',
            subtitle: 'Hızlı bir ön kontrol ile harcamanın nakit görünümüne etkisini görün',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tutar',
              hintText: 'Örn. 15000',
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Örn. ekipman alımı',
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.rule_outlined),
              label: const Text('Kontrol Et'),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RiskBadge(label: result!.riskLevel, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result!.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(result!.description),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onDetailedAnalysis,
              icon: const Icon(Icons.waterfall_chart_outlined),
              label: const Text('Nakit AI’da Detaylı Analiz Et'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinanceStrip extends StatelessWidget {
  const _FinanceStrip({
    required this.summary,
    required this.currency,
  });

  final DashboardSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MiniMetric('Aylık Gelir', currency.format(summary.monthlyIncome), AppColors.success),
      _MiniMetric('Aylık Gider', currency.format(summary.monthlyExpense), AppColors.danger),
      _MiniMetric('Net Kâr/Zarar', currency.format(summary.netProfit), summary.netProfit >= 0 ? AppColors.gold400 : AppColors.warning),
      _MiniMetric('Tahsil Edilecek', currency.format(summary.pendingReceivables), AppColors.info),
      _MiniMetric('Ödenecek', currency.format(summary.upcomingPayments7d), AppColors.warning),
      _MiniMetric('Nakit Skoru', '${summary.cashScore}/100', AppColors.gold500),
    ];

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Finans Özeti',
            subtitle: 'Günün kısa finans görünümü',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000 ? 6 : constraints.maxWidth >= 640 ? 3 : 2;
              final itemWidth = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map((item) => SizedBox(width: itemWidth, child: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReceivablePaymentRow extends StatelessWidget {
  const _ReceivablePaymentRow({
    required this.summary,
    required this.currency,
    required this.onCustomers,
    required this.onCashflow,
  });

  final DashboardSummary summary;
  final NumberFormat currency;
  final VoidCallback onCustomers;
  final VoidCallback onCashflow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 760;
        final receivableCard = _CompactInfoCard(
          title: 'Tahsilat',
          rows: [
            _InfoRow('Bekleyen tahsilat', currency.format(summary.pendingReceivables)),
            _InfoRow('Geciken tahsilat', currency.format(summary.overdueReceivables)),
          ],
          buttonLabel: 'Tahsilatları Gör',
          icon: Icons.request_quote_outlined,
          color: AppColors.info,
          onPressed: onCustomers,
        );

        final paymentCard = _CompactInfoCard(
          title: 'Ödemeler',
          rows: [
            _InfoRow('7 gün içindeki ödeme', currency.format(summary.upcomingPayments7d)),
            _InfoRow('30 günlük ödeme planı', currency.format(summary.expectedOutflow30d)),
          ],
          buttonLabel: 'Ödeme Planına Git',
          icon: Icons.payments_outlined,
          color: AppColors.warning,
          onPressed: onCashflow,
        );

        if (vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              receivableCard,
              const SizedBox(height: 12),
              paymentCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: receivableCard),
            const SizedBox(width: 12),
            Expanded(child: paymentCard),
          ],
        );
      },
    );
  }
}

class _StockAlertsCard extends StatelessWidget {
  const _StockAlertsCard({
    required this.summary,
    required this.onOpenInventory,
  });

  final DashboardSummary summary;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Stok Uyarıları',
            subtitle: 'Kritik ürünler ve marj görünümü',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TinyStateBox(label: 'Kritik stok', value: '${summary.criticalStockCount} ürün'),
              _TinyStateBox(label: 'Stokta yok', value: '${summary.outOfStockCount} ürün'),
              _TinyStateBox(label: 'Düşük marj', value: '${summary.lowMarginProductCount} ürün'),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onOpenInventory,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Stokları Kontrol Et'),
          ),
        ],
      ),
    );
  }
}

class _DailyCommentaryCard extends StatelessWidget {
  const _DailyCommentaryCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ Günlük Yorumu',
            subtitle: 'Bugünün kısa yönetim notu',
          ),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _DocumentSupportCard extends StatelessWidget {
  const _DocumentSupportCard({
    required this.summary,
    required this.onOpenDocuments,
    required this.onOpenSupport,
    required this.onOpenProfile,
  });

  final DashboardSummary summary;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final subtitle = summary.profileCompletion < 70
        ? 'İşletme profilinizi tamamladıkça destek hazırlığı daha net görünür.'
        : 'Belge ve destek hazırlığı durumunuzu tek kartta izleyin.';

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Belge ve Destek Hazırlığı',
            subtitle: subtitle,
          ),
          const SizedBox(height: 14),
          _InfoRow('Eksik belge', '${summary.missingDocumentsCount}'),
          const SizedBox(height: 8),
          _InfoRow('Yüksek öncelikli eksik', '${summary.highPriorityMissingDocuments}'),
          const SizedBox(height: 8),
          _InfoRow('Süresi geçen belge', '${summary.expiredDocumentsCount}'),
          const SizedBox(height: 8),
          _InfoRow('Profil tamamlama', '%${summary.profileCompletion}'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenDocuments,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Belgeler’e Git'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenSupport,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Destek Analizi'),
              ),
              if (summary.profileCompletion < 70)
                OutlinedButton.icon(
                  onPressed: onOpenProfile,
                  icon: const Icon(Icons.business_center_outlined),
                  label: const Text('Profili Tamamla'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onIncome,
    required this.onExpense,
    required this.onCustomer,
    required this.onProduct,
    required this.onCashflow,
    required this.onDocuments,
    required this.onAdvisor,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onCustomer;
  final VoidCallback onProduct;
  final VoidCallback onCashflow;
  final VoidCallback onDocuments;
  final VoidCallback onAdvisor;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionItem('Gelir Ekle', Icons.add_chart, onIncome),
      _QuickActionItem('Gider Ekle', Icons.money_off_csred_outlined, onExpense),
      _QuickActionItem('Müşteri Ekle', Icons.person_add_alt_1, onCustomer),
      _QuickActionItem('Ürün Ekle', Icons.add_box_outlined, onProduct),
      _QuickActionItem('Nakit Kaydı Ekle', Icons.waterfall_chart_outlined, onCashflow),
      _QuickActionItem('Belge Yükle', Icons.upload_file_outlined, onDocuments),
      _QuickActionItem('AI Danışmana Sor', Icons.smart_toy_outlined, onAdvisor),
    ];

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Hızlı İşlemler',
            subtitle: 'Günlük işlemleri tek dokunuşla başlatın',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 480 ? 2 : 1;
              final itemWidth = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: actions
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: OutlinedButton.icon(
                          onPressed: item.onTap,
                          icon: Icon(item.icon, color: AppColors.gold500),
                          label: Text(item.label),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportsOverviewCard extends StatelessWidget {
  const _ReportsOverviewCard({
    required this.latestReportType,
    required this.latestReportSummary,
    required this.onOpenReports,
  });

  final String? latestReportType;
  final String? latestReportSummary;
  final ValueChanged<String?> onOpenReports;

  @override
  Widget build(BuildContext context) {
    final hasReport = (latestReportType ?? '').trim().isNotEmpty;
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Son Rapor',
            subtitle: 'Yönetim raporlarınızı tek yerden takip edin',
          ),
          const SizedBox(height: 12),
          Text(
            hasReport ? _reportTypeLabel(latestReportType!) : 'Henüz rapor oluşturulmadı',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasReport
                ? (latestReportSummary?.trim().isNotEmpty == true
                    ? latestReportSummary!
                    : 'Son oluşturulan raporun özeti burada görünür.')
                : 'KOBİ Sağlık Raporu oluşturarak işletmenizin genel durumunu tek çıktıda görebilirsiniz.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => onOpenReports(hasReport ? latestReportType : 'business_health'),
                icon: Icon(hasReport ? Icons.visibility_outlined : Icons.add_chart),
                label: Text(hasReport ? 'Raporlara Git' : 'KOBİ Sağlık Raporu Oluştur'),
              ),
              if (hasReport)
                OutlinedButton.icon(
                  onPressed: () => onOpenReports('weekly_action_plan'),
                  icon: const Icon(Icons.date_range_outlined),
                  label: const Text('Haftalık Plan Raporu'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationsOverviewCard extends StatelessWidget {
  const _NotificationsOverviewCard({
    required this.summary,
    required this.onOpenNotifications,
    required this.onRefreshReminders,
  });

  final NotificationSummaryModel summary;
  final VoidCallback onOpenNotifications;
  final VoidCallback onRefreshReminders;

  @override
  Widget build(BuildContext context) {
    final hasNotifications = summary.totalCount > 0;
    final latestItems = summary.latestNotifications.take(3).toList();
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Bugünkü Hatırlatmalar',
            subtitle: 'Önemli uyarıları ve günlük asistan bildirimlerini izleyin',
          ),
          const SizedBox(height: 12),
          Text(
            hasNotifications
                ? '${summary.unreadCount} okunmamış bildirim var'
                : 'Henüz bildirim görünmüyor',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            summary.criticalCount > 0
                ? 'Kritik bildirimleriniz var. Öncelikle tahsilat, belge ve nakit uyarılarını kontrol edin.'
                : 'SmartKOBİ, önemli tahsilat, ödeme, stok ve belge uyarılarını burada özetler.',
          ),
          const SizedBox(height: 12),
          if (latestItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Yeni hatırlatma üretildiğinde burada son bildirimleriniz görünecek.'),
            )
          else
            ...latestItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isCritical ? Icons.priority_high : Icons.notifications_outlined,
                        color: item.isCritical ? AppColors.danger : AppColors.gold500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onOpenNotifications,
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Bildirimleri Gör'),
              ),
              OutlinedButton.icon(
                onPressed: onRefreshReminders,
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Hatırlatmaları Yenile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  const _CompactInfoCard({
    required this.title,
    required this.rows,
    required this.buttonLabel,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String title;
  final List<_InfoRow> rows;
  final String buttonLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TinyStateBox extends StatelessWidget {
  const _TinyStateBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _reportTypeLabel(String value) {
  switch (value) {
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
      return 'Rapor';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SmartCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.warning, size: 36),
              const SizedBox(height: 12),
              Text(
                'Ana sayfa verileri alınamadı',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDecisionResult {
  const _QuickDecisionResult({
    required this.title,
    required this.riskLevel,
    required this.description,
  });

  final String title;
  final String riskLevel;
  final String description;
}

class _QuickActionItem {
  const _QuickActionItem(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

Color _riskColor(String riskLevel) {
  switch (riskLevel) {
    case 'Acil':
    case 'Yüksek risk':
    case 'high':
      return AppColors.danger;
    case 'Riskli':
    case 'Orta risk':
    case 'Dikkat':
      return AppColors.warning;
    case 'Güvenli':
    case 'Düşük risk':
    case 'low':
      return AppColors.success;
    default:
      return AppColors.gold500;
  }
}
