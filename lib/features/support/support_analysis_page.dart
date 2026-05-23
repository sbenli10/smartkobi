import 'package:flutter/material.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/support_analysis_result_model.dart';
import '../../data/models/support_checklist_item_model.dart';
import '../../data/models/support_opportunity_model.dart';
import '../../data/repositories/business_profile_repository.dart';
import '../../data/repositories/support_analysis_repository.dart';
import '../business_profile/business_profile_page.dart';
import '../documents/documents_page.dart';
import '../reports/reports_page.dart';

class SupportAnalysisPage extends StatefulWidget {
  const SupportAnalysisPage({super.key});

  @override
  State<SupportAnalysisPage> createState() => _SupportAnalysisPageState();
}

class _SupportAnalysisPageState extends State<SupportAnalysisPage> {
  final _repository = SupportAnalysisRepository();
  final _businessProfileRepository = BusinessProfileRepository();

  bool _loading = true;
  bool _runningAnalysis = false;
  String? _errorMessage;
  BusinessProfileModel? _profile;
  SupportAnalysisResultModel? _analysis;
  List<SupportOpportunityModel> _opportunities = const [];
  List<SupportChecklistItemModel> _checklist = const [];

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
      final profile = await _businessProfileRepository.fetchMyBusinessProfile();
      final analysis = await _repository.fetchLatestAnalysis();
      final opportunities = analysis == null
          ? const <SupportOpportunityModel>[]
          : await _repository.fetchOpportunities(analysis.id);
      final checklist = analysis == null
          ? const <SupportChecklistItemModel>[]
          : await _repository.fetchChecklistItems(analysis.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _analysis = analysis;
        _opportunities = opportunities;
        _checklist = checklist;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Destek analizi alinmadi. Lutfen baglantinizi kontrol edin.\n$error';
      });
    }
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _runningAnalysis = true;
      _errorMessage = null;
    });

    try {
      final analysis = await _repository.runSupportAnalysis();
      final opportunities = await _repository.fetchOpportunities(analysis.id);
      final checklist = await _repository.fetchChecklistItems(analysis.id);
      final profile = await _businessProfileRepository.fetchMyBusinessProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _analysis = analysis;
        _opportunities = opportunities;
        _checklist = checklist;
        _profile = profile;
        _runningAnalysis = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destek analizi guncellendi.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _runningAnalysis = false;
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _updateChecklistStatus(
    SupportChecklistItemModel item,
    bool? value,
  ) async {
    final nextStatus = value == true ? 'completed' : 'pending';
    try {
      final updated = await _repository.updateChecklistItemStatus(item.id, nextStatus);
      if (!mounted) {
        return;
      }
      setState(() {
        _checklist = _checklist
            .map((entry) => entry.id == updated.id ? updated : entry)
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _openBusinessProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BusinessProfilePage()),
    );
  }

  void _openDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentsPage()),
    );
  }

  void _openSupportReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportsPage(initialReportType: 'support_eligibility'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Destek Analizi',
      subtitle:
          'Isletme profilinize gore uygun olabilecek destekleri ve eksiklerinizi gorun.',
      actions: [
        IconButton(
          onPressed: _loading || _runningAnalysis ? null : _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _loading
          ? const Center(child: Text('Destek analizi hazirlaniyor...'))
          : _errorMessage != null
              ? _ErrorState(message: _errorMessage!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final profileCompletion = _profile?.profileCompletion ?? 0;
    final profileMissing = _analysis?.needsProfile == true || profileCompletion < 40;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;
        final main = [
          _buildHeroCard(profileMissing),
          const SizedBox(height: 16),
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildScoreGrid(),
          const SizedBox(height: 16),
          _buildAiInsightCard(),
        ];

        final side = [
          _buildOpportunitiesCard(),
          const SizedBox(height: 16),
          _buildChecklistCard(),
          const SizedBox(height: 16),
          _buildInfoNote(),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ListView(children: main)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: ListView(children: side)),
            ],
          );
        }

        return ListView(
          children: [
            ...main,
            const SizedBox(height: 16),
            ...side,
          ],
        );
      },
    );
  }

  Widget _buildHeroCard(bool profileMissing) {
    final analysis = _analysis;
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: AppColors.gold500, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analysis?.statusLabel ?? 'Henüz destek analizi oluşturulmadı.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatusChip(label: analysis?.statusLabel ?? 'Analiz Bekleniyor'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            analysis == null
                ? 'Isletme profilinize gore uygun olabilecek destekleri gormek icin ilk analizi baslatin.'
                : (analysis.summary ?? analysis.scoreLabel),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniStat(
                label: 'Genel Uygunluk Skoru',
                value: analysis == null ? '--' : '${analysis.overallScore}/100',
              ),
              _MiniStat(
                label: 'Profil Tamamlama',
                value: '${_profile?.profileCompletion ?? 0}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runningAnalysis ? null : _runAnalysis,
                  icon: _runningAnalysis
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(_runningAnalysis ? 'Analiz Hazirlaniyor' : 'Analizi Yenile'),
                ),
              ),
              if (profileMissing) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openBusinessProfile,
                    icon: const Icon(Icons.business_center_outlined),
                    label: const Text('Isletme Profilini Tamamla'),
                  ),
                ),
              ] else if ((analysis?.missingDocuments.isNotEmpty ?? false)) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openDocuments,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Eksik Belgeleri Tamamla'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openSupportReport,
              icon: const Icon(Icons.assessment_outlined),
              label: const Text('Destek Uygunluk Raporu Oluştur'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = _profile;
    final profileFields = _analysis?.missingProfileFields ?? const <String>[];
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Profil Durumu',
            subtitle: 'Destek analizi isletme profilindeki bilgilere dayanir',
          ),
          const SizedBox(height: 14),
          if (profile == null)
            _EmptyPanel(
              title: 'Destek analizi icin isletme profilinizi olusturmaniz gerekiyor.',
              description:
                  'Profil olusturuldugunda sektor, NACE ve ihtiyac alanlarina gore on uygunluk analizi yapilabilir.',
              buttonLabel: 'Isletme Profiline Git',
              onPressed: _openBusinessProfile,
            )
          else ...[
            Text(
              profile.businessName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProfilePill(label: 'Profil Tamamlama', value: '%${profile.profileCompletion}'),
                _ProfilePill(label: 'Sektor', value: _orDash(profile.sector)),
                _ProfilePill(label: 'NACE', value: _orDash(profile.naceCode)),
                _ProfilePill(
                  label: 'Operasyon',
                  value: [
                    if (profile.doesManufacture) 'Uretim',
                    if (profile.doesExport) 'Ihracat',
                    if (profile.wantsExport) 'Ihracat Hedefi',
                    if (profile.needsDigitalization) 'Dijitallesme',
                  ].isEmpty
                      ? 'Standart'
                      : [
                          if (profile.doesManufacture) 'Uretim',
                          if (profile.doesExport) 'Ihracat',
                          if (profile.wantsExport) 'Ihracat Hedefi',
                          if (profile.needsDigitalization) 'Dijitallesme',
                        ].join(' • '),
                ),
              ],
            ),
            if (profileFields.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Eksik profil alanlari',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...profileFields
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ))
                  ,
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildScoreGrid() {
    final analysis = _analysis;
    final cards = [
      ('KOSGEB', analysis?.kosgebScore ?? 0, 'Makine, yatirim ve KOBI gelisim basliklari'),
      ('TUBITAK / Ar-Ge', analysis?.tubitakScore ?? 0, 'Ar-Ge, teknoloji ve dijitallesme potansiyeli'),
      ('Ihracat Destekleri', analysis?.exportSupportScore ?? 0, 'Pazar gelistirme ve ihracat hazirligi'),
      ('Belgelendirme', analysis?.certificationSupportScore ?? 0, 'TSE, ISO, CE ve teknik uygunluk'),
      ('Dijitallesme', analysis?.digitalizationSupportScore ?? 0, 'Verimlilik ve dijital altyapi ihtiyaci'),
      ('Finansman / Eximbank', analysis?.financingSupportScore ?? 0, 'Yatirim ve nakit destek potansiyeli'),
    ];

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Destek Skorlari',
            subtitle: 'Her baslikta on uygunluk tablosunu kisa ozetle gorun',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 580 ? 2 : 1;
              final itemWidth = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: itemWidth,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.$1, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 10),
                              Text(
                                '${card.$2}/100',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: _scoreColor(card.$2),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(card.$3, style: Theme.of(context).textTheme.bodyMedium),
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

  Widget _buildOpportunitiesCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Firsatlar',
            subtitle: 'One cikan destek basliklari ve sonraki adimlar',
          ),
          const SizedBox(height: 14),
          if (_opportunities.isEmpty)
            const Text('Henüz destek fırsatı üretilmedi.')
          else
            ..._opportunities.map(
              (item) => Padding(
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
                            child: Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          _StatusChip(label: '${item.eligibilityScore}/100'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description ?? item.supportTypeLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (item.missingRequirements.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Eksikler', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        ...item.missingRequirements.map((entry) => _BulletText(entry)),
                      ],
                      if (item.nextSteps.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Sonraki Adimlar', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        ...item.nextSteps.map((entry) => _BulletText(entry)),
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

  Widget _buildChecklistCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Basvuru Hazirlik Checklisti',
            subtitle: 'Profil, belge ve basvuru adimlarini tek listede takip edin',
          ),
          const SizedBox(height: 14),
          if (_checklist.isEmpty)
            const Text('Hazırlık checklisti henüz oluşmadı.')
          else
            ..._checklist.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CheckboxListTile(
                  value: item.isCompleted,
                  onChanged: (value) => _updateChecklistStatus(item, value),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.categoryLabel} • ${item.priorityLabel}${item.description == null ? '' : '\n${item.description!}'}',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard() {
    final analysis = _analysis;
    final text = analysis == null
        ? 'Profil ve analiz verisi olustugunda SmartKOBI hangi desteklerde on potansiyel oldugunu daha net gosterir.'
        : analysis.needsProfile
            ? 'Profilinize gore destek analizi icin bazi temel bilgiler eksik. Sektor, NACE kodu, ciro ve ihtiyac alanlarini tamamlamaniz onerilir.'
            : 'Profilinize gore ${_topInsight(analysis)} tarafinda on potansiyel gorunuyor. Analizin netlesmesi icin eksik profil alanlarini ve belge listesini tamamlamaniz onerilir.';

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBI AI Yorumu',
            subtitle: 'Bu analiz on bilgilendirme niteligindedir',
          ),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return SmartCard(
      child: Text(
        'Bu analiz on bilgilendirme niteligindedir. Nihai basvuru sartlari ilgili kurumlarin guncel mevzuatina gore degerlendirilmelidir.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  String _topInsight(SupportAnalysisResultModel analysis) {
    final scores = <String, int>{
      'KOSGEB': analysis.kosgebScore,
      'TUBITAK / Ar-Ge': analysis.tubitakScore,
      'Ihracat destekleri': analysis.exportSupportScore,
      'belgelendirme': analysis.certificationSupportScore,
      'dijitallesme': analysis.digitalizationSupportScore,
      'finansman': analysis.financingSupportScore,
    };
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _orDash(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Belirtilmedi' : text;
  }

  Color _scoreColor(int score) {
    if (score >= 75) {
      return AppColors.success;
    }
    if (score >= 45) {
      return AppColors.gold500;
    }
    return AppColors.warning;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
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

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.gold400,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.business_center_outlined),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
                'Destek analizi alinamadi',
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
