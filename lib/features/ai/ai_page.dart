import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_context_summary_model.dart';
import '../../data/repositories/ai_advisor_repository.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final AiAdvisorRepository _repository = AiAdvisorRepository();
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);

  BusinessContextSummaryModel _summary = BusinessContextSummaryModel.empty();
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _repository.buildContextSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
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

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'AI Analizler',
      subtitle: 'İşletmenizin özet risk ve fırsat görünümünü tek ekranda inceleyin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadSummary,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _loading
          ? const Center(child: Text('SmartKOBİ analiz ediyor...'))
          : _errorMessage != null
              ? Center(
                  child: SmartCard(
                    child: Text(_errorMessage!),
                  ),
                )
              : ListView(
                  children: [
                    SmartCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Genel Özet',
                            subtitle: 'Finans, cari, stok ve nakit verilerinin birleşik görünümü',
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _summary.summaryText ??
                                'Yeterli veri bulunamadı. Gelir-gider, cari, stok ve nakit kayıtları eklendikçe öneriler güçlenir.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _SummaryMetric(
                                label: 'Net Kâr',
                                value: _currency.format(_summary.netProfit),
                                color: _summary.netProfit >= 0
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                              _SummaryMetric(
                                label: 'Nakit Skoru',
                                value: '${_summary.cashScore}/100',
                                color: _summary.cashScore >= 70
                                    ? AppColors.success
                                    : _summary.cashScore >= 50
                                        ? AppColors.warning
                                        : AppColors.danger,
                              ),
                              _SummaryMetric(
                                label: 'Geciken Tahsilat',
                                value: _currency.format(_summary.overdueReceivables),
                                color: AppColors.warning,
                              ),
                              _SummaryMetric(
                                label: 'Kritik Stok',
                                value: _summary.criticalStockCount.toString(),
                                color: AppColors.info,
                              ),
                            ],
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
                            title: 'Öne Çıkan Riskler',
                            subtitle: 'Danışman bu riskleri cevaplarında önceliklendirir.',
                          ),
                          const SizedBox(height: 14),
                          if (_summary.topRisks.isEmpty)
                            const Text('Şu an belirgin bir kırmızı bayrak görünmüyor.')
                          else
                            ..._summary.topRisks.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.warning_amber_outlined,
                                        color: AppColors.warning,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(item)),
                                  ],
                                ),
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
                            title: 'Fırsatlar',
                            subtitle: 'Kısa vadede iyileştirme sağlayabilecek alanlar',
                          ),
                          const SizedBox(height: 14),
                          if (_summary.topOpportunities.isEmpty)
                            const Text('Henüz fırsat önerisi oluşturacak kadar veri bulunamadı.')
                          else
                            ..._summary.topOpportunities.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: AppColors.gold500,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(item)),
                                  ],
                                ),
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
