import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/metric_card.dart';
import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_report_model.dart';
import '../../data/repositories/reports_repository.dart';
import 'report_detail_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    this.initialReportType,
  });

  final String? initialReportType;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _repository = ReportsRepository();
  final _dateFormat = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _errorMessage;
  String? _selectedHintType;
  List<BusinessReportModel> _reports = const [];

  static const _reportCatalog = <_ReportCatalogItem>[
    _ReportCatalogItem(
      type: 'business_health',
      title: 'KOBİ Sağlık Raporu',
      description: 'İşletmenizin genel durumunu tek raporda özetler.',
      icon: Icons.favorite_border,
    ),
    _ReportCatalogItem(
      type: 'financial_summary',
      title: 'Finansal Özet Raporu',
      description: 'Gelir, gider ve net sonuç görünümünü derler.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _ReportCatalogItem(
      type: 'cashflow',
      title: 'Nakit Akışı Raporu',
      description: '30 ve 60 günlük nakit görünümünü özetler.',
      icon: Icons.waterfall_chart_outlined,
    ),
    _ReportCatalogItem(
      type: 'customer_risk',
      title: 'Cari Risk Raporu',
      description: 'Tahsilat risklerini ve öncelik sıralamasını çıkarır.',
      icon: Icons.people_outline,
    ),
    _ReportCatalogItem(
      type: 'inventory_risk',
      title: 'Stok Risk Raporu',
      description: 'Kritik stok, tükenen ürün ve marj risklerini listeler.',
      icon: Icons.inventory_2_outlined,
    ),
    _ReportCatalogItem(
      type: 'support_eligibility',
      title: 'Destek Uygunluk Raporu',
      description: 'Destek başlıkları ve hazırlık seviyesini özetler.',
      icon: Icons.workspace_premium_outlined,
    ),
    _ReportCatalogItem(
      type: 'document_gap',
      title: 'Eksik Belge Raporu',
      description: 'Eksik, süresi geçen ve yaklaşan belgeleri derler.',
      icon: Icons.folder_open_outlined,
    ),
    _ReportCatalogItem(
      type: 'daily_action_plan',
      title: 'Günlük İş Planı Raporu',
      description: 'Günün önceliklerini tek çıktıda toplar.',
      icon: Icons.today_outlined,
    ),
    _ReportCatalogItem(
      type: 'weekly_action_plan',
      title: 'Haftalık İş Planı Raporu',
      description: 'Haftalık operasyon planı ve takip listesini üretir.',
      icon: Icons.date_range_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedHintType = widget.initialReportType;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final reports = await _repository.fetchReports();
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _generateReport(String reportType) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _selectedHintType = reportType;
    });

    try {
      final report = await _repository.generateReport(reportType: reportType);
      final reports = await _repository.fetchReports();
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = reports;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor hazırlandı.')),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportDetailPage(report: report)),
      );
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapor oluşturulamadı. Lütfen verilerinizi kontrol edip tekrar deneyin.'),
        ),
      );
    }
  }

  Future<void> _archiveReport(BusinessReportModel report) async {
    try {
      await _repository.archiveReport(report.id);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _deleteReport(BusinessReportModel report) async {
    try {
      await _repository.deleteReport(report.id);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Raporlar',
      subtitle: 'İşletme verilerinizden yönetim, finans, nakit, stok, destek ve belge raporları oluşturun.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _loading
          ? const Center(child: Text('Rapor hazırlanıyor...'))
          : _errorMessage != null
              ? _ReportsError(message: _errorMessage!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final latest = _reports.isEmpty ? null : _reports.first;
    final readyCount = _reports.where((item) => item.status == 'ready').length;
    final pdfCount = _reports.where((item) => item.hasPdf).length;
    final activeCount = _reports.where((item) => item.status != 'archived').length;

    return ListView(
      children: [
        SmartCard(
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
                        Text('Rapor Merkezi', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'İşletme verilerinizden finans, nakit, cari, stok, destek ve belge raporları oluşturun. Bu çıktılar ön analiz, yönetim özeti ve karar destek amacıyla hazırlanır.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _generateReport(_selectedHintType ?? 'business_health'),
                    icon: const Icon(Icons.add_chart),
                    label: const Text('Yeni Rapor Oluştur'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (latest != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppColors.gold500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Son rapor: ${latest.title} - ${_dateFormat.format(latest.createdAt)}',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailPage(report: latest),
                            ),
                          );
                        },
                        child: const Text('Önizle'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Henüz rapor oluşturulmadı. İlk raporunuzu oluşturarak işletmenizin genel durumunu tek çıktıda görün.'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: MetricCard(
                title: 'Toplam Rapor',
                value: '$activeCount',
                icon: Icons.assessment_outlined,
                color: AppColors.info,
              ),
            ),
            SizedBox(
              width: 220,
              child: MetricCard(
                title: 'Hazır Rapor',
                value: '$readyCount',
                icon: Icons.verified_outlined,
                color: AppColors.gold500,
              ),
            ),
            SizedBox(
              width: 220,
              child: MetricCard(
                title: 'PDF Hazır',
                value: '$pdfCount',
                icon: Icons.picture_as_pdf_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Rapor Türleri',
                subtitle: 'Modül bazlı rapor seçin, önizleyin ve PDF çıktısı alın',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 980;
                  final itemWidth = isWide ? (constraints.maxWidth - 24) / 3 : double.infinity;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _reportCatalog
                        .map(
                          (item) => SizedBox(
                            width: itemWidth,
                            child: _ReportTypeCard(
                              item: item,
                              highlighted: _selectedHintType == item.type,
                              onCreate: () => _generateReport(item.type),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Son Oluşturulan Raporlar',
                subtitle: 'Önizleme, PDF ve arşiv işlemlerini buradan yönetin',
              ),
              const SizedBox(height: 14),
              if (_reports.isEmpty)
                _EmptyReportsState(onCreate: () => _generateReport('business_health'))
              else
                ..._reports.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportHistoryRow(
                      report: report,
                      dateFormat: _dateFormat,
                      onPreview: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(report: report),
                          ),
                        );
                        await _load();
                      },
                      onArchive: () => _archiveReport(report),
                      onDelete: () => _deleteReport(report),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportCatalogItem {
  const _ReportCatalogItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String type;
  final String title;
  final String description;
  final IconData icon;
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({
    required this.item,
    required this.onCreate,
    required this.highlighted,
  });

  final _ReportCatalogItem item;
  final VoidCallback onCreate;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.gold500.withValues(alpha: 0.12) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? AppColors.gold500.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.gold500),
          ),
          const SizedBox(height: 12),
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _ReportHistoryRow extends StatelessWidget {
  const _ReportHistoryRow({
    required this.report,
    required this.dateFormat,
    required this.onPreview,
    required this.onArchive,
    required this.onDelete,
  });

  final BusinessReportModel report;
  final DateFormat dateFormat;
  final VoidCallback onPreview;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
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
                    Text(report.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${report.reportTypeLabel} • ${dateFormat.format(report.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _HistoryStatusPill(label: report.statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.summary ?? 'Rapor özeti bulunamadı.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Önizle'),
              ),
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: Icon(
                  report.hasPdf ? Icons.download_outlined : Icons.picture_as_pdf_outlined,
                ),
                label: Text(report.hasPdf ? 'İndir' : 'PDF'),
              ),
              TextButton.icon(
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Arşivle'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Sil'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryStatusPill extends StatelessWidget {
  const _HistoryStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Henüz rapor oluşturulmadı.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'İlk raporunuzu oluşturarak işletmenizin genel durumunu tek çıktıda görün.',
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_chart),
            label: const Text('İlk Raporu Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SmartCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.warning, size: 32),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
