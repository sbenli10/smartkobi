import 'package:flutter/material.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/smart_card.dart';
import '../business_profile/business_profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Ayarlar',
      subtitle: 'İşletme, kullanıcı, bildirim ve entegrasyon tercihlerini yönetin.',
      child: ListView(
        children: [
          _SettingTile(
            title: 'İşletme profili',
            subtitle: 'Firma bilgileri, vergi numarası ve işletme ölçeği',
            icon: Icons.business_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BusinessProfilePage(),
                ),
              );
            },
          ),
          const _SettingTile(
            title: 'Kullanıcılar ve yetkiler',
            subtitle: 'Rol bazlı erişim ve ekip üyeleri yönetimi',
            icon: Icons.manage_accounts_outlined,
          ),
          const _SettingTile(
            title: 'Bildirimler',
            subtitle: 'Tahsilat, kritik stok ve hedef sapması uyarıları',
            icon: Icons.notifications_active_outlined,
          ),
          const _SettingTile(
            title: 'Entegrasyonlar',
            subtitle: 'Muhasebe, banka ve e-belge bağlantıları',
            icon: Icons.hub_outlined,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SmartCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
