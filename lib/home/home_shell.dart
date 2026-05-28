import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/ai/ai_chat_page.dart';
import '../features/ai/ai_page.dart';
import '../features/ai/cashflow_page.dart';
import '../features/business_profile/business_profile_page.dart';
import '../features/customers/customers_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/documents/documents_page.dart';
import 'package:smartkobi/features/inventory/inventory_page.dart';
import '../features/kpi/kpi_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/settings_page.dart';
import '../features/support/support_analysis_page.dart';
import '../features/transactions/transactions_page.dart';
import '../data/repositories/notifications_repository.dart';
import '../features/profit_leakage/profit_leakage_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  final _notificationsRepository = NotificationsRepository();
  int _unreadNotificationCount = 0;

  late final List<SmartKobiNavItem> _items;

  // 'Analiz' grubu listeye eklendi, böylece Sidebar döngüsünde ekrana çizilecek
  late final List<String> _groupOrder = const [
    'Genel',
    'İşletme',
    'Analiz',
    'Akıllı asistan',
    'Büyüme',
    'Yönetim',
  ];

  List<SmartKobiNavItem> _buildItems() {
    return [
      const SmartKobiNavItem(
        id: 'dashboard',
        label: 'Ana ekran',
        description: 'İşletmenizin genel özeti ve hızlı işlemler',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        page: DashboardPage(),
        group: 'Genel',
        showInBottomNav: true,
      ),
      const SmartKobiNavItem(
        id: 'kpi',
        label: 'KPI',
        description: 'Temel performans göstergeleri',
        icon: Icons.query_stats_outlined,
        selectedIcon: Icons.query_stats,
        page: KpiPage(),
        group: 'Genel',
      ),
     const SmartKobiNavItem(
        id: 'profit-leakage',
        label: 'Fiyat radarı',
        description: 'Alış fiyatı artışlarını ve gizli kayıpları görün',
        icon: Icons.price_change_outlined,
        selectedIcon: Icons.price_change,
        page: ProfitLeakagePage(),
        group: 'İşletme', // <-- 'Analiz' yerine doğrudan 'İşletme' yaptık
      ),
      const SmartKobiNavItem(
        id: 'reports',
        label: 'Raporlar',
        description: 'Finansal ve operasyonel özetler',
        icon: Icons.assessment_outlined,
        selectedIcon: Icons.assessment,
        page: ReportsPage(),
        group: 'Genel',
      ),
      SmartKobiNavItem(
        id: 'notifications',
        label: 'Bildirimler',
        description: 'Akıllı hatırlatmalar ve önemli uyarılar',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        page: NotificationsPage(
          onUnreadCountChanged: _handleUnreadCountChanged,
          onNavigateToRoute: _openModuleFromNotification,
        ),
        group: 'Yönetim',
      ),
      const SmartKobiNavItem(
        id: 'finance',
        label: 'Finans',
        description: 'Gelir, gider ve işlem kayıtları',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        page: TransactionsPage(),
        group: 'İşletme',
        showInBottomNav: true,
      ),
      const SmartKobiNavItem(
        id: 'customers',
        label: 'Cari',
        description: 'Cari hesap ve tahsilat yönetimi',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        page: CustomersPage(),
        group: 'İşletme',
        showInBottomNav: true,
      ),
      SmartKobiNavItem(
        id: 'inventory',
        label: 'Stok',
        description: 'Ürünler, hareketler ve kritik stoklar',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        page: InventoryPage(),
        group: 'İşletme',
        showInBottomNav: true,
      ),
      const SmartKobiNavItem(
        id: 'cashflow',
        label: 'Nakit akışı',
        description: '30 ve 60 günlük nakit tahmini ile risk analizi',
        icon: Icons.waterfall_chart_outlined,
        selectedIcon: Icons.waterfall_chart,
        page: CashflowPage(),
        group: 'İşletme',
      ),
      const SmartKobiNavItem(
        id: 'advisor',
        label: 'Yapay zekâ danışmanı',
        description: 'İşletme verilerinize göre kısa öneriler alın',
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy,
        page: AiChatPage(),
        group: 'Akıllı asistan',
      ),
      const SmartKobiNavItem(
        id: 'ai-analytics',
        label: 'Yapay zekâ analizleri',
        description: 'Ek analizler ve veri yorumları',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
        page: AiPage(),
        group: 'Akıllı asistan',
      ),
      const SmartKobiNavItem(
        id: 'support',
        label: 'Destek analizi',
        description: 'KOSGEB, ihracat ve finansman için ön uygunluk analizi',
        icon: Icons.workspace_premium_outlined,
        selectedIcon: Icons.workspace_premium,
        page: SupportAnalysisPage(),
        group: 'Büyüme',
      ),
      const SmartKobiNavItem(
        id: 'documents',
        label: 'Belgeler',
        description: 'Hazırlanacak ve takip edilecek belge listeleri',
        icon: Icons.folder_open_outlined,
        selectedIcon: Icons.folder_open,
        page: DocumentsPage(),
        group: 'Büyüme',
      ),
      const SmartKobiNavItem(
        id: 'business-profile',
        label: 'İşletme profili',
        description: 'KOBİ kimlik kartı ve profil tamamlama bilgileri',
        icon: Icons.business_center_outlined,
        selectedIcon: Icons.business_center,
        page: BusinessProfilePage(),
        group: 'Yönetim',
      ),
      const SmartKobiNavItem(
        id: 'settings',
        label: 'Ayarlar',
        description: 'Uygulama ve hesap tercihleri',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: SettingsPage(),
        group: 'Yönetim',
      ),
    ];
  }

  List<SmartKobiNavItem> get _primaryMobileItems =>
      _items.where((item) => item.showInBottomNav).toList();

  // 'profit-leakage' kimliği eklendi, böylece mobil "Diğer" alt sayfasında da listelenecek
  List<SmartKobiNavItem> get _moreMobileItems =>
      [
        'cashflow',
        'profit-leakage',
        'advisor',
        'support',
        'notifications',
        'business-profile',
        'documents',
        'reports',
        'kpi',
        'ai-analytics',
        'settings',
      ]
          .map((id) => _items.firstWhere((item) => item.id == id))
          .toList();

  SmartKobiNavItem get _selectedItem => _items[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _items = _buildItems();
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidebar = constraints.maxWidth >= 900;
        final forceExpanded = constraints.maxWidth >= 1280;
        final sidebarExpanded = forceExpanded ? true : _sidebarExpanded;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.scaffoldBackground,
                    AppColors.surfaceAlt,
                  ],
                ),
              ),
              child: Row(
                children: [
                  if (useSidebar)
                    _SmartSidebar(
                      items: _items,
                      groupOrder: _groupOrder,
                      selectedIndex: _selectedIndex,
                      expanded: sidebarExpanded,
                      unreadNotificationCount: _unreadNotificationCount,
                      onToggleExpanded: forceExpanded
                          ? null
                          : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                      onSelect: _selectIndex,
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedItem.id),
                        child: _selectedItem.page,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: useSidebar
              ? null
              : _SmartBottomNav(
                  currentIndex: _mobileCurrentIndex,
                  onSelect: (value) {
                    if (value == 4) {
                      _openMoreModulesSheet(context);
                      return;
                    }
                    final item = _primaryMobileItems[value];
                    _selectIndex(_items.indexOf(item));
                  },
                ),
        );
      },
    );
  }

  int get _mobileCurrentIndex {
    final primaryIndex =
        _primaryMobileItems.indexWhere((item) => item.id == _selectedItem.id);
    return primaryIndex >= 0 ? primaryIndex : 4;
  }

  Future<void> _openMoreModulesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _MoreModulesSheet(
          items: _moreMobileItems,
          activeItemId: _selectedItem.id,
          unreadNotificationCount: _unreadNotificationCount,
          onSelect: (item) {
            Navigator.pop(context);
            _selectIndex(_items.indexOf(item));
          },
        );
      },
    );
  }

  void _selectIndex(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() => _selectedIndex = index);
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationsRepository.getUnreadCount();
      if (!mounted) {
        return;
      }
      setState(() => _unreadNotificationCount = count);
    } catch (_) {}
  }

  void _handleUnreadCountChanged(int count) {
    if (!mounted) {
      return;
    }
    setState(() => _unreadNotificationCount = count);
  }

  void _openModuleFromNotification(String route) {
    final normalizedRoute = route == 'business_profile' ? 'business-profile' : route;
    final targetIndex = _items.indexWhere((item) => item.id == normalizedRoute);
    if (targetIndex >= 0) {
      _selectIndex(targetIndex);
      return;
    }

    if (normalizedRoute == 'dashboard') {
      _selectIndex(0);
    }
  }
}

