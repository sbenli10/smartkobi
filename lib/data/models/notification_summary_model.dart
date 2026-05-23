import 'app_notification_model.dart';

class NotificationSummaryModel {
  const NotificationSummaryModel({
    required this.totalCount,
    required this.unreadCount,
    required this.criticalCount,
    required this.highPriorityCount,
    required this.todayCount,
    required this.expiredCount,
    required this.latestNotifications,
  });

  final int totalCount;
  final int unreadCount;
  final int criticalCount;
  final int highPriorityCount;
  final int todayCount;
  final int expiredCount;
  final List<AppNotificationModel> latestNotifications;

  factory NotificationSummaryModel.empty() {
    return const NotificationSummaryModel(
      totalCount: 0,
      unreadCount: 0,
      criticalCount: 0,
      highPriorityCount: 0,
      todayCount: 0,
      expiredCount: 0,
      latestNotifications: [],
    );
  }
}
