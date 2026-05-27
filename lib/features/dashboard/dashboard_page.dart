import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/widgets/metric_card.dart';
import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/business_context_summary_model.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/cashflow_projection_model.dart';
import '../../data/repositories/business_profile_repository.dart';
import '../../data/repositories/cashflow_repository.dart';
import '../../data/repositories/documents_repository.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/services/business_context_service.dart';
import '../ai/ai_chat_page.dart';
import '../ai/cashflow_page.dart';
import '../auth/login_page.dart';
import '../business_profile/business_profile_page.dart';
import '../customers/customers_page.dart';
import '../documents/documents_page.dart';
import '../inventory/inventory_page.dart';
import '../profit_leakage/profit_leakage_page.dart';
import '../receipt_scanner/receipt_scanner_page.dart';
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

  bool _loading = true;
  String? _errorMessage;
  DashboardSummary? _summary;
  List<DashboardDailyAction> _dailyActions = const [];

  @override
  void initState() {
    super.initState();
    _load();
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
        profileCompletion:
            businessProfile?.profileCompletion ?? contextSummary.profileCompletion,
        totalDocuments: contextSummary.totalDocuments > 0
            ? contextSummary.totalDocuments
            : documentsSummary.totalDocuments,
        expiredDocumentsCount: contextSummary.expiredDocumentsCount > 0
            ? contextSummary.expiredDocumentsCount
            : documentsSummary.expiredDocuments,
        hasAnyBusinessData: _hasAnyBusinessData(
          contextSummary,
          businessProfile,
          documentsSummary,
          projection,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _dailyActions = buildDailyActions(summary);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Ana sayfa verileri alınamadı.\n$error';
      });
    }
  }

  bool _hasAnyBusinessData(
    BusinessContextSummaryModel contextSummary,
    BusinessProfileModel? businessProfile,
    DocumentSummary documentsSummary,
    CashflowProjectionModel? projection,
  ) {
    return contextSummary.hasFinancialData ||
        contextSummary.pendingReceivables > 0 ||
        contextSummary.criticalStockCount > 0 ||
        documentsSummary.totalDocuments > 0 ||
        (businessProfile?.profileCompletion ?? 0) > 0 ||
        projection != null;
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

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _handleActionTap(String module) {
    switch (module) {
      case 'finance':
      case 'transactions':
        _openPage(const TransactionsPage());
        break;
      case 'customers':
        _openPage(const CustomersPage());
        break;
      case 'cashflow':
        _openPage(const CashflowPage());
        break;
      case 'inventory':
        _openPage(const InventoryPage());
        break;
      case 'documents':
        _openPage(const DocumentsPage());
        break;
      case 'profile':
        _openPage(const BusinessProfilePage());
        break;
      case 'advisor':
        _openPage(const AiChatPage());
        break;
      case 'profit-leakage':
        _openPage(const ProfitLeakagePage());
        break;
      case 'receipt-scanner':
        _openPage(const ReceiptScannerPage());
        break;
      default:
        _openPage(const TransactionsPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bugünkü İş Planınız',
      subtitle: 'Bugün işletmenizde neye öncelik vermeniz gerektiğini tek ekranda görün.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: _logout,
          tooltip: 'Çıkış Yap',
          icon: const Icon(Icons.logout, color: AppColors.textPrimary),
        ),
      ],
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryNavy),
            )
          : _errorMessage != null
              ? _DashboardErrorState(
                  message: _errorMessage!,
                  onRetry: _load,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final priorities = _buildPriorityItems(summary);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeroCard(summary: summary),
            const SizedBox(height: 24),
            _PriorityActionsSection(
              items: priorities,
              onActionTap: _handleActionTap,
              isOnboarding: summary.shouldShowOnboarding,
            ),
            const SizedBox(height: 24),
            _FinanceSummarySection(summary: summary),
          ],
        );

        final rightColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuickActionsSection(
              onActionTap: _handleActionTap,
            ),
            const SizedBox(height: 24),
            _SmartKobiCommentCard(text: summary.dailySummaryText),
          ],
        );

        if (!isWide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftColumn,
                const SizedBox(height: 24),
                rightColumn,
                const SizedBox(height: 32),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: leftColumn),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: rightColumn),
            ],
          ),
        );
      },
    );
  }

  List<_PriorityActionViewModel> _buildPriorityItems(DashboardSummary summary) {
    final items = <_PriorityActionViewModel>[];

    if (summary.openPriceAlertCount > 0) {
      items.add(
        _PriorityActionViewModel(
          title: 'Maliyet artışı uyarılarını inceleyin',
          description:
              '${summary.openPriceAlertCount} açık fiyat uyarısı kârlılığınızı etkileyebilir.',
          module: 'profit-leakage',
          icon: Icons.trending_up_outlined,
          color: AppColors.warning,
        ),
      );
    }

    for (final action in _dailyActions) {
      items.add(
        _PriorityActionViewModel(
          title: action.title,
          description: action.description,
          module: action.module,
          icon: action.icon,
          color: _priorityColor(action.riskLevel),
        ),
      );
    }

    return items.take(3).toList();
  }
}

