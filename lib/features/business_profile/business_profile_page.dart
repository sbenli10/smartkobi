import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/repositories/business_profile_repository.dart';
import 'business_profile_completion.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _repository = BusinessProfileRepository();
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _sectorController = TextEditingController();
  final _naceCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _foundationYearController = TextEditingController();
  final _employeeCountController = TextEditingController();
  final _mainProductsController = TextEditingController();
  final _targetInvestmentController = TextEditingController();
  final _targetMarketsController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherCertificationController = TextEditingController();

  String? _businessType;
  String? _annualRevenueRange;
  String? _monthlyExpenseRange;
  bool _doesManufacture = false;
  bool _doesExport = false;
  bool _wantsExport = false;
  bool _hasEcommerce = false;
  bool _hasPhysicalStore = false;
  bool _needsMachinery = false;
  bool _needsDigitalization = false;
  bool _needsCertification = false;
  bool _needsFinancing = false;
  final Set<String> _selectedCertifications = <String>{};

  BusinessProfileModel? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  static const List<_OptionItem> _businessTypes = [
    _OptionItem('sole_proprietorship', 'Şahıs Şirketi'),
    _OptionItem('limited', 'Limited Şirket'),
    _OptionItem('joint_stock', 'Anonim Şirket'),
    _OptionItem('cooperative', 'Kooperatif'),
    _OptionItem('other', 'Diğer'),
  ];

  static const List<_OptionItem> _annualRevenueOptions = [
    _OptionItem('0_1m', '0 - 1 Milyon TL'),
    _OptionItem('1m_5m', '1 - 5 Milyon TL'),
    _OptionItem('5m_10m', '5 - 10 Milyon TL'),
    _OptionItem('10m_50m', '10 - 50 Milyon TL'),
    _OptionItem('50m_plus', '50 Milyon TL+'),
    _OptionItem('unknown', 'Henüz Bilmiyorum'),
  ];

  static const List<_OptionItem> _monthlyExpenseOptions = [
    _OptionItem('0_100k', '0 - 100 Bin TL'),
    _OptionItem('100k_500k', '100 - 500 Bin TL'),
    _OptionItem('500k_1m', '500 Bin - 1 Milyon TL'),
    _OptionItem('1m_5m', '1 - 5 Milyon TL'),
    _OptionItem('5m_plus', '5 Milyon TL+'),
    _OptionItem('unknown', 'Henüz Bilmiyorum'),
  ];

  static const List<String> _certificationOptions = [
    'TSE',
    'ISO 9001',
    'ISO 14001',
    'CE',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _sectorController.dispose();
    _naceCodeController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _foundationYearController.dispose();
    _employeeCountController.dispose();
    _mainProductsController.dispose();
    _targetInvestmentController.dispose();
    _targetMarketsController.dispose();
    _notesController.dispose();
    _otherCertificationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.fetchMyBusinessProfile() ??
          BusinessProfileModel.empty(
            businessName: Supabase.instance.client.auth.currentUser?.userMetadata?['business_name']
                    ?.toString() ??
                '',
            userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          );

      _applyProfile(profile);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
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

  void _applyProfile(BusinessProfileModel profile) {
    _businessNameController.text = profile.businessName;
    _legalNameController.text = profile.legalName ?? '';
    _taxNumberController.text = profile.taxNumber ?? '';
    _taxOfficeController.text = profile.taxOffice ?? '';
    _sectorController.text = profile.sector ?? '';
    _naceCodeController.text = profile.naceCode ?? '';
    _cityController.text = profile.city ?? '';
    _districtController.text = profile.district ?? '';
    _foundationYearController.text = profile.foundationYear?.toString() ?? '';
    _employeeCountController.text = profile.employeeCount?.toString() ?? '';
    _mainProductsController.text = profile.mainProducts ?? '';
    _targetInvestmentController.text =
        profile.targetInvestmentAmount?.toStringAsFixed(0) ?? '';
    _targetMarketsController.text = profile.targetMarkets ?? '';
    _notesController.text = profile.notes ?? '';
    _businessType = profile.businessType;
    _annualRevenueRange = profile.annualRevenueRange;
    _monthlyExpenseRange = profile.monthlyExpenseRange;
    _doesManufacture = profile.doesManufacture;
    _doesExport = profile.doesExport;
    _wantsExport = profile.wantsExport;
    _hasEcommerce = profile.hasEcommerce;
    _hasPhysicalStore = profile.hasPhysicalStore;
    _needsMachinery = profile.needsMachinery;
    _needsDigitalization = profile.needsDigitalization;
    _needsCertification = profile.needsCertification;
    _needsFinancing = profile.needsFinancing;
    _selectedCertifications
      ..clear()
      ..addAll(profile.certifications);
    _otherCertificationController.text = profile.certifications
        .where((item) => !_certificationOptions.contains(item))
        .join(', ');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final saved = await _repository.upsertBusinessProfile(_buildProfile());
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = saved;
        _saving = false;
      });

      _showSnackBar('İşletme profili güncellendi.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _showSnackBar(
        'İşletme profili kaydedilemedi. Lütfen tekrar deneyin.',
        isError: true,
      );
    }
  }

  BusinessProfileModel _buildProfile() {
    final existing = _profile ??
        BusinessProfileModel.empty(
          businessName: _businessNameController.text.trim(),
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        );

    final certifications = <String>{
      ..._selectedCertifications,
      ..._otherCertificationController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    }.toList();

    final amountText = _targetInvestmentController.text.trim().replaceAll('.', '').replaceAll(',', '.');

    final profile = existing.copyWith(
      businessName: _businessNameController.text.trim(),
      legalName: _emptyToNull(_legalNameController.text),
      taxNumber: _emptyToNull(_taxNumberController.text),
      taxOffice: _emptyToNull(_taxOfficeController.text),
      businessType: _businessType,
      sector: _emptyToNull(_sectorController.text),
      naceCode: _emptyToNull(_naceCodeController.text),
      city: _emptyToNull(_cityController.text),
      district: _emptyToNull(_districtController.text),
      foundationYear: _parseInt(_foundationYearController.text),
      employeeCount: _parseInt(_employeeCountController.text),
      annualRevenueRange: _annualRevenueRange,
      monthlyExpenseRange: _monthlyExpenseRange,
      doesManufacture: _doesManufacture,
      doesExport: _doesExport,
      wantsExport: _wantsExport,
      hasEcommerce: _hasEcommerce,
      hasPhysicalStore: _hasPhysicalStore,
      needsMachinery: _needsMachinery,
      needsDigitalization: _needsDigitalization,
      needsCertification: _needsCertification,
      needsFinancing: _needsFinancing,
      targetInvestmentAmount: amountText.isEmpty ? null : double.tryParse(amountText),
      mainProducts: _emptyToNull(_mainProductsController.text),
      targetMarkets: _emptyToNull(_targetMarketsController.text),
      certifications: certifications,
      notes: _emptyToNull(_notesController.text),
    );

    final completion = calculateBusinessProfileCompletion(profile);
    return profile.copyWith(
      profileCompletion: completion,
      onboardingCompleted: completion >= 70,
    );
  }

  BusinessProfileModel _previewProfile() {
    try {
      return _buildProfile();
    } catch (_) {
      return _profile ??
          BusinessProfileModel.empty(
            businessName: _businessNameController.text.trim(),
            userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          );
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _parseInt(String value) => int.tryParse(value.trim());

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.warning : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewProfile();
    final completion = calculateBusinessProfileCompletion(preview);
    final sections = <Widget>[
      _basicCard(),
      _activityCard(),
      _financeCard(),
      _operationsCard(),
      _needsCard(),
      _certificationsCard(),
      _marketsCard(),
    ];

    return PageScaffold(
      title: 'İşletme Profili',
      subtitle: 'SmartKOBİ analizlerini güçlendirmek için işletme bilgilerinizi tamamlayın.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadProfile,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _loading
          ? const Center(child: Text('İşletme profili yükleniyor...'))
          : _errorMessage != null
              ? _ProfileErrorState(message: _errorMessage!, onRetry: _loadProfile)
              : Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1100;
                      if (isWide) {
                        return ListView(
                          children: [
                            _ProfileHeroCard(
                              businessName: preview.businessName.isEmpty
                                  ? 'İşletmeniz'
                                  : preview.businessName,
                              completion: completion,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      sections[0],
                                      const SizedBox(height: 16),
                                      sections[2],
                                      const SizedBox(height: 16),
                                      sections[4],
                                      const SizedBox(height: 16),
                                      sections[6],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      sections[1],
                                      const SizedBox(height: 16),
                                      sections[3],
                                      const SizedBox(height: 16),
                                      sections[5],
                                      const SizedBox(height: 16),
                                      _SaveCard(saving: _saving, onSave: _saveProfile),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return ListView(
                        children: [
                          _ProfileHeroCard(
                            businessName: preview.businessName.isEmpty
                                ? 'İşletmeniz'
                                : preview.businessName,
                            completion: completion,
                          ),
                          const SizedBox(height: 16),
                          for (final section in sections) ...[
                            section,
                            const SizedBox(height: 16),
                          ],
                          _SaveCard(saving: _saving, onSave: _saveProfile),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _basicCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Temel Bilgiler',
            subtitle: 'Firma adı, unvan ve vergi bilgilerini ekleyin.',
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: _businessNameController,
            label: 'İşletme adı',
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'İşletme adı zorunludur.' : null,
          ),
          const SizedBox(height: 12),
          _FormField(controller: _legalNameController, label: 'Resmi unvan'),
          const SizedBox(height: 12),
          _FormField(
            controller: _taxNumberController,
            label: 'Vergi no',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _FormField(controller: _taxOfficeController, label: 'Vergi dairesi'),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'İşletme türü',
            value: _businessType,
            items: _businessTypes,
            onChanged: (value) => setState(() => _businessType = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FormField(controller: _cityController, label: 'Şehir')),
              const SizedBox(width: 12),
              Expanded(child: _FormField(controller: _districtController, label: 'İlçe')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Faaliyet Bilgileri',
            subtitle: 'Sektör, NACE ve temel faaliyet yapınızı tanımlayın.',
          ),
          const SizedBox(height: 16),
          _FormField(controller: _sectorController, label: 'Sektör'),
          const SizedBox(height: 12),
          _FormField(controller: _naceCodeController, label: 'NACE kodu'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: _foundationYearController,
                  label: 'Kuruluş yılı',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    final year = int.tryParse(text);
                    if (year == null || year < 1900 || year > DateTime.now().year) {
                      return 'Geçerli bir yıl girin.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  controller: _employeeCountController,
                  label: 'Çalışan sayısı',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    final count = int.tryParse(text);
                    if (count == null || count < 0) {
                      return 'Negatif olamaz.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormField(
            controller: _mainProductsController,
            label: 'Ana ürün / hizmetler',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _financeCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Finansal Ölçek',
            subtitle: 'Ciro, gider ve yatırım hedefinizi belirtin.',
          ),
          const SizedBox(height: 16),
          _DropdownField(
            label: 'Yıllık ciro aralığı',
            value: _annualRevenueRange,
            items: _annualRevenueOptions,
            onChanged: (value) => setState(() => _annualRevenueRange = value),
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Aylık gider aralığı',
            value: _monthlyExpenseRange,
            items: _monthlyExpenseOptions,
            onChanged: (value) => setState(() => _monthlyExpenseRange = value),
          ),
          const SizedBox(height: 12),
          _FormField(
            controller: _targetInvestmentController,
            label: 'Hedef yatırım tutarı',
            prefixText: 'TL ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return null;
              }
              final parsed = double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                return 'Geçerli bir tutar girin.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _operationsCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Operasyon Bilgileri',
            subtitle: 'Faaliyet modelinizi birkaç seçimle işaretleyin.',
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            title: 'Üretim yapıyor',
            value: _doesManufacture,
            onChanged: (value) => setState(() => _doesManufacture = value),
          ),
          _SwitchTile(
            title: 'İhracat yapıyor',
            value: _doesExport,
            onChanged: (value) => setState(() => _doesExport = value),
          ),
          _SwitchTile(
            title: 'İhracat yapmak istiyor',
            value: _wantsExport,
            onChanged: (value) => setState(() => _wantsExport = value),
          ),
          _SwitchTile(
            title: 'E-ticaret yapıyor',
            value: _hasEcommerce,
            onChanged: (value) => setState(() => _hasEcommerce = value),
          ),
          _SwitchTile(
            title: 'Fiziksel mağazası var',
            value: _hasPhysicalStore,
            onChanged: (value) => setState(() => _hasPhysicalStore = value),
          ),
        ],
      ),
    );
  }

  Widget _needsCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'İhtiyaç Analizi',
            subtitle: 'SmartKOBİ önerilerini güçlendirecek ihtiyaç alanlarını seçin.',
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            title: 'Makine / teçhizat ihtiyacı var',
            value: _needsMachinery,
            onChanged: (value) => setState(() => _needsMachinery = value),
          ),
          _SwitchTile(
            title: 'Dijitalleşme ihtiyacı var',
            value: _needsDigitalization,
            onChanged: (value) => setState(() => _needsDigitalization = value),
          ),
          _SwitchTile(
            title: 'Belge / sertifika ihtiyacı var',
            value: _needsCertification,
            onChanged: (value) => setState(() => _needsCertification = value),
          ),
          _SwitchTile(
            title: 'Finansman ihtiyacı var',
            value: _needsFinancing,
            onChanged: (value) => setState(() => _needsFinancing = value),
          ),
        ],
      ),
    );
  }

  Widget _certificationsCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Sertifikalar',
            subtitle: 'Mevcut sertifikalarınızı işaretleyin.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _certificationOptions.map((item) {
              final selected = _selectedCertifications.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedCertifications.add(item);
                    } else {
                      _selectedCertifications.remove(item);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _FormField(
            controller: _otherCertificationController,
            label: 'Diğer sertifikalar',
            hintText: 'Virgülle ayırarak yazın',
          ),
        ],
      ),
    );
  }

  Widget _marketsCard() {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Hedef Pazarlar',
            subtitle: 'Pazar hedeflerinizi ve ek notlarınızı girin.',
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: _targetMarketsController,
            label: 'Hedef pazarlar',
            hintText: 'Türkiye iç pazar, Almanya, Avrupa, Orta Doğu...',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _FormField(
            controller: _notesController,
            label: 'Ek notlar',
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.businessName,
    required this.completion,
  });

  final String businessName;
  final int completion;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.business_center_outlined, color: AppColors.gold500),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Profiliniz %$completion tamamlandı',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold400,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(getCompletionDescription(completion)),
                  ],
                ),
              ),
              _CompletionBadge(completion: completion),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: completion / 100,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.completion});

  final int completion;

  @override
  Widget build(BuildContext context) {
    final label = getCompletionLabel(completion);
    final color = completion >= 90
        ? AppColors.success
        : completion >= 70
            ? AppColors.info
            : completion >= 40
                ? AppColors.warning
                : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SaveCard extends StatelessWidget {
  const _SaveCard({
    required this.saving,
    required this.onSave,
  });

  final bool saving;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Kaydet',
            subtitle: 'Profili güncel tuttukça destek analizi ve AI önerileri güçlenir.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Kaydediliyor...' : 'Profili Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SmartCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.warning, size: 40),
            const SizedBox(height: 12),
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
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
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
  final String? value;
  final List<_OptionItem> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.value,
              child: Text(item.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      activeThumbColor: AppColors.gold500,
      activeTrackColor: AppColors.gold500.withValues(alpha: 0.35),
      onChanged: onChanged,
    );
  }
}

class _OptionItem {
  const _OptionItem(this.value, this.label);

  final String value;
  final String label;
}
