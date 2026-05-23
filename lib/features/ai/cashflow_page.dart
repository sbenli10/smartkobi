import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/cashflow_entry_model.dart';
import '../../data/models/cashflow_projection_model.dart';
import '../../data/models/cashflow_scenario_model.dart';
import '../../data/models/cashflow_snapshot_model.dart';
import '../../data/repositories/cashflow_repository.dart';
import '../cashflow/cashflow_calculations.dart';

enum CashflowFilter {
  all,
  inflows,
  outflows,
  overdue,
  nextSevenDays,
  nextThirtyDays,
}

class CashflowPage extends StatefulWidget {
  const CashflowPage({super.key});

  @override
  State<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends State<CashflowPage> {
  final CashflowRepository _repository = CashflowRepository();
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);

  List<CashflowEntryModel> _entries = [];
  List<CashflowScenarioModel> _scenarios = [];
  CashflowProjectionModel? _projection;
  CashflowFilter _filter = CashflowFilter.all;
  CashflowScenarioAnalysis? _lastScenarioAnalysis;
  bool _loading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final entries = await _repository.fetchCashflowEntries();
      final scenarios = await _repository.fetchCashflowScenarios();
      final projection = await _repository.buildProjection();

      final snapshot = CashflowSnapshotModel(
        id: '',
        userId: '',
        businessId: null,
        snapshotDate: DateTime.now(),
        openingBalance: projection.openingBalance,
        expectedInflow30d: projection.expectedInflow30d,
        expectedOutflow30d: projection.expectedOutflow30d,
        netCash30d: projection.netCash30d,
        expectedInflow60d: projection.expectedInflow60d,
        expectedOutflow60d: projection.expectedOutflow60d,
        netCash60d: projection.netCash60d,
        cashScore: projection.cashScore,
        riskLevel: projection.riskLevel,
        aiSummary: projection.aiSummary,
        createdAt: DateTime.now(),
      );
      await _repository.saveSnapshot(snapshot);

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _scenarios = scenarios;
        _projection = projection;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<CashflowEntryModel> get _filteredEntries {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = _entries.where((entry) {
      switch (_filter) {
        case CashflowFilter.inflows:
          return entry.isInflow;
        case CashflowFilter.outflows:
          return entry.isOutflow;
        case CashflowFilter.overdue:
          return entry.isOverdue;
        case CashflowFilter.nextSevenDays:
          return !entry.expectedDate.isBefore(today) &&
              !entry.expectedDate.isAfter(today.add(const Duration(days: 7)));
        case CashflowFilter.nextThirtyDays:
          return !entry.expectedDate.isBefore(today) &&
              !entry.expectedDate.isAfter(today.add(const Duration(days: 30)));
        case CashflowFilter.all:
          return true;
      }
    }).toList();

    filtered.sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
    return filtered;
  }

  Future<void> _openAddEntrySheet() async {
    final entry = await showModalBottomSheet<CashflowEntryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCashflowEntrySheet(),
    );

    if (entry == null) {
      return;
    }