class _PriorityActionViewModel {
  const _PriorityActionViewModel({
    required this.title,
    required this.description,
    required this.module,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String module;
  final IconData icon;
  final Color color;
}

class _QuickActionViewModel {
  const _QuickActionViewModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.module,
    this.isFeatured = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String module;
  final bool isFeatured;
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _riskColor(summary.overallRiskLevel);
    final heroMessage = summary.shouldShowOnboarding
        ? 'İlk kayıtlarınızı oluşturarak günlük komuta merkezinizi aktive edin.'
        : summary.dailySummaryText;
    final criticalCount = _criticalAlertCount(summary);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.turquoiseSoft,
            AppColors.primaryNavySoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İyi çalışmalar!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bugün odak noktanız hazır',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      heroMessage,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _StatusBadge(
                label: summary.overallRiskLevel,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final itemWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetricTile(
                      title: 'Bekleyen Tahsilat',
                      value: AppFormatters.formatCurrency(summary.pendingReceivables),
                      icon: Icons.request_quote_outlined,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetricTile(
                      title: 'Nakit Skoru',
                      value: '${summary.cashScore}/100',
                      icon: Icons.waterfall_chart_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetricTile(
                      title: 'Kritik Uyarı',
                      value: criticalCount.toString(),
                      icon: Icons.notification_important_outlined,
                      color: criticalCount > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _criticalAlertCount(DashboardSummary summary) {
    var count = 0;
    if (summary.overdueReceivables > 0) {
      count += 1;
    }
    if (summary.criticalStockCount > 0) {
      count += 1;
    }
    if (summary.highPriorityMissingDocuments > 0) {
      count += 1;
    }
    if (summary.openPriceAlertCount > 0) {
      count += 1;
    }
    if (summary.cashScore < 60) {
      count += 1;
    }
    return count;
  }
}

class _PriorityActionsSection extends StatelessWidget {
  const _PriorityActionsSection({
    required this.items,
    required this.onActionTap,
    required this.isOnboarding,
  });

  final List<_PriorityActionViewModel> items;
  final ValueChanged<String> onActionTap;
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Bugün Öncelik Verilecekler',
          subtitle: 'Bugün işletmenizi en çok etkileyecek işleri öne çıkarır.',
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          SmartCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isOnboarding
                        ? 'İlk kayıtlarınızı ekleyerek günlük önceliklerinizi oluşturmaya başlayın.'
                        : 'Bugün kritik bir öncelik görünmüyor. İşletme durumunuz dengeli.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PriorityActionCard(
                item: item,
                onTap: () => onActionTap(item.module),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriorityActionCard extends StatelessWidget {
  const _PriorityActionCard({
    required this.item,
    required this.onTap,
  });

  final _PriorityActionViewModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.onActionTap,
  });

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickActionViewModel(
        title: 'Gelir/Gider',
        description: 'Yeni finans kaydı açın',
        icon: Icons.add_chart_outlined,
        module: 'finance',
      ),
      _QuickActionViewModel(
        title: 'Fiş Tara',
        description: 'Belgeden gider oluşturun',
        icon: Icons.document_scanner_outlined,
        module: 'receipt-scanner',
        isFeatured: true,
      ),
      _QuickActionViewModel(
        title: 'Müşteri Ekle',
        description: 'Cari listenizi büyütün',
        icon: Icons.person_add_alt_1_outlined,
        module: 'customers',
      ),
      _QuickActionViewModel(
        title: 'Tahsilat Mesajı',
        description: 'Nazik bir hatırlatma hazırlayın',
        icon: Icons.chat_bubble_outline,
        module: 'customers',
      ),
      _QuickActionViewModel(
        title: 'Nakit Kaydı',
        description: 'Ödeme planınızı güncelleyin',
        icon: Icons.waterfall_chart_outlined,
        module: 'cashflow',
      ),
      _QuickActionViewModel(
        title: 'Belge Yükle',
        description: 'Eksik evrak ekleyin',
        icon: Icons.upload_file_outlined,
        module: 'documents',
      ),
      _QuickActionViewModel(
        title: 'AI Danışman',
        description: 'Günlük yorumu derinleştirin',
        icon: Icons.smart_toy_outlined,
        module: 'advisor',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Hızlı İşlemler',
          subtitle: 'En sık kullanılan işlemleri tek dokunuşla başlatın.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            var columns = 2;
            if (constraints.maxWidth >= 900) {
              columns = 4;
            } else if (constraints.maxWidth >= 620) {
              columns = 3;
            }
            final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: width,
                      child: _QuickActionCard(
                        action: action,
                        onTap: () => onActionTap(action.module),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.action,
    required this.onTap,
  });

  final _QuickActionViewModel action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        action.isFeatured ? AppColors.primaryNavy : AppColors.info;
    final background = action.isFeatured
        ? const Color(0xFFF0FBFE)
        : AppColors.surface;
    final borderColor = action.isFeatured
        ? const Color(0xFFCDECF6)
        : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              action.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              action.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceSummarySection extends StatelessWidget {
  const _FinanceSummarySection({
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final netProfitColor =
        summary.netProfit >= 0 ? AppColors.success : AppColors.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Kısa Finans Özeti',
          subtitle: 'Bugünkü kararlar için en gerekli finans göstergeleri.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final width = isCompact
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 36) / 4;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: MetricCard(
                    title: 'Aylık Gelir',
                    value: AppFormatters.formatCurrency(summary.monthlyIncome),
                    icon: Icons.north_east_rounded,
                    color: AppColors.success,
                    subtitle: 'Gelir hareketleri',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MetricCard(
                    title: 'Aylık Gider',
                    value: AppFormatters.formatCurrency(summary.monthlyExpense),
                    icon: Icons.south_east_rounded,
                    color: AppColors.warning,
                    subtitle: 'Gider kayıtları',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MetricCard(
                    title: 'Net Kâr/Zarar',
                    value: AppFormatters.formatCurrency(summary.netProfit),
                    icon: Icons.account_balance_wallet_outlined,
                    color: netProfitColor,
                    subtitle: 'Bu ayın dengesi',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MetricCard(
                    title: 'Nakit Skoru',
                    value: '${summary.cashScore}/100',
                    icon: Icons.waterfall_chart_outlined,
                    color: AppColors.info,
                    subtitle: 'Kısa vadeli görünüm',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Bekleyen tahsilat: ${AppFormatters.formatCurrency(summary.pendingReceivables)} • Yaklaşan ödeme: ${AppFormatters.formatCurrency(summary.upcomingPayments7d)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _SmartKobiCommentCard extends StatelessWidget {
  const _SmartKobiCommentCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.turquoiseSoft,
            AppColors.primaryNavySoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SmartKOBİ Yorumu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
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
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                'Veriler alınamadı',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
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

Color _riskColor(String value) {
  switch (value) {
    case 'Acil':
      return AppColors.danger;
    case 'Riskli':
      return AppColors.warning;
    case 'Dikkat':
      return AppColors.info;
    default:
      return AppColors.success;
  }
}

Color _priorityColor(String riskLevel) {
  switch (riskLevel) {
    case 'high':
      return AppColors.danger;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.info;
  }
}