class _SmartSidebar extends StatelessWidget {
  const _SmartSidebar({
    required this.items,
    required this.groupOrder,
    required this.selectedIndex,
    required this.expanded,
    required this.unreadNotificationCount,
    required this.onSelect,
    this.onToggleExpanded,
  });

  final List<SmartKobiNavItem> items;
  final List<String> groupOrder;
  final int selectedIndex;
  final bool expanded;
  final int unreadNotificationCount;
  final ValueChanged<int> onSelect;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<MapEntry<int, SmartKobiNavItem>>>{};
    for (var i = 0; i < items.length; i++) {
      grouped.putIfAbsent(items[i].group, () => []).add(MapEntry(i, items[i]));
    }

    return Container(
      width: expanded ? 268 : 100,
      margin: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          _SidebarBrand(
            expanded: expanded,
            onToggleExpanded: onToggleExpanded,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  for (final group in groupOrder)
                    if ((grouped[group] ?? const []).isNotEmpty) ...[
                      if (expanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                          child: Text(
                            group,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ...grouped[group]!.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SidebarNavTile(
                            item: entry.value,
                            index: entry.key,
                            selected: entry.key == selectedIndex,
                            expanded: expanded,
                            badgeCount:
                                entry.value.id == 'notifications' ? unreadNotificationCount : 0,
                            onTap: () => onSelect(entry.key),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SidebarFooter(expanded: expanded),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({
    required this.expanded,
    this.onToggleExpanded,
  });

  final bool expanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryNavy,
                AppColors.turquoise,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.turquoise.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.hub, color: Colors.white),
        ),
        if (expanded) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartKOBİ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dijital iş ortağınız',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
        if (onToggleExpanded != null)
          IconButton(
            tooltip: expanded ? 'Menüyü daralt' : 'Menüyü genişlet',
            onPressed: onToggleExpanded,
            icon: Icon(
              expanded ? Icons.first_page_rounded : Icons.last_page_rounded,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.index,
    required this.selected,
    required this.expanded,
    required this.badgeCount,
    required this.onTap,
  });

  final SmartKobiNavItem item;
  final int index;
  final bool selected;
  final bool expanded;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.primaryNavy : AppColors.textSecondary;
    final labelColor = selected ? AppColors.primaryNavy : AppColors.textSecondary;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 14 : 0,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selected ? AppColors.turquoiseSoft : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? AppColors.turquoise : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Icon(selected ? item.selectedIcon : item.icon, color: iconColor, size: 22),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: labelColor,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (!expanded && badgeCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: tile,
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(expanded ? 14 : 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İşletme profili',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Profilinizi tamamladıkça analizler daha net hale gelir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            )
          : const Icon(Icons.business_center_outlined, color: AppColors.primaryNavy),
    );
  }
}

class _SmartBottomNav extends StatelessWidget {
  const _SmartBottomNav({
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.turquoiseSoft,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryNavy
                  : AppColors.textSecondary,
              fontWeight:
                  states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.turquoise
                  : AppColors.textSecondary,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelect,
          height: 72,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Ana ekran',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Finans',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Cari',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Stok',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Diğer',
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreModulesSheet extends StatelessWidget {
  const _MoreModulesSheet({
    required this.items,
    required this.activeItemId,
    required this.unreadNotificationCount,
    required this.onSelect,
  });

  final List<SmartKobiNavItem> items;
  final String activeItemId;
  final int unreadNotificationCount;
  final ValueChanged<SmartKobiNavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Diğer modüller',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Nakit akışı, destekler, raporlar ve yönetim modüllerine buradan geçin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = item.id == activeItemId;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: selected
                          ? AppColors.turquoiseSoft
                          : Colors.transparent,
                      leading: Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? AppColors.primaryNavy : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                            color: selected ? AppColors.primaryNavy : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text(item.description, style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppColors.primaryNavy)
                          : item.id == 'notifications' && unreadNotificationCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$unreadNotificationCount',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                )
                              : null,
                      onTap: () => onSelect(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartKobiNavItem {
  const SmartKobiNavItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    required this.group,
    this.showInBottomNav = false,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final String group;
  final bool showInBottomNav;
}