    try {
      await _repository.addCashflowEntry(entry);
      await _loadData();
      if (!mounted) {
        return;
      }
      _showSnackBar('Nakit kaydı başarıyla kaydedildi.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _analyzeScenario(_ExpenseScenarioInput input) async {
    final projection = _projection;
    if (projection == null) {
      return;
    }

    final analysis = analyzeExpenseScenario(
      title: input.title,
      plannedExpenseAmount: input.amount,
      plannedExpenseDate: input.date,
      openingBalance: projection.openingBalance,
      projection: projection,
    );
    final resultSummary = input.description.isEmpty
        ? analysis.resultSummary
        : '${analysis.resultSummary} Not: ${input.description}';

    try {
      await _repository.addCashflowScenario(
        CashflowScenarioModel(
          id: '',
          userId: '',
          businessId: null,
          title: input.title,
          scenarioType: 'expense_check',
          amount: input.amount,
          scenarioDate: input.date,
          riskLevel: analysis.riskLevel,
          resultSummary: resultSummary,
          recommendation: analysis.recommendation,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final scenarios = await _repository.fetchCashflowScenarios();
      if (!mounted) {
        return;
      }

      setState(() {
        _lastScenarioAnalysis = analysis;
        _scenarios = scenarios;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projection = _projection;

    return PageScaffold(
      title: 'Nakit AI',
      subtitle: '30/60 günlük nakit akışınızı ve sıkışıklık riskini analiz edin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadData,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cashflowEntryFab',
        onPressed: _openAddEntrySheet,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Nakit Kaydı'),
      ),
      child: _loading
          ? const Center(child: Text('Nakit akışı analiz ediliyor...'))
          : _errorMessage != null
              ? _CashflowErrorState(
                  message: 'Nakit akışı verileri alınamadı. Lütfen bağlantınızı kontrol edin.',
                  details: _errorMessage,
                  onRetry: _loadData,
                )
              : projection == null
                  ? _CashflowErrorState(
                      message:
                          'Nakit akışı verileri alınamadı. Lütfen bağlantınızı kontrol edin.',
                      onRetry: _loadData,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _CashflowHeroCard(
                            projection: projection,
                            lastUpdated: _lastUpdated,
                          ),
                          const SizedBox(height: 16),
                          _ProjectionGrid(
                            title: '30 Günlük Tahmin',
                            subtitle: 'Kısa vadeli tahsilat, ödeme ve sıkışıklık görünümü',
                            metrics: [
                              _ProjectionMetric(
                                label: 'Beklenen Tahsilat',
                                value: _currency.format(projection.expectedInflow30d),
                                color: AppColors.success,
                                icon: Icons.south_west_outlined,
                              ),
                              _ProjectionMetric(
                                label: 'Beklenen Ödeme',
                                value: _currency.format(projection.expectedOutflow30d),
                                color: AppColors.danger,
                                icon: Icons.north_east_outlined,
                              ),
                              _ProjectionMetric(
                                label: 'Tahmini Net Nakit',
                                value: _currency.format(projection.netCash30d),
                                color: projection.netCash30d >= 0
                                    ? AppColors.gold500
                                    : AppColors.warning,
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              _ProjectionMetric(
                                label: 'Geciken Tahsilat',
                                value: _currency.format(projection.overdueInflowTotal),
                                color: AppColors.warning,
                                icon: Icons.warning_amber_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ProjectionGrid(
                            title: '60 Günlük Tahmin',
                            subtitle: 'Orta vadeli nakit dayanıklılığı ve ödeme yoğunluğu',
                            metrics: [
                              _ProjectionMetric(
                                label: 'Beklenen Tahsilat',
                                value: _currency.format(projection.expectedInflow60d),
                                color: AppColors.success,
                                icon: Icons.trending_up,
                              ),
                              _ProjectionMetric(
                                label: 'Beklenen Ödeme',
                                value: _currency.format(projection.expectedOutflow60d),
                                color: AppColors.danger,
                                icon: Icons.trending_down,
                              ),
                              _ProjectionMetric(
                                label: 'Tahmini Net Nakit',
                                value: _currency.format(projection.netCash60d),
                                color: projection.netCash60d >= 0
                                    ? AppColors.gold500
                                    : AppColors.warning,
                                icon: Icons.analytics_outlined,
                              ),
                              _ProjectionMetric(
                                label: 'Yaklaşan Ödeme Yoğunluğu',
                                value: _currency.format(projection.upcomingOutflowTotal),
                                color: AppColors.info,
                                icon: Icons.schedule_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ProjectionChartCard(
                            projection: projection,
                          ),
                          const SizedBox(height: 16),
                          _UpcomingEntriesSection(
                            entries: _filteredEntries,
                            filter: _filter,
                            currency: _currency,
                            onFilterChanged: (filter) {
                              setState(() => _filter = filter);
                            },
                            onCreate: _openAddEntrySheet,
                          ),
                          const SizedBox(height: 16),
                          _ExpenseScenarioCard(
                            projection: projection,
                            lastAnalysis: _lastScenarioAnalysis,
                            currency: _currency,
                            onAnalyze: _analyzeScenario,
                          ),
                          const SizedBox(height: 16),
                          _SuggestionsCard(suggestions: projection.suggestions),
                          if (_scenarios.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _ScenarioHistoryCard(
                              scenarios: _scenarios,
                              currency: _currency,
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _CashflowHeroCard extends StatelessWidget {
  const _CashflowHeroCard({
    required this.projection,
    required this.lastUpdated,
  });

  final CashflowProjectionModel projection;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(projection.riskLevel);

    return SmartCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              riskColor.withValues(alpha: 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nakit Sağlık Özeti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.gold400,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  projection.aiSummary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Risk durumu: ${_riskLabel(projection.riskLevel)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (lastUpdated != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Son güncelleme: ${DateFormat('dd.MM.yyyy HH:mm').format(lastUpdated!)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
                if (projection.criticalDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Kritik tarih: ${DateFormat('dd.MM.yyyy').format(projection.criticalDate!)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                ],
              ],
            );

            final scoreCard = Container(
              width: compact ? double.infinity : 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy950,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: riskColor.withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nakit Skoru',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${projection.cashScore}/100',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: riskColor,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _RiskPill(level: projection.riskLevel),
                ],
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 16),
                  scoreCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: content),
                const SizedBox(width: 16),
                scoreCard,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProjectionGrid extends StatelessWidget {
  const _ProjectionGrid({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final List<_ProjectionMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(metric.icon, color: metric.color),
                              const SizedBox(height: 10),
                              Text(
                                metric.label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                metric.value,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: metric.color,
                                    ),
                              ),
                            ],
                          ),
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

class _ProjectionChartCard extends StatelessWidget {
  const _ProjectionChartCard({
    required this.projection,
  });

  final CashflowProjectionModel projection;

  @override
  Widget build(BuildContext context) {
    final points = [
      FlSpot(0, projection.openingBalance),
      FlSpot(30, projection.netCash30d),
      FlSpot(60, projection.netCash60d),
    ];

    final values = [
      projection.openingBalance,
      projection.netCash30d,
      projection.netCash60d,
    ];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final chartMinY = minY > 0 ? 0.0 : minY * 1.15;
    final chartMaxY = maxY <= 0 ? 1.0 : maxY * 1.15;

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Nakit Eğrisi',
            subtitle: 'Açılış bakiyesi ile 30 ve 60 günlük tahmini net nakit görünümü',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 60,
                minY: chartMinY,
                maxY: chartMaxY,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY == minY ? 1 : ((maxY - minY).abs() / 4).clamp(1, 999999),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 30,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value == 0 ? 'Bugün' : '${value.toInt()} Gün',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: AppColors.gold500,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.gold500,
                        strokeWidth: 2,
                        strokeColor: AppColors.navy950,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.gold500.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEntriesSection extends StatelessWidget {
  const _UpcomingEntriesSection({
    required this.entries,
    required this.filter,
    required this.currency,
    required this.onFilterChanged,
    required this.onCreate,
  });

  final List<CashflowEntryModel> entries;
  final CashflowFilter filter;
  final NumberFormat currency;
  final ValueChanged<CashflowFilter> onFilterChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Yaklaşan Nakit Kayıtları',
            subtitle: 'Tahsilatları, ödemeleri ve gecikmeleri aynı ekrandan takip edin.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'Tümü',
                selected: filter == CashflowFilter.all,
                onTap: () => onFilterChanged(CashflowFilter.all),
              ),
              _FilterChipButton(
                label: 'Tahsilatlar',
                selected: filter == CashflowFilter.inflows,
                onTap: () => onFilterChanged(CashflowFilter.inflows),
              ),
              _FilterChipButton(
                label: 'Ödemeler',
                selected: filter == CashflowFilter.outflows,
                onTap: () => onFilterChanged(CashflowFilter.outflows),
              ),
              _FilterChipButton(
                label: 'Gecikenler',
                selected: filter == CashflowFilter.overdue,
                onTap: () => onFilterChanged(CashflowFilter.overdue),
              ),
              _FilterChipButton(
                label: '7 Gün',
                selected: filter == CashflowFilter.nextSevenDays,
                onTap: () => onFilterChanged(CashflowFilter.nextSevenDays),
              ),
              _FilterChipButton(
                label: '30 Gün',
                selected: filter == CashflowFilter.nextThirtyDays,
                onTap: () => onFilterChanged(CashflowFilter.nextThirtyDays),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _EmptyCashflowState(onCreate: onCreate)
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CashflowEntryCard(
                  entry: entry,
                  currency: currency,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CashflowEntryCard extends StatelessWidget {
  const _CashflowEntryCard({
    required this.entry,
    required this.currency,
  });

  final CashflowEntryModel entry;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entryColor = entry.isInflow ? AppColors.success : AppColors.danger;
    final statusColor = _statusColor(entry.status, entry.isOverdue);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  entry.isInflow ? Icons.call_received : Icons.call_made,
                  color: entryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _LabelPill(
                          label: entry.isInflow ? 'Tahsilat' : 'Ödeme',
                          color: entryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.category?.isNotEmpty == true
                          ? entry.category!
                          : 'Kategori belirtilmedi',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoBadge(
                icon: Icons.payments_outlined,
                label: currency.format(entry.amount),
              ),
              _InfoBadge(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd.MM.yyyy').format(entry.expectedDate),
              ),
              _InfoBadge(
                icon: Icons.flag_outlined,
                label: _statusLabel(entry.status, entry.isOverdue),
                color: statusColor,
              ),
              _InfoBadge(
                icon: Icons.shield_outlined,
                label: _confidenceLabel(entry.confidenceLevel),
              ),
            ],
          ),
          if ((entry.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.description!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseScenarioCard extends StatefulWidget {
  const _ExpenseScenarioCard({
    required this.projection,
    required this.lastAnalysis,
    required this.currency,
    required this.onAnalyze,
  });

  final CashflowProjectionModel projection;
  final CashflowScenarioAnalysis? lastAnalysis;
  final NumberFormat currency;
  final Future<void> Function(_ExpenseScenarioInput input) onAnalyze;

  @override
  State<_ExpenseScenarioCard> createState() => _ExpenseScenarioCardState();
}

class _ExpenseScenarioCardState extends State<_ExpenseScenarioCard> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _plannedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.lastAnalysis;

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Bu Harcamayı Yapabilir miyim?',
            subtitle: 'Yeni bir giderin 30 günlük nakit görünümüne etkisini anında değerlendirin.',
          ),
          const SizedBox(height: 14),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harcama başlığı zorunlu';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Harcama başlığı',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      return 'Tutar 0’dan büyük olmalı';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tutar',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.gold500,
                  ),
                  title: const Text('Harcama tarihi'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(_plannedDate)),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analiz Et'),
                  ),
                ),
              ],
            ),
          ),
          if (analysis != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RiskPill(level: analysis.riskLevel),
                      const SizedBox(width: 10),
                      Text(
                        widget.currency.format(analysis.amount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    analysis.resultSummary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Yeni skor: ${analysis.resultingCashScore}/100 · 30 günlük net nakit: ${widget.currency.format(analysis.resultingNetCash30d)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _plannedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onAnalyze(
      _ExpenseScenarioInput(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim().replaceAll(',', '.')),
        date: _plannedDate,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ AI Önerileri',
            subtitle: 'Kural bazlı nakit akışı aksiyon önerileri',
          ),
          const SizedBox(height: 14),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: AppColors.gold500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioHistoryCard extends StatelessWidget {
  const _ScenarioHistoryCard({
    required this.scenarios,
    required this.currency,
  });

  final List<CashflowScenarioModel> scenarios;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Son Senaryo Analizleri',
            subtitle: 'Kaydedilen harcama ve nakit etkisi değerlendirmeleri',
          ),
          const SizedBox(height: 14),
          ...scenarios.take(3).map(
            (scenario) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scenario.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _RiskPill(level: scenario.riskLevel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(scenario.amount),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd.MM.yyyy').format(scenario.scenarioDate),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    if ((scenario.resultSummary ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        scenario.resultSummary!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCashflowEntrySheet extends StatefulWidget {
  const _AddCashflowEntrySheet();

  @override
  State<_AddCashflowEntrySheet> createState() => _AddCashflowEntrySheetState();
}

class _AddCashflowEntrySheetState extends State<_AddCashflowEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _entryType = 'inflow';
  String _status = 'expected';
  String _confidenceLevel = 'medium';
  String? _recurrence = 'none';
  DateTime _expectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.navy900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Yeni Nakit Kaydı',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Beklenen tahsilat veya ödeme kaydı oluşturarak tahmini güçlendirin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _entryType,
                    decoration: const InputDecoration(
                      labelText: 'Tür',
                      prefixIcon: Icon(Icons.swap_horiz_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'inflow', child: Text('Tahsilat')),
                      DropdownMenuItem(value: 'outflow', child: Text('Ödeme')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _entryType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Başlık zorunlu';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (amount == null || amount < 0) {
                        return 'Tutar negatif olamaz';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tutar',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.gold500,
                    ),
                    title: const Text('Beklenen tarih'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_expectedDate)),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expected', child: Text('Beklenen')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Kesinleşmiş')),
                      DropdownMenuItem(value: 'paid', child: Text('Ödendi')),
                      DropdownMenuItem(value: 'overdue', child: Text('Gecikti')),
                      DropdownMenuItem(value: 'cancelled', child: Text('İptal')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _confidenceLevel,
                    decoration: const InputDecoration(
                      labelText: 'Güven seviyesi',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Düşük')),
                      DropdownMenuItem(value: 'medium', child: Text('Orta')),
                      DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _confidenceLevel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _recurrence,
                    decoration: const InputDecoration(
                      labelText: 'Tekrar',
                      prefixIcon: Icon(Icons.repeat_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Yok')),
                      DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                      DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                      DropdownMenuItem(value: 'quarterly', child: Text('Üç aylık')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                    ],
                    onChanged: (value) {
                      setState(() => _recurrence = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _expectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    Navigator.of(context).pop(
      CashflowEntryModel(
        id: '',
        userId: '',
        businessId: null,
        sourceType: 'manual',
        sourceId: null,
        entryType: _entryType,
        title: _titleController.text.trim(),
        category:
            _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        amount: double.parse(_amountController.text.trim().replaceAll(',', '.')),
        expectedDate: _expectedDate,
        status: _status,
        recurrence: _recurrence == 'none' ? null : _recurrence,
        confidenceLevel: _confidenceLevel,
        description:
            _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _EmptyCashflowState extends StatelessWidget {
  const _EmptyCashflowState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy950.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 44,
            color: AppColors.gold500,
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz nakit akışı kaydı yok.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Beklenen tahsilat ve ödemelerinizi ekleyerek 30/60 günlük nakit tahminini başlatın.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('İlk Nakit Kaydını Ekle'),
          ),
        ],
      ),
    );
  }
}

class _CashflowErrorState extends StatelessWidget {
  const _CashflowErrorState({
    required this.message,
    required this.onRetry,
    this.details,
  });

  final String message;
  final String? details;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SmartCard(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (details != null && details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  details!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold500 : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.navy950 : Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.gold500),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color ?? Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return _LabelPill(
      label: _riskLabel(level),
      color: _riskColor(level),
    );
  }
}

class _ProjectionMetric {
  const _ProjectionMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _ExpenseScenarioInput {
  const _ExpenseScenarioInput({
    required this.title,
    required this.amount,
    required this.date,
    required this.description,
  });

  final String title;
  final double amount;
  final DateTime date;
  final String description;
}

String _riskLabel(String level) {
  switch (level) {
    case 'critical':
      return 'Kritik';
    case 'high':
      return 'Riskli';
    case 'medium':
      return 'Dikkat';
    default:
      return 'Güvenli';
  }
}

Color _riskColor(String level) {
  switch (level) {
    case 'critical':
      return AppColors.danger;
    case 'high':
      return AppColors.warning;
    case 'medium':
      return AppColors.info;
    default:
      return AppColors.success;
  }
}

String _statusLabel(String status, bool isOverdue) {
  if (isOverdue) {
    return 'Gecikmiş';
  }

  switch (status) {
    case 'confirmed':
      return 'Kesinleşmiş';
    case 'paid':
      return 'Ödendi';
    case 'cancelled':
      return 'İptal';
    case 'overdue':
      return 'Gecikmiş';
    default:
      return 'Beklenen';
  }
}

Color _statusColor(String status, bool isOverdue) {
  if (isOverdue) {
    return AppColors.warning;
  }

  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'cancelled':
      return AppColors.textSecondary;
    case 'confirmed':
      return AppColors.info;
    case 'overdue':
      return AppColors.warning;
    default:
      return AppColors.gold500;
  }
}

String _confidenceLabel(String level) {
  switch (level) {
    case 'high':
      return 'Yüksek güven';
    case 'low':
      return 'Düşük güven';
    default:
      return 'Orta güven';
  }
}
