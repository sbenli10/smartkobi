import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/notifications/notification_engine.dart';
import '../models/app_notification_model.dart';
import '../models/device_token_model.dart';
import '../models/notification_preferences_model.dart';
import '../models/notification_summary_model.dart';
import '../services/business_context_service.dart';

class NotificationsRepository {
  NotificationsRepository({
    SupabaseClient? client,
    BusinessContextService? contextService,
  })  : _client = client ?? Supabase.instance.client,
        _contextService = contextService ?? BusinessContextService(client: client);

  final SupabaseClient _client;
  final BusinessContextService _contextService;

  Future<List<AppNotificationModel>> fetchNotifications() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => AppNotificationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Bildirimler alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Bildirimler alınamadı. Lütfen bağlantınızı kontrol edin.');
    }
  }

  Future<List<AppNotificationModel>> fetchUnreadNotifications() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'unread')
          .order('priority', ascending: false)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => AppNotificationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Okunmamış bildirimler alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Okunmamış bildirimler alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<NotificationSummaryModel> fetchNotificationSummary() async {
    final notifications = await fetchNotifications();
    if (notifications.isEmpty) {
      return NotificationSummaryModel.empty();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCount = notifications.where((item) {
      final itemDay = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      return itemDay == today;
    }).length;
    return NotificationSummaryModel(
      totalCount: notifications.length,
      unreadCount: notifications.where((item) => item.isUnread).length,
      criticalCount: notifications.where((item) => item.isCritical).length,
      highPriorityCount: notifications.where((item) => item.isHighPriority).length,
      todayCount: todayCount,
      expiredCount: notifications.where((item) => item.isExpired).length,
      latestNotifications: notifications.take(5).toList(),
    );
  }

  Future<AppNotificationModel> createNotification(AppNotificationModel notification) async {
    final user = _requireUser();
    try {
      final payload = notification.copyWith(
        userId: user.id,
        updatedAt: DateTime.now(),
      ).toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      final data = await _client.from('notifications').insert(payload).select().single();
      return AppNotificationModel.fromJson(data);
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        throw Exception('Bildirim altyapısı henüz hazır değil. Migration dosyalarını uygulayın.');
      }
      throw Exception('Bildirim oluşturulamadı. ${error.message}');
    } catch (_) {
      throw Exception('Bildirim oluşturulamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _requireUser();
    try {
      await _client
          .from('notifications')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw Exception('Bildirim güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Bildirim güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> markAllAsRead() async {
    final user = _requireUser();
    try {
      await _client
          .from('notifications')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('status', 'unread');
    } on PostgrestException catch (error) {
      throw Exception('Bildirimler güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Bildirimler güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    await _updateStatus(notificationId, 'archived');
  }

  Future<void> dismissNotification(String notificationId) async {
    await _updateStatus(notificationId, 'dismissed');
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _requireUser();
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw Exception('Bildirim silinemedi. ${error.message}');
    } catch (_) {
      throw Exception('Bildirim silinemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deleteExpiredNotifications() async {
    final user = _requireUser();
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .lt('expires_at', DateTime.now().toIso8601String());
    } on PostgrestException catch (error) {
      throw Exception('Süresi dolan bildirimler temizlenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Süresi dolan bildirimler temizlenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<int> getUnreadCount() async {
    final unread = await fetchUnreadNotifications();
    return unread.length;
  }

  Future<NotificationPreferencesModel> fetchPreferences() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (data == null) {
        return NotificationPreferencesModel.defaults(user.id);
      }
      return NotificationPreferencesModel.fromJson(data);
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        return NotificationPreferencesModel.defaults(user.id);
      }
      throw Exception('Bildirim tercihleri alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Bildirim tercihleri alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<NotificationPreferencesModel> upsertPreferences(
    NotificationPreferencesModel preferences,
  ) async {
    final user = _requireUser();
    try {
      final payload = preferences.copyWith(
        userId: user.id,
        updatedAt: DateTime.now(),
      ).toJson()
        ..remove('created_at')
        ..remove('updated_at');
      final data = await _client
          .from('notification_preferences')
          .upsert(payload, onConflict: 'user_id')
          .select()
          .single();
      return NotificationPreferencesModel.fromJson(data);
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        throw Exception('Bildirim tercihleri altyapısı henüz hazır değil.');
      }
      throw Exception('Bildirim tercihleri kaydedilemedi. ${error.message}');
    } catch (_) {
      throw Exception('Bildirim tercihleri kaydedilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    final user = _requireUser();
    try {
      await _client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'device_name': deviceName,
        'app_version': appVersion,
        'is_active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        return;
      }
      throw Exception('Cihaz bildirimi kaydedilemedi. ${error.message}');
    } catch (_) {
      throw Exception('Cihaz bildirimi kaydedilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deactivateDeviceToken(String token) async {
    final user = _requireUser();
    try {
      await _client
          .from('device_tokens')
          .update({
            'is_active': false,
            'last_seen_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('token', token);
    } on PostgrestException catch (error) {
      throw Exception('Cihaz bildirimi devre dışı bırakılamadı. ${error.message}');
    } catch (_) {
      throw Exception('Cihaz bildirimi devre dışı bırakılamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<DeviceTokenModel>> fetchDeviceTokens() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('device_tokens')
          .select()
          .eq('user_id', user.id)
          .order('last_seen_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => DeviceTokenModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        return const [];
      }
      throw Exception('Cihaz listesi alınamadı. ${error.message}');
    } catch (_) {
      throw Exception('Cihaz listesi alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<List<AppNotificationModel>> generateSmartReminders() async {
    final user = _requireUser();
    final preferences = await fetchPreferences();
    if (!preferences.inAppEnabled) {
      return const [];
    }

    final snapshot = await _buildSnapshot(user.id);
    final drafts = await buildSmartReminderDrafts(
      userId: user.id,
      snapshot: snapshot,
      preferences: preferences,
    );
    if (drafts.isEmpty) {
      return const [];
    }

    final existing = await _fetchRecentNotifications();
    final existingKeys = existing
        .map((item) => '${item.metadata['rule_key'] ?? ''}:${item.metadata['generated_date'] ?? ''}')
        .toSet();

    return drafts
        .where((draft) {
          final key =
              '${draft.metadata['rule_key'] ?? ''}:${draft.metadata['generated_date'] ?? ''}';
          return key.trim().isNotEmpty && !existingKeys.contains(key);
        })
        .map(
          (draft) => AppNotificationModel(
            id: '',
            userId: user.id,
            businessId: null,
            title: draft.title,
            message: draft.message,
            notificationType: draft.notificationType,
            priority: draft.priority,
            status: 'unread',
            sourceModule: draft.sourceModule,
            sourceId: draft.sourceId,
            actionRoute: draft.actionRoute,
            actionLabel: draft.actionLabel,
            metadata: draft.metadata,
            scheduledFor: draft.scheduledFor,
            expiresAt: draft.expiresAt,
            readAt: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> generateAndSaveSmartReminders() async {
    final notifications = await generateSmartReminders();
    for (final notification in notifications) {
      await createNotification(notification);
    }
  }

  Future<void> _updateStatus(String notificationId, String status) async {
    final user = _requireUser();
    try {
      await _client
          .from('notifications')
          .update({'status': status})
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw Exception('Bildirim güncellenemedi. ${error.message}');
    } catch (_) {
      throw Exception('Bildirim güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<List<AppNotificationModel>> _fetchRecentNotifications() async {
    final user = _requireUser();
    try {
      final since = DateTime.now().subtract(const Duration(days: 14));
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((row) => AppNotificationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isNotificationsTablesMissing(error)) {
        return const [];
      }
      rethrow;
    }
  }

  Future<NotificationDataSnapshot> _buildSnapshot(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next3Days = today.add(const Duration(days: 3));
    final next7Days = today.add(const Duration(days: 7));
    final next30Days = today.add(const Duration(days: 30));

    var overdueCollectionCount = 0;
    var upcomingCollectionCount = 0;
    var upcomingPaymentCount = 0;
    var criticalStockCount = 0;
    var outOfStockCount = 0;
    var expiringDocumentCount = 0;
    var expiredDocumentCount = 0;
    var highPriorityMissingDocumentCount = 0;
    var hasSupportAnalysis = false;
    DateTime? supportAnalysisUpdatedAt;
    var profileCompletion = 0;
    var hasRecentReport = false;
    DateTime? latestDailyPlanDate;

    try {
      final rows = await _client
          .from('customer_transactions')
          .select('payment_status,due_date,type')
          .eq('user_id', userId)
          .eq('type', 'receivable');
      for (final item in rows as List<dynamic>) {
        final row = item as Map<String, dynamic>;
        final status = row['payment_status']?.toString() ?? 'pending';
        final dueDate = DateTime.tryParse(row['due_date']?.toString() ?? '');
        if (status == 'overdue' || (status == 'pending' && dueDate != null && dueDate.isBefore(today))) {
          overdueCollectionCount += 1;
        }
        if (status == 'pending' &&
            dueDate != null &&
            !dueDate.isBefore(today) &&
            !dueDate.isAfter(next3Days)) {
          upcomingCollectionCount += 1;
        }
      }
    } catch (_) {}

    try {
      final rows = await _client
          .from('cashflow_entries')
          .select('entry_type,expected_date,status')
          .eq('user_id', userId)
          .eq('entry_type', 'outflow');
      for (final item in rows as List<dynamic>) {
        final row = item as Map<String, dynamic>;
        final expectedDate = DateTime.tryParse(row['expected_date']?.toString() ?? '');
        final status = row['status']?.toString() ?? '';
        if (expectedDate != null &&
            !expectedDate.isBefore(today) &&
            !expectedDate.isAfter(next7Days) &&
            status != 'paid') {
          upcomingPaymentCount += 1;
        }
      }
    } catch (_) {}

    final context = await _contextService.buildContextSummary();

    try {
      final rows = await _client
          .from('inventory_items')
          .select('stock_quantity,min_stock_level')
          .eq('user_id', userId);
      for (final item in rows as List<dynamic>) {
        final row = item as Map<String, dynamic>;
        final quantity = (row['stock_quantity'] as num?)?.toDouble() ?? 0;
        final minLevel = (row['min_stock_level'] as num?)?.toDouble() ?? 0;
        if (quantity <= minLevel) {
          criticalStockCount += 1;
        }
        if (quantity <= 0) {
          outOfStockCount += 1;
        }
      }
    } catch (_) {}

    try {
      final rows = await _client
          .from('business_documents')
          .select('expiry_date')
          .eq('user_id', userId);
      for (final item in rows as List<dynamic>) {
        final row = item as Map<String, dynamic>;
        final expiryDate = DateTime.tryParse(row['expiry_date']?.toString() ?? '');
        if (expiryDate == null) {
          continue;
        }
        if (expiryDate.isBefore(today)) {
          expiredDocumentCount += 1;
        } else if (!expiryDate.isAfter(next30Days)) {
          expiringDocumentCount += 1;
        }
      }
    } catch (_) {}

    try {
      final rows = await _client
          .from('document_requirements')
          .select('status,priority')
          .eq('user_id', userId)
          .eq('status', 'missing')
          .eq('priority', 'high');
      highPriorityMissingDocumentCount = (rows as List<dynamic>).length;
    } catch (_) {}

    try {
      final data = await _client
          .from('support_analysis_results')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data != null) {
        hasSupportAnalysis = true;
        supportAnalysisUpdatedAt = DateTime.tryParse(data['created_at']?.toString() ?? '');
      }
    } catch (_) {}

    try {
      final data = await _client
          .from('business_profiles')
          .select('profile_completion')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      if (data != null) {
        profileCompletion = (data['profile_completion'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    try {
      final since = now.subtract(const Duration(days: 7));
      final rows = await _client
          .from('business_reports')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .limit(1);
      hasRecentReport = (rows as List<dynamic>).isNotEmpty;
    } catch (_) {}

    try {
      final data = await _client
          .from('notifications')
          .select('created_at')
          .eq('user_id', userId)
          .eq('notification_type', 'daily_plan')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data != null) {
        latestDailyPlanDate = DateTime.tryParse(data['created_at']?.toString() ?? '');
      }
    } catch (_) {}

    return NotificationDataSnapshot(
      overdueCollectionCount: overdueCollectionCount,
      upcomingCollectionCount: upcomingCollectionCount,
      upcomingPaymentCount: upcomingPaymentCount,
      cashScore: context.cashScore,
      netCash30d: context.netCash30d,
      criticalStockCount: criticalStockCount,
      outOfStockCount: outOfStockCount,
      expiringDocumentCount: expiringDocumentCount,
      expiredDocumentCount: expiredDocumentCount,
      highPriorityMissingDocumentCount: highPriorityMissingDocumentCount,
      hasSupportAnalysis: hasSupportAnalysis,
      supportAnalysisUpdatedAt: supportAnalysisUpdatedAt,
      profileCompletion: profileCompletion > 0 ? profileCompletion : context.profileCompletion,
      hasRecentReport: hasRecentReport,
      latestDailyPlanDate: latestDailyPlanDate,
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  bool _isNotificationsTablesMissing(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains('notifications') ||
        message.contains('notification_preferences') ||
        message.contains('device_tokens');
  }
}
