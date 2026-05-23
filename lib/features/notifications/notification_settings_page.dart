import 'package:flutter/material.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../data/repositories/notifications_repository.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _repository = NotificationsRepository();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  NotificationPreferencesModel? _preferences;

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
      final preferences = await _repository.fetchPreferences();
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = preferences;
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

  Future<void> _save(NotificationPreferencesModel preferences) async {
    setState(() {
      _saving = true;
    });
    try {
      final saved = await _repository.upsertPreferences(preferences);
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirim tercihleri kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _update(NotificationPreferencesModel Function(NotificationPreferencesModel current) builder) {
    final current = _preferences;
    if (current == null) {
      return;
    }
    final next = builder(current);
    setState(() {
      _preferences = next;
    });
    _save(next);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bildirim Ayarları',
      subtitle: 'Hangi hatırlatmaları görmek istediğinizi yönetin.',
      child: _loading
          ? const Center(child: Text('Bildirim ayarları yükleniyor...'))
          : _errorMessage != null
              ? _SettingsError(message: _errorMessage!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final preferences = _preferences!;
    return ListView(
      children: [
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Bildirim Kanalları',
                subtitle: 'Uygulama içi ve gelecekte gelecek kanal seçenekleri',
              ),
              const SizedBox(height: 12),
              _SwitchRow(
                title: 'Uygulama içi bildirimler',
                subtitle: 'Bildirim merkezi içinde hatırlatmaları göster.',
                value: preferences.inAppEnabled,
                onChanged: (value) => _update((current) => current.copyWith(inAppEnabled: value)),
              ),
              _SwitchRow(
                title: 'Push bildirimler',
                subtitle: 'Mobil push bildirimleri yakında aktif olacak.',
                value: preferences.pushEnabled,
                onChanged: (value) => _update((current) => current.copyWith(pushEnabled: value)),
              ),
              _SwitchRow(
                title: 'E-posta bildirimleri',
                subtitle: 'Özet e-posta gönderimi için altyapı sonraki sürümde genişletilecek.',
                value: preferences.emailEnabled,
                onChanged: (value) => _update((current) => current.copyWith(emailEnabled: value)),
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
                title: 'Hatırlatma Türleri',
                subtitle: 'İşletmeniz için hangi konularda uyarı almak istediğinizi seçin',
              ),
              const SizedBox(height: 12),
              _SwitchRow(
                title: 'Tahsilat bildirimleri',
                subtitle: 'Geciken ve yaklaşan tahsilatları hatırlat.',
                value: preferences.collectionEnabled,
                onChanged: (value) => _update((current) => current.copyWith(collectionEnabled: value)),
              ),
              _SwitchRow(
                title: 'Ödeme bildirimleri',
                subtitle: 'Yaklaşan ödemeler için uyarı üret.',
                value: preferences.paymentEnabled,
                onChanged: (value) => _update((current) => current.copyWith(paymentEnabled: value)),
              ),
              _SwitchRow(
                title: 'Stok bildirimleri',
                subtitle: 'Kritik ve tükenen ürünleri takip et.',
                value: preferences.inventoryEnabled,
                onChanged: (value) => _update((current) => current.copyWith(inventoryEnabled: value)),
              ),
              _SwitchRow(
                title: 'Nakit riski bildirimleri',
                subtitle: 'Nakit görünümü zayıfladığında uyarı ver.',
                value: preferences.cashflowEnabled,
                onChanged: (value) => _update((current) => current.copyWith(cashflowEnabled: value)),
              ),
              _SwitchRow(
                title: 'Belge bildirimleri',
                subtitle: 'Süresi yaklaşan ve eksik belgeleri hatırlat.',
                value: preferences.documentEnabled,
                onChanged: (value) => _update((current) => current.copyWith(documentEnabled: value)),
              ),
              _SwitchRow(
                title: 'Destek bildirimleri',
                subtitle: 'Destek analizi güncelleme hatırlatmaları oluştur.',
                value: preferences.supportEnabled,
                onChanged: (value) => _update((current) => current.copyWith(supportEnabled: value)),
              ),
              _SwitchRow(
                title: 'Rapor bildirimleri',
                subtitle: 'Haftalık rapor oluşturma önerilerini göster.',
                value: preferences.reportEnabled,
                onChanged: (value) => _update((current) => current.copyWith(reportEnabled: value)),
              ),
              _SwitchRow(
                title: 'Profil bildirimleri',
                subtitle: 'İşletme profili tamamlanma hatırlatmalarını göster.',
                value: preferences.profileEnabled,
                onChanged: (value) => _update((current) => current.copyWith(profileEnabled: value)),
              ),
              _SwitchRow(
                title: 'Günlük iş planı bildirimi',
                subtitle: 'Her gün iş planı bildirimini oluştur.',
                value: preferences.dailyPlanEnabled,
                onChanged: (value) => _update((current) => current.copyWith(dailyPlanEnabled: value)),
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
                title: 'Zamanlama',
                subtitle: 'Günlük plan bildiriminin görünen saatini ayarlayın',
              ),
              const SizedBox(height: 12),
              _TimeOptionRow(
                label: 'Günlük bildirim saati',
                value: preferences.dailyPlanTime,
                onSelected: (value) => _update((current) => current.copyWith(dailyPlanTime: value)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Telefon bildirimi için Firebase Cloud Messaging kurulumu gerekir. İlk sürümde hatırlatmalar uygulama içinde gösterilir.',
                ),
              ),
              if (_saving) ...[
                const SizedBox(height: 12),
                const Text('Kaydediliyor...'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TimeOptionRow extends StatelessWidget {
  const _TimeOptionRow({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = ['08:00', '09:00', '10:00', '11:00'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (item) => ChoiceChip(
                  label: Text(item),
                  selected: item == value,
                  onSelected: (_) => onSelected(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({
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
