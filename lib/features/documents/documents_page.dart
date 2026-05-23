import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/metric_card.dart';
import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_document_model.dart';
import '../../data/models/document_requirement_model.dart';
import '../../data/repositories/documents_repository.dart';
import '../reports/reports_page.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _repository = DocumentsRepository();
  final _dateFormat = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _errorMessage;
  List<BusinessDocumentModel> _documents = const [];
  List<DocumentRequirementModel> _requirements = const [];
  DocumentSummary? _summary;
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';

  static const List<String> _filters = [
    'Tümü',
    'Şirket Belgeleri',
    'Finansal Belgeler',
    'Destek Evrakları',
    'Sertifikalar',
    'İhracat Belgeleri',
    'Teknik Dokümanlar',
    'Süresi Geçen',
    'Eksik Belgeler',
  ];

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
      final documents = await _repository.fetchDocuments();
      final requirements = await _repository.fetchRequirements();
      final summary = await _repository.buildDocumentSummary();

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _requirements = requirements;
        _summary = summary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage =
            'Belgeler alınamadı. Lütfen bağlantınızı kontrol edin.\n$error';
      });
    }
  }

  Future<void> _deleteDocument(BusinessDocumentModel document) async {
    try {
      await _repository.deleteDocument(document.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge silindi.')),
      );
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

  Future<void> _showUploadSheet({DocumentRequirementModel? requirement}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DocumentUploadSheet(
          initialRequirement: requirement,
          onSubmit: ({
            required String title,
            required String documentType,
            required String category,
            required Uint8List fileBytes,
            required String fileName,
            required String mimeType,
            DateTime? issueDate,
            DateTime? expiryDate,
            String? issuer,
            String? referenceNumber,
            String? notes,
            List<String> tags = const [],
          }) async {
            final uploaded = await _repository.uploadDocumentFile(
              title: title,
              documentType: documentType,
              category: category,
              fileBytes: fileBytes,
              fileName: fileName,
              mimeType: mimeType,
              issueDate: issueDate,
              expiryDate: expiryDate,
              issuer: issuer,
              referenceNumber: referenceNumber,
              notes: notes,
              tags: tags,
            );

            if (requirement != null && requirement.id.isNotEmpty) {
              await _repository.linkRequirementToDocument(
                requirementId: requirement.id,
                documentId: uploaded.id,
              );
            }
          },
        );
      },
    );

    if (!mounted) {
      return;
    }
    await _load();
  }

  Future<void> _markRequirementCompleted(DocumentRequirementModel requirement) async {
    try {
      await _repository.updateRequirement(
        requirement.copyWith(status: 'completed'),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge ihtiyacı güncellendi.')),
      );
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

  void _openDocumentGapReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportsPage(initialReportType: 'document_gap'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Belgelerim',
      subtitle:
          'İşletme belgelerinizi, başvuru evraklarınızı ve sertifikalarınızı tek yerden yönetin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _loading
          ? const Center(child: Text('Belgeler yükleniyor...'))
          : _errorMessage != null
              ? _DocumentsError(message: _errorMessage!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final summary = _summary ??
        const DocumentSummary(
          totalDocuments: 0,
          missingRequirements: 0,
          expiredDocuments: 0,
          willExpireDocuments: 0,
          uploadedDocuments: 0,
          highPriorityMissing: 0,
          supportReadyScore: 0,
          insight: 'Belgelerinizi yükledikçe hazırlık görünümü güçlenir.',
        );
    final filteredDocuments = _filteredDocuments();
    final filteredRequirements = _filteredRequirements();
    final hasData = _documents.isNotEmpty || _requirements.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1160;
        final mainChildren = [
          _buildHeroCard(summary),
          _buildReportShortcut(),
          const SizedBox(height: 16),
          _buildMetricGrid(summary),
          const SizedBox(height: 16),
          _buildInsightCard(summary),
          const SizedBox(height: 16),
          _buildFiltersCard(),
          const SizedBox(height: 16),
          hasData
              ? _buildDocumentsSection(filteredDocuments)
              : _EmptyDocumentsState(onUpload: _showUploadSheet),
        ];

        final sideChildren = [
          _buildRequirementsSection(filteredRequirements),
          const SizedBox(height: 16),
          _buildInfoNote(),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ListView(children: mainChildren)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: ListView(children: sideChildren)),
            ],
          );
        }

        return ListView(
          children: [
            ...mainChildren,
            const SizedBox(height: 16),
            ...sideChildren,
          ],
        );
      },
    );
  }

  Widget _buildHeroCard(DocumentSummary summary) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_special_outlined, color: AppColors.gold500, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belge Hazırlık Skoru',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatusPill(label: '${summary.supportReadyScore}/100'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.insight,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniSummaryCard(
                label: 'Yüklü Belgeler',
                value: '${summary.uploadedDocuments}',
              ),
              _MiniSummaryCard(
                label: 'Eksik Gereksinimler',
                value: '${summary.missingRequirements}',
              ),
              _MiniSummaryCard(
                label: 'Süresi Yaklaşan',
                value: '${summary.willExpireDocuments}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () => _showUploadSheet(),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Belge Yükle'),
                ),
              ),
              SizedBox(
                width: 220,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedFilter = 'Eksik Belgeler');
                  },
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: const Text('Eksik Belgeleri Gör'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportShortcut() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _openDocumentGapReport,
          icon: const Icon(Icons.assessment_outlined),
          label: const Text('Eksik Belge Raporu Oluştur'),
        ),
      ),
    );
  }

  Widget _buildMetricGrid(DocumentSummary summary) {
    final metrics = [
      MetricCard(
        title: 'Toplam Belge',
        value: '${summary.totalDocuments}',
        subtitle: 'Sistemde kayıtlı belge sayısı',
        icon: Icons.folder_copy_outlined,
        color: AppColors.gold500,
      ),
      MetricCard(
        title: 'Eksik Belge',
        value: '${summary.missingRequirements}',
        subtitle: 'Hazırlık listesinde açık kalan belge ihtiyacı',
        icon: Icons.assignment_late_outlined,
        color: AppColors.warning,
      ),
      MetricCard(
        title: 'Süresi Geçen',
        value: '${summary.expiredDocuments}',
        subtitle: 'Güncellenmesi önerilen belgeler',
        icon: Icons.event_busy_outlined,
        color: AppColors.danger,
      ),
      MetricCard(
        title: 'Süresi Yaklaşan',
        value: '${summary.willExpireDocuments}',
        subtitle: 'Önümüzdeki 30 günde yenilenmesi iyi olur',
        icon: Icons.schedule_outlined,
        color: AppColors.info,
      ),
      MetricCard(
        title: 'Yüksek Öncelikli Eksik',
        value: '${summary.highPriorityMissing}',
        subtitle: 'Başvuru hazırlığını en çok etkileyen gereksinimler',
        icon: Icons.priority_high_outlined,
        color: AppColors.gold400,
      ),
      MetricCard(
        title: 'Yüklü Belge',
        value: '${summary.uploadedDocuments}',
        subtitle: 'Dosyası yüklenmiş ve takibe alınmış belge',
        icon: Icons.cloud_done_outlined,
        color: AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 3 : constraints.maxWidth >= 720 ? 2 : 1;
        final itemWidth = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map((metric) => SizedBox(width: itemWidth, child: metric))
              .toList(),
        );
      },
    );
  }

  Widget _buildInsightCard(DocumentSummary summary) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ Belge Yorumu',
            subtitle: 'Belge hazırlık görünümü verilerinize göre özetlenir',
          ),
          const SizedBox(height: 12),
          Text(
            summary.insight,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Filtreler ve Arama',
            subtitle: 'Belge türü, durum ve başlığa göre hızlıca daraltın',
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Belge adı, türü, kurum veya etiket ile arayın',
              prefixIcon: const Icon(Icons.search),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _filters
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    selectedColor: AppColors.gold500.withValues(alpha: 0.18),
                    backgroundColor: AppColors.surfaceAlt,
                    side: BorderSide(
                      color: _selectedFilter == filter
                          ? AppColors.gold500.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter
                          ? AppColors.gold400
                          : AppColors.textSecondary,
                      fontWeight: _selectedFilter == filter
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(List<BusinessDocumentModel> documents) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Belge Listesi',
            subtitle: 'Yüklenen dosyalar, durumlar ve geçerlilik tarihleri',
          ),
          const SizedBox(height: 14),
          if (documents.isEmpty)
            const Text('Seçili filtreye uygun belge bulunamadı.')
          else
            ...documents.map(
              (document) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DocumentCard(
                  document: document,
                  dateFormat: _dateFormat,
                  onDelete: () => _deleteDocument(document),
                  onOpenPlaceholder: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belge görüntüleme bu sürümde yakında eklenecek.'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection(List<DocumentRequirementModel> requirements) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Eksik Belge Gereksinimleri',
            subtitle: 'Destek Analizi ve işletme profiline göre önerilen belge ihtiyaçları',
          ),
          const SizedBox(height: 14),
          if (requirements.isEmpty)
            const Text(
              'Şimdilik eksik belge gereksinimi görünmüyor. Destek Analizi ve işletme profili güncellendikçe öneriler burada listelenir.',
            )
          else
            ...requirements.map(
              (requirement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequirementCard(
                  requirement: requirement,
                  dateFormat: _dateFormat,
                  onUpload: () => _showUploadSheet(requirement: requirement),
                  onComplete: requirement.isCompleted
                      ? null
                      : () => _markRequirementCompleted(requirement),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return SmartCard(
      child: Text(
        'Belge durumu takip amaçlıdır. Süresi yaklaşan belgeleri erkenden güncellemeniz, destek ve başvuru süreçlerinde daha rahat ilerlemenizi sağlar.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  List<BusinessDocumentModel> _filteredDocuments() {
    final search = _searchQuery.toLowerCase();
    return _documents.where((document) {
      final matchesFilter = switch (_selectedFilter) {
        'Tümü' => true,
        'Şirket Belgeleri' => document.category == 'company',
        'Finansal Belgeler' => document.category == 'finance',
        'Destek Evrakları' => document.category == 'support',
        'Sertifikalar' => document.category == 'certification',
        'İhracat Belgeleri' => document.category == 'export',
        'Teknik Dokümanlar' => document.category == 'technical',
        'Süresi Geçen' => document.isExpired,
        'Eksik Belgeler' => false,
        _ => true,
      };

      final haystack = [
        document.title,
        document.documentTypeLabel,
        document.categoryLabel,
        document.issuer ?? '',
        document.fileName ?? '',
        document.tags.join(' '),
      ].join(' ').toLowerCase();

      return matchesFilter && (search.isEmpty || haystack.contains(search));
    }).toList();
  }

  List<DocumentRequirementModel> _filteredRequirements() {
    final search = _searchQuery.toLowerCase();
    return _requirements.where((requirement) {
      final matchesFilter = switch (_selectedFilter) {
        'Tümü' => true,
        'Şirket Belgeleri' => requirement.category == 'company',
        'Finansal Belgeler' => requirement.category == 'finance',
        'Destek Evrakları' => requirement.category == 'support',
        'Sertifikalar' => requirement.category == 'certification',
        'İhracat Belgeleri' => requirement.category == 'export',
        'Teknik Dokümanlar' => requirement.category == 'technical',
        'Süresi Geçen' => false,
        'Eksik Belgeler' => requirement.isMissing,
        _ => true,
      };

      final haystack = [
        requirement.title,
        requirement.requiredDocumentTypeLabel,
        requirement.categoryLabel,
        requirement.description ?? '',
      ].join(' ').toLowerCase();

      return matchesFilter && (search.isEmpty || haystack.contains(search));
    }).toList();
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.dateFormat,
    required this.onDelete,
    required this.onOpenPlaceholder,
  });

  final BusinessDocumentModel document;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final VoidCallback onOpenPlaceholder;

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: _statusColor(document.status).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined, color: _statusColor(document.status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${document.documentTypeLabel} • ${document.categoryLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: document.statusLabel, color: _statusColor(document.status)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(label: 'Dosya', value: document.fileName ?? 'Dosya eklenmedi'),
              _MetaPill(label: 'Boyut', value: document.formattedFileSize),
              _MetaPill(label: 'Yükleme', value: dateFormat.format(document.createdAt)),
              if (document.expiryDate != null)
                _MetaPill(label: 'Geçerlilik', value: dateFormat.format(document.expiryDate!)),
            ],
          ),
          if (document.issuer?.trim().isNotEmpty == true ||
              document.referenceNumber?.trim().isNotEmpty == true ||
              document.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              [
                if (document.issuer?.trim().isNotEmpty == true)
                  'Veren kurum: ${document.issuer}',
                if (document.referenceNumber?.trim().isNotEmpty == true)
                  'Referans no: ${document.referenceNumber}',
                if (document.notes?.trim().isNotEmpty == true) document.notes!,
              ].join('\n'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (document.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: document.tags
                  .map((tag) => _TagChip(label: tag))
                  .toList(),
            ),
          ],
          if (document.isExpired || document.willExpireSoon) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  document.isExpired ? Icons.warning_amber_rounded : Icons.schedule_outlined,
                  size: 18,
                  color: document.isExpired ? AppColors.danger : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.isExpired
                        ? 'Bu belgenin süresi geçti. Güncellemeniz önerilir.'
                        : 'Bu belgenin süresi yaklaşıyor. Erken yenileme rahatlık sağlar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenPlaceholder,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Görüntüle'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenPlaceholder,
                icon: const Icon(Icons.download_outlined),
                label: const Text('İndir'),
              ),
              OutlinedButton.icon(
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

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.requirement,
    required this.dateFormat,
    required this.onUpload,
    this.onComplete,
  });

  final DocumentRequirementModel requirement;
  final DateFormat dateFormat;
  final VoidCallback onUpload;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = switch (requirement.sourceModule) {
      'support_analysis' => 'Destek Analizi',
      'business_profile' => 'İşletme Profili',
      'manual' => 'Manuel',
      'ai_advisor' => 'AI Danışman',
      _ => 'Sistem',
    };

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requirement.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${requirement.requiredDocumentTypeLabel} • ${requirement.categoryLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: requirement.statusLabel,
                color: requirement.isCompleted ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          if (requirement.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(requirement.description!),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(label: 'Öncelik', value: requirement.priorityLabel),
              _MetaPill(label: 'Kaynak', value: sourceLabel),
              if (requirement.dueDate != null)
                _MetaPill(label: 'Hedef tarih', value: dateFormat.format(requirement.dueDate!)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Belge Yükle'),
              ),
              if (onComplete != null)
                OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('Tamamlandı Olarak İşaretle'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentUploadSheet extends StatefulWidget {
  const _DocumentUploadSheet({
    required this.onSubmit,
    this.initialRequirement,
  });

  final Future<void> Function({
    required String title,
    required String documentType,
    required String category,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? issuer,
    String? referenceNumber,
    String? notes,
    List<String> tags,
  }) onSubmit;
  final DocumentRequirementModel? initialRequirement;

  @override
  State<_DocumentUploadSheet> createState() => _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends State<_DocumentUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _saving = false;
  String _documentType = 'tax_certificate';
  String _category = 'company';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  Uint8List? _fileBytes;
  String? _fileName;
  String _mimeType = 'application/octet-stream';

  @override
  void initState() {
    super.initState();
    final requirement = widget.initialRequirement;
    if (requirement != null) {
      _titleController.text = requirement.title;
      _documentType = requirement.requiredDocumentType;
      _category = requirement.category;
      _notesController.text = requirement.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya içeriği alınamadı. Lütfen tekrar deneyin.')),
      );
      return;
    }

    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
      _mimeType = _guessMimeType(file.name);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_fileBytes == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir dosya seçin.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final tags = _tagsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      await widget.onSubmit(
        title: _titleController.text.trim(),
        documentType: _documentType,
        category: _category,
        fileBytes: _fileBytes!,
        fileName: _fileName!,
        mimeType: _mimeType,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        issuer: _issuerController.text.trim().isEmpty ? null : _issuerController.text.trim(),
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        tags: tags,
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge başarıyla yüklendi.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onChanged,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + insets.bottom),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Belge Yükle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Belge türünü seçin, dosyanızı yükleyin ve temel bilgileri ekleyin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _AuthLikeField(
                    controller: _titleController,
                    label: 'Belge başlığı',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Belge başlığı zorunludur.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Belge türü',
                          value: _documentType,
                          items: _documentTypeOptions,
                          onChanged: (value) => setState(() => _documentType = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Kategori',
                          value: _category,
                          items: _categoryOptions,
                          onChanged: (value) => setState(() => _category = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickFile,
                    icon: const Icon(Icons.attach_file_outlined),
                    label: Text(_fileName ?? 'Dosya seç'),
                  ),
                  const SizedBox(height: 12),
                  _AuthLikeField(
                    controller: _issuerController,
                    label: 'Veren kurum',
                  ),
                  const SizedBox(height: 12),
                  _AuthLikeField(
                    controller: _referenceController,
                    label: 'Referans numarası',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Belge tarihi',
                          value: _issueDate,
                          onTap: () => _pickDate(
                            currentValue: _issueDate,
                            onChanged: (value) => setState(() => _issueDate = value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Geçerlilik tarihi',
                          value: _expiryDate,
                          onTap: () => _pickDate(
                            currentValue: _expiryDate,
                            onChanged: (value) => setState(() => _expiryDate = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AuthLikeField(
                    controller: _tagsController,
                    label: 'Etiketler',
                    hintText: 'ör. kosgeb, mali, sertifika',
                  ),
                  const SizedBox(height: 12),
                  _AuthLikeField(
                    controller: _notesController,
                    label: 'Notlar',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(_saving ? 'Yükleniyor...' : 'Belgeyi Kaydet'),
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
}

class _AuthLikeField extends StatelessWidget {
  const _AuthLikeField({
    required this.controller,
    required this.label,
    this.hintText,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      decoration: InputDecoration(
        labelText: label,
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
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Seçin'
        : DateFormat('d MMM y', 'tr_TR').format(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
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
        child: Text(text),
      ),
    );
  }
}

class _EmptyDocumentsState extends StatelessWidget {
  const _EmptyDocumentsState({required this.onUpload});

  final Future<void> Function({DocumentRequirementModel? requirement}) onUpload;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        children: [
          const Icon(Icons.upload_file_outlined, size: 40, color: AppColors.gold500),
          const SizedBox(height: 12),
          Text(
            'Henüz belge yüklenmedi.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk belgenizi yükleyerek destek analizi ve başvuru hazırlık sürecinizi güçlendirin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => onUpload(),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('İlk Belgeyi Yükle'),
          ),
        ],
      ),
    );
  }
}

class _DocumentsError extends StatelessWidget {
  const _DocumentsError({
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
                'Belgeler alınamadı',
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

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.navy900.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.gold400,
            ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    this.color = AppColors.gold500,
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

Color _statusColor(String status) {
  switch (status) {
    case 'approved':
    case 'uploaded':
      return AppColors.success;
    case 'expired':
    case 'rejected':
      return AppColors.danger;
    case 'will_expire':
      return AppColors.warning;
    case 'needs_review':
      return AppColors.info;
    default:
      return AppColors.gold500;
  }
}

String _guessMimeType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  return 'application/octet-stream';
}

final List<MapEntry<String, String>> _documentTypeOptions = [
  const MapEntry('tax_certificate', 'Vergi Levhası'),
  const MapEntry('activity_certificate', 'Faaliyet Belgesi'),
  const MapEntry('signature_circular', 'İmza Sirküleri'),
  const MapEntry('sme_declaration', 'KOBİ Beyannamesi'),
  const MapEntry('capacity_report', 'Kapasite Raporu'),
  const MapEntry('invoice', 'Fatura'),
  const MapEntry('receipt', 'Dekont'),
  const MapEntry('proforma_invoice', 'Proforma Fatura'),
  const MapEntry('quotation', 'Teklif Formu'),
  const MapEntry('technical_specification', 'Teknik Şartname / Teknik Doküman'),
  const MapEntry('iso_certificate', 'ISO Belgesi'),
  const MapEntry('tse_certificate', 'TSE Belgesi'),
  const MapEntry('ce_certificate', 'CE Belgesi'),
  const MapEntry('export_document', 'İhracat Belgesi'),
  const MapEntry('bank_document', 'Banka / Finansman Belgesi'),
  const MapEntry('contract', 'Sözleşme'),
  const MapEntry('other', 'Diğer'),
];

final List<MapEntry<String, String>> _categoryOptions = [
  const MapEntry('company', 'Şirket Belgeleri'),
  const MapEntry('finance', 'Finansal Belgeler'),
  const MapEntry('support', 'Destek Evrakları'),
  const MapEntry('certification', 'Sertifikalar'),
  const MapEntry('export', 'İhracat Belgeleri'),
  const MapEntry('technical', 'Teknik Dokümanlar'),
  const MapEntry('contract', 'Sözleşmeler'),
  const MapEntry('general', 'Genel'),
];
