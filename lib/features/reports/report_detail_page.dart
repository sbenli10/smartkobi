import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/metric_card.dart';
import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_report_model.dart';
import '../../data/models/report_section_model.dart';
import '../../data/repositories/reports_repository.dart';
import 'report_download_helper.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.report,
  });

  final BusinessReportModel report;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _repository = ReportsRepository();
  final _dateFormat = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  bool _exporting = false;
  String? _errorMessage;
  late BusinessReportModel _report;
  List<ReportSectionModel> _sections = const [];

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final report = await _repository.getReportById(_report.id);
      final sections = await _repository.fetchReportSections(_report.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report ?? _report;
        _sections = sections;
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

  Future<void> _exportPdf() async {
    setState(() {
      _exporting = true;
    });
    try {
      final updated = await _repository.exportReportToPdf(_report.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _report = updated;
        _exporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF raporu hazırlandı.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _exporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF oluşturulamadı. Lütfen tekrar deneyin.')),
      );
    }
  }

  Future<void> _downloadPdf() async {
    if (!_report.hasPdf || (_report.pdfFilePath ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce PDF oluşturmanız gerekiyor.')),
      );
      return;
    }
    try {
      final url = await _repository.createPdfDownloadUrl(_report.pdfFilePath!);
      if (kIsWeb) {
        openReportUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF bağlantısı hazır. Bu platformda otomatik indirme sınırlı olabilir.'),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF bağlantısı hazırlanamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: _report.title,
      subtitle: 'Rapor özeti, bölümler ve PDF çıktısı burada yer alır.',
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
              ? _ReportError(message: _errorMessage!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final metrics = _parseMetricCards(_report.reportData['metrikler']);
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
                        Text(
                          _report.reportTypeLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _report.summary ??
                              'Bu rapor ön analiz ve karar destek amacıyla hazırlanmıştır.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _StatusPill(label: _report.statusLabel),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MiniInfo(
                    label: 'Dönem',
                    value: _report.formattedPeriod,
                  ),
                  _MiniInfo(
                    label: 'Tarih',
                    value: _dateFormat.format(_report.generatedAt ?? _report.createdAt),
                  ),
                  _MiniInfo(
                    label: 'PDF',
                    value: _report.hasPdf ? 'Hazır' : 'Henüz yok',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _exporting ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(_report.hasPdf ? 'PDF Yenile' : 'PDF Oluştur'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _report.hasPdf ? _downloadPdf : null,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('PDF İndir'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics,
          ),
        ],
        const SizedBox(height: 16),
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Bölümler',
                subtitle: 'Raporun ana anlatısı ve modül bazlı değerlendirmeleri',
              ),
              const SizedBox(height: 12),
              if (_sections.isEmpty)
                const Text('Rapor bölümü bulunamadı.')
              else
                ..._sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SectionCard(section: section),
                  ),
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
                title: 'Riskler ve Aksiyonlar',
                subtitle: 'Öne çıkan riskler, fırsatlar ve önerilen sonraki adımlar',
              ),
              const SizedBox(height: 12),
              _BulletBlock(
                title: 'Riskler',
                items: _report.risks,
                emptyText: 'Belirgin risk görünmüyor.',
              ),
              const SizedBox(height: 12),
              _BulletBlock(
                title: 'Fırsatlar',
                items: _report.opportunities,
                emptyText: 'Belirgin fırsat görünmüyor.',
              ),
              const SizedBox(height: 12),
              _BulletBlock(
                title: 'Önerilen Aksiyonlar',
                items: _report.recommendedActions,
                emptyText: 'Aksiyon listesi bulunamadı.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _parseMetricCards(dynamic raw) {
    if (raw is! Map) {
      return const [];
    }
    final entries = raw.entries.take(6).toList();
    return entries
        .map(
          (entry) => SizedBox(
            width: 220,
            child: MetricCard(
              title: _metricLabel(entry.key.toString()),
              value: _metricValue(entry.value),
              icon: _metricIcon(entry.key.toString()),
              color: AppColors.gold500,
            ),
          ),
        )
        .toList();
  }

  String _metricLabel(String key) {
    switch (key) {
      case 'aylik_gelir':
        return 'Aylık Gelir';
      case 'aylik_gider':
        return 'Aylık Gider';
      case 'net_kar_zarar':
        return 'Net Kâr / Zarar';
      case 'bekleyen_tahsilat':
        return 'Bekleyen Tahsilatlar';
      case 'vadesi_gecmis_tahsilat':
        return 'Vadesi Geçmiş Tahsilatlar';
      case 'nakit_skoru':
        return 'Nakit Skoru';
      case 'net_nakit_30_gun':
        return '30 Günlük Net Nakit';
      case 'kritik_stok_sayisi':
        return 'Kritik Stok';
      case 'stokta_olmayan_sayisi':
        return 'Stokta Olmayan';
      case 'eksik_belge_sayisi':
        return 'Eksik Belge';
      case 'destek_skoru':
        return 'Destek Skoru';
      case 'profil_tamamlama':
        return 'Profil Tamamlama';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  String _metricValue(dynamic value) {
    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value?.toString() ?? '-';
  }

  IconData _metricIcon(String key) {
    switch (key) {
      case 'aylik_gelir':
        return Icons.trending_up;
      case 'aylik_gider':
        return Icons.trending_down;
      case 'bekleyen_tahsilat':
        return Icons.request_quote_outlined;
      case 'nakit_skoru':
        return Icons.waterfall_chart_outlined;
      case 'kritik_stok_sayisi':
        return Icons.inventory_2_outlined;
      case 'eksik_belge_sayisi':
        return Icons.folder_open_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final ReportSectionModel section;

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
          Text(section.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(section.content ?? 'İçerik bulunamadı.'),
        ],
      ),
    );
  }
}

class _BulletBlock extends StatelessWidget {
  const _BulletBlock({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(emptyText)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8, color: AppColors.gold500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({
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
