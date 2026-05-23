import 'package:flutter/material.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/models/notification_summary_model.dart';
import '../../data/repositories/notifications_repository.dart';
import '../ai/cashflow_page.dart';
import '../business_profile/business_profile_page.dart';
import '../customers/customers_page.dart';
import '../documents/documents_page.dart';
import '../inventory/inventory_page.dart';
import '../reports/reports_page.dart';
import '../support/support_analysis_page.dart';
import '../transactions/transactions_page.dart';
import 'notification_settings_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.onUnreadCountChanged,
    this.onNavigateToRoute,
  });

  final ValueChanged<int>? onUnreadCountChanged;
  final ValueChanged<String>? onNavigateToRoute;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repository = NotificationsRepository();

  bool _loading = true;
  bool _refreshingReminders = false;
  String? _errorMessage;
  String _selectedFilter = 'all';
  NotificationSummaryModel _summary = NotificationSummaryModel.empty();
  List<AppNotificationModel> _notifications = const [];

  static const _filters = <String, String>{
    'all': 'Tümü',
    'unread': 'Okunmamış',
    'critical': 'Kritik',
    'collection': 'Tahsilat',
    'payment': 'Ödeme',
    'inventory': 'Stok',
    'cashflow': 'Nakit',
    'document': 'Belge',
    'support': 'Destek',
    'report': 'Rapor',
  };

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
      final notifications = await _repository.fetchNotifications();
      final summary = await _repository.fetchNotificationSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = notifications;
        _summary = summary;
        _loading = false;
      });
      widget.onUnreadCountChanged?.call(summary.unreadCount);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Bildirimler alınamadı. Lütfen bağlantınızı kontrol edin.';
      });
    }
  }

  Future<void> _generateReminders() async {
    setState(() {
      _refreshingReminders = true;
    });
    try {
      await _repository.generateAndSaveSmartReminders();
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akıllı hatırlatmalar güncellendi.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshingReminders = false;
        });
      }
    }
  }

  Future<void> _markAsRead(AppNotificationModel notification) async {
    await _repository.markAsRead(notification.id);
    await _load();
  }

  Future<void> _markAllAsRead() async {
    await _repository.markAllAsRead();
    await _load();
  }

  Future<void> _archive(AppNotificationModel notification) async {
    await _repository.archiveNotification(notification.id);
    await _load();
  }

  Future<void> _delete(AppNotificationModel notification) async {
    await _repository.deleteNotification(notification.id);
    await _load();
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    if (notification.isUnread) {
      await _repository.markAsRead(notification.id);
    }
    if (!mounted) {
      return;
    }
    final route = notification.actionRoute ?? notification.sourceModule ?? 'dashboard';
    if (widget.onNavigateToRoute != null && _canNavigateInsideShell(route)) {
      final nextUnreadCount =
          notification.isUnread ? (_summary.unreadCount - 1).clamp(0, _summary.unreadCount) : _summary.unreadCount;
      widget.onUnreadCountChanged?.call(nextUnreadCount);
      widget.onNavigateToRoute!(route);
      return;
    }
    final page = _pageForRoute(route);
    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlgili ekran açılamadı. Ana Sayfa üzerinden devam edebilirsiniz.')),
      );
      await _load();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    await _load();
  }

  bool _canNavigateInsideShell(String route) {
    const shellRoutes = {
      'dashboard',
      'finance',
      'customers',
      'inventory',
      'cashflow',
      'reports',
      'business_profile',
      'business-profile',
      'documents',
      'support',
    };
    return shellRoutes.contains(route);
  }

  Widget? _pageForRoute(String route) {
    switch (route) {
      case 'finance':
        return const TransactionsPage();
      case 'customers':
        return const CustomersPage();
      case 'inventory':
        return const InventoryPage();
      case 'cashflow':
        return const CashflowPage();
      case 'documents':
        return const DocumentsPage();
      case 'support':
        return const SupportAnalysisPage();
      case 'reports':
        return const ReportsPage();
      case 'business_profile':
      case 'business-profile':
        return const BusinessProfilePage();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bildirimler',
      subtitle: 'İşletmeniz için önemli hatırlatma ve uyarıları takip edin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
            );
          },
          tooltip: 'Ayarlar',
          icon: const Icon(Icons.tune),
        ),
      ],
      child: _loading
          ? const Center(child: Text('Bildirimler yükleniyor...'))
          : _errorMessage != null
              ? _NotificationsError(message: _errorMessage!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final filtered = _notifications.where(_matchesFilter).toList();
    final archivedCount = _notifications.where((item) => item.isArchived).length;
    return ListView(
      children: [
        SmartCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _summary.unreadCount == 0 ? null : _markAllAsRead,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Tümünü Okundu Yap'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refreshingReminders ? null : _generateReminders,
                    icon: const Icon(Icons.bolt_outlined),
                    label: Text(_refreshingReminders ? 'Yenileniyor...' : 'Hatırlatmaları Yenile'),
                  ),
                ],
              );

              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bildirim Merkezi', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Geciken tahsilat, yaklaşan ödeme, kritik stok, eksik belge ve günlük iş hatırlatmalarınızı burada takip edin.',
                  ),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCompact) ...[
                    intro,
                    const SizedBox(height: 12),
                    actions,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: intro),
                        const SizedBox(width: 12),
                        Flexible(child: actions),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SummaryPill(
                        title: 'Okunmamış',
                        value: '${_summary.unreadCount}',
                        color: AppColors.gold500,
                      ),
                      _SummaryPill(
                        title: 'Kritik',
                        value: '${_summary.criticalCount}',
                        color: AppColors.danger,
                      ),
                      _SummaryPill(
                        title: 'Yüksek Öncelik',
                        value: '${_summary.highPriorityCount}',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(title: 'Okunmamış', value: '${_summary.unreadCount}', color: AppColors.gold500),
            _StatCard(title: 'Kritik', value: '${_summary.criticalCount}', color: AppColors.danger),
            _StatCard(title: 'Bugün', value: '${_summary.todayCount}', color: AppColors.info),
            _StatCard(title: 'Arşivlenen', value: '$archivedCount', color: AppColors.success),
          ],
        ),
        const SizedBox(height: 16),
        SmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Filtreler',
                subtitle: 'Bildirimi türüne ve önemine göre hızlıca daraltın',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters.entries
                    .map(
                      (entry) => ChoiceChip(
                        label: Text(entry.value),
                        selected: _selectedFilter == entry.key,
                        onSelected: (_) => setState(() => _selectedFilter = entry.key),
                      ),
                    )
                    .toList(),
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
                title: 'Bildirim Listesi',
                subtitle: 'Aksiyon alınması gereken uyarılar ve günlük hatırlatmalar',
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                _EmptyNotificationsState(onRefresh: _generateReminders)
              else
                ...filtered.map(
                  (notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      notification: notification,
                      onOpen: () => _openNotification(notification),
                      onRead: notification.isUnread ? () => _markAsRead(notification) : null,
                      onArchive: () => _archive(notification),
                      onDelete: () => _delete(notification),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(AppNotificationModel notification) {
    switch (_selectedFilter) {
      case 'unread':
        return notification.isUnread;
      case 'critical':
        return notification.isCritical;
      case 'all':
        return true;
      default:
        return notification.notificationType == _selectedFilter;
    }
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SmartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onOpen,
    required this.onArchive,
    required this.onDelete,
    this.onRead,
  });

  final AppNotificationModel notification;
  final VoidCallback onOpen;
  final VoidCallback? onRead;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accentColor = _priorityColor(notification.priority);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: notification.isUnread ? AppColors.gold500 : accentColor.withValues(alpha: 0.4),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(notification.notificationType), color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(notification.message),
                  ],
                ),
              ),
              if (notification.isUnread)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Icon(Icons.circle, size: 10, color: AppColors.gold500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: notification.typeLabel, color: AppColors.info),
              _MiniBadge(label: notification.priorityLabel, color: accentColor),
              _MiniBadge(label: notification.statusLabel, color: AppColors.success),
              _MiniBadge(label: notification.displayTime, color: AppColors.info),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: Text(notification.actionLabel ?? 'İlgili Ekrana Git'),
              ),
              if (onRead != null)
                OutlinedButton.icon(
                  onPressed: onRead,
                  icon: const Icon(Icons.done),
                  label: const Text('Okundu Yap'),
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState({
    required this.onRefresh,
  });

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Henüz bildiriminiz yok.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'SmartKOBİ, tahsilat, ödeme, stok ve belge durumlarınıza göre önemli hatırlatmaları burada gösterir.',
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Hatırlatmaları Üret'),
          ),
        ],
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({
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

IconData _iconForType(String type) {
  switch (type) {
    case 'collection':
      return Icons.payments_outlined;
    case 'payment':
      return Icons.account_balance_wallet_outlined;
    case 'inventory':
      return Icons.inventory_2_outlined;
    case 'cashflow':
      return Icons.waterfall_chart_outlined;
    case 'document':
      return Icons.folder_open_outlined;
    case 'support':
      return Icons.workspace_premium_outlined;
    case 'report':
      return Icons.assessment_outlined;
    case 'profile':
      return Icons.business_center_outlined;
    case 'daily_plan':
      return Icons.today_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'critical':
      return AppColors.danger;
    case 'high':
      return AppColors.warning;
    case 'low':
      return AppColors.success;
    default:
      return AppColors.info;
  }
}
