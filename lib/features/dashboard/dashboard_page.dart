import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
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
import 'package:smartkobi/features/inventory/inventory_page.dart';
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
  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL ');

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
          totalDocuments: 0, missingRequirements: 0, expiredDocuments: 0,
          willExpireDocuments: 0, uploadedDocuments: 0, highPriorityMissing: 0,
          supportReadyScore: 0, insight: '',
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
        hasAnyBusinessData: _hasAnyBusinessData(contextSummary, businessProfile, documentsSummary, projection),
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
    BusinessContextSummaryModel ctx,
    BusinessProfileModel? prof,
    DocumentSummary doc,
    CashflowProjectionModel? proj,
  ) {
    return ctx.hasFinancialData ||
        ctx.pendingReceivables > 0 ||
        ctx.criticalStockCount > 0 ||
        doc.totalDocuments > 0 ||
        (prof?.profileCompletion ?? 0) > 0 ||
        proj != null;
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPagePremium()));
  }

  // --- Routing Methods ---
  void _openPage(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _handleActionTap(String module) {
    switch (module) {
      case 'customers': _openPage(const CustomersPage()); break;
      case 'cashflow': _openPage(const CashflowPage()); break;
      case 'inventory': _openPage(InventoryPage()); break;   
      case 'documents': _openPage(const DocumentsPage()); break;
      case 'profile': _openPage(const BusinessProfilePage()); break;
      case 'advisor': _openPage(const AiChatPage()); break;
      default: _openPage(const TransactionsPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bugünkü İş Planınız',
      subtitle: 'SmartKOBİ, bugün öncelik vermeniz gereken işleri sizin için özetler.',
      actions: [
        IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh, color: AppColors.textPrimary), tooltip: 'Yenile'),
        IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: AppColors.textPrimary), tooltip: 'Çıkış Yap'),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeroCard(summary: summary),
              const SizedBox(height: 24),
              
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPrioritiesSection(summary),
                          const SizedBox(height: 24),
                          _FinanceSummarySection(summary: summary, currency: _currency),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuickActionsGrid(onOpen: _handleActionTap, onOpenScanner: () => _openPage(const ReceiptScannerPage())),
                          const SizedBox(height: 24),
                          _WarningSection(summary: summary, onAction: _handleActionTap),
                          const SizedBox(height: 24),
                          _SmartKobiCommentCard(text: summary.dailySummaryText),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _buildPrioritiesSection(summary),
                const SizedBox(height: 24),
                _QuickActionsGrid(onOpen: _handleActionTap, onOpenScanner: () => _openPage(const ReceiptScannerPage())),
                const SizedBox(height: 24),
                _FinanceSummarySection(summary: summary, currency: _currency),
                const SizedBox(height: 24),
                _WarningSection(summary: summary, onAction: _handleActionTap),
                const SizedBox(height: 24),
                _SmartKobiCommentCard(text: summary.dailySummaryText),
                const SizedBox(height: 40),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrioritiesSection(DashboardSummary summary) {
    if (summary.shouldShowOnboarding) {
      return _EmptyDashboardState(
        onIncome: () => _handleActionTap('transactions'),
        onCustomer: () => _handleActionTap('customers'),
        onProduct: () => _handleActionTap('inventory'),
      );
    }
    return _DailyPrioritiesSection(
      actions: _dailyActions,
      onActionTap: _handleActionTap,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text('Veriler alınamadı', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_errorMessage ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGETS: CLEAN, MODULAR, AND ACTION-ORIENTED
// ============================================================================

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final riskLevel = summary.overallRiskLevel;
    Color badgeColor = AppColors.primaryNavy;
    
    if (riskLevel == 'Acil' || riskLevel == 'Yüksek risk') {
      badgeColor = AppColors.danger;
    } else if (riskLevel == 'Dikkat' || riskLevel == 'Riskli') {
      badgeColor = AppColors.warning;
    } else if (riskLevel == 'Güvenli') {
      badgeColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İyi Çalışmalar!', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  summary.shouldShowOnboarding 
                    ? 'İlk kayıtlarınızı ekleyerek günlük planınızı oluşturmaya başlayın.'
                    : 'Bugün önceliğinizi tahsilatlar ve nakit yönetimine vermeniz önerilir.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lens, size: 10, color: badgeColor),
                const SizedBox(width: 8),
                Text(
                  'Durum: $riskLevel',
                  style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.onIncome, required this.onCustomer, required this.onProduct});
  final VoidCallback onIncome;
  final VoidCallback onCustomer;
  final VoidCallback onProduct;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_outlined, color: AppColors.primaryNavy, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('SmartKOBİ’ye Hoş Geldiniz', style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Günlük iş planınızı ve akıllı analizleri görebilmek için temel işletme verilerinizi oluşturmanız gerekiyor. Aşağıdaki adımlarla başlayabilirsiniz.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              ElevatedButton.icon(onPressed: onIncome, icon: const Icon(Icons.add), label: const Text('İlk Gelir/Gideri Ekle')),
              OutlinedButton.icon(onPressed: onCustomer, icon: const Icon(Icons.person_add), label: const Text('Müşteri Ekle')),
              OutlinedButton.icon(onPressed: onProduct, icon: const Icon(Icons.inventory_2), label: const Text('Ürün Ekle')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyPrioritiesSection extends StatelessWidget {
  const _DailyPrioritiesSection({required this.actions, required this.onActionTap});
  final List<DashboardDailyAction> actions;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bugün Öncelik Verilecekler', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (actions.isEmpty)
          const SmartCard(child: Text('Bugün için acil bir aksiyon veya öncelik görünmüyor.'))
        else
          ...actions.take(4).map((action) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DailyActionCard(action: action, onTap: () => onActionTap(action.module)),
          )),
      ],
    );
  }
}

class _DailyActionCard extends StatelessWidget {
  const _DailyActionCard({required this.action, required this.onTap});
  final DashboardDailyAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHigh = action.riskLevel == 'high';
    final color = isHigh ? AppColors.danger : AppColors.warning;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(action.icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(action.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.onOpen, required this.onOpenScanner});
  final ValueChanged<String> onOpen;
  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hızlı İşlemler', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _QuickActionBtn('Gelir/Gider', Icons.add_chart, () => onOpen('transactions')),
            _QuickActionBtn('Fiş Tara', Icons.document_scanner, onOpenScanner, isFeatured: true),
            _QuickActionBtn('Müşteri Ekle', Icons.person_add, () => onOpen('customers')),
            _QuickActionBtn('Nakit Kaydı', Icons.waterfall_chart, () => onOpen('cashflow')),
            _QuickActionBtn('Belge Yükle', Icons.upload_file, () => onOpen('documents')),
            _QuickActionBtn('Yapay Zeka', Icons.smart_toy, () => onOpen('advisor')),
          ],
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn(this.label, this.icon, this.onTap, {this.isFeatured = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isFeatured ? AppColors.primaryNavySoft : AppColors.surface,
          border: Border.all(color: isFeatured ? AppColors.primaryNavy.withValues(alpha: 0.3) : AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryNavy, size: 22),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceSummarySection extends StatelessWidget {
  const _FinanceSummarySection({required this.summary, required this.currency});
  final DashboardSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kısa Finans Özeti', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 36) / 4;
            final isMobile = constraints.maxWidth < 600;
            final cardWidth = isMobile ? (constraints.maxWidth - 12) / 2 : width;
            
            return Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                SizedBox(width: cardWidth, child: _MiniStat('Aylık Gelir', currency.format(summary.monthlyIncome), AppColors.success)),
                SizedBox(width: cardWidth, child: _MiniStat('Aylık Gider', currency.format(summary.monthlyExpense), AppColors.danger)),
                SizedBox(width: cardWidth, child: _MiniStat('Net Kâr/Zarar', currency.format(summary.netProfit), summary.netProfit >= 0 ? AppColors.primaryNavy : AppColors.warning)),
                SizedBox(width: cardWidth, child: _MiniStat('Nakit Skoru', '${summary.cashScore}/100', AppColors.primaryNavy)),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Alt Bilgi Satırı
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.insights, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bekleyen tahsilat: ${currency.format(summary.pendingReceivables)} • Yaklaşan ödeme: ${currency.format(summary.upcomingPayments7d)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}

class _WarningSection extends StatelessWidget {
  const _WarningSection({required this.summary, required this.onAction});
  final DashboardSummary summary;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    List<Widget> warnings = [];

    if (summary.overdueReceivables > 0) {
      warnings.add(_WarningItem('Geciken Tahsilat', 'Vadesi geçmiş alacaklarınız var.', AppColors.danger, () => onAction('customers')));
    }
    if (summary.criticalStockCount > 0) {
      warnings.add(_WarningItem('Kritik Stok', '${summary.criticalStockCount} ürün tükenmek üzere.', AppColors.warning, () => onAction('inventory')));
    }
    if (summary.cashScore < 50) {
      warnings.add(_WarningItem('Nakit Riski', 'Nakit skorunuz düşük. Harcamaları izleyin.', AppColors.warning, () => onAction('cashflow')));
    }
    if (summary.profileCompletion < 70) {
      warnings.add(_WarningItem('Eksik Profil', 'İşletme profilinizi tamamlayın.', AppColors.info, () => onAction('profile')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dikkat Gerektirenler', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (warnings.isEmpty)
          const SmartCard(child: Text('Şu anda işletmenizde kritik bir uyarı görünmüyor. Harika gidiyorsunuz!'))
        else
          Column(children: warnings.take(3).toList()),
      ],
    );
  }
}

class _WarningItem extends StatelessWidget {
  const _WarningItem(this.title, this.desc, this.color, this.onTap);
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                    Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartKobiCommentCard extends StatelessWidget {
  const _SmartKobiCommentCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: AppColors.primaryNavy, size: 20),
              const SizedBox(width: 10),
              Text('SmartKOBİ Yorumu', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryNavy)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}
