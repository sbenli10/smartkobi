import '../repositories/notifications_repository.dart';

class PushNotificationService {
  PushNotificationService({
    NotificationsRepository? notificationsRepository,
  }) : _notificationsRepository = notificationsRepository ?? NotificationsRepository();

  final NotificationsRepository _notificationsRepository;

  Future<void> initialize() async {
    // TODO(FCM): Firebase Messaging paketi eklendiğinde gerçek push başlatma akışı burada kurulacak.
  }

  Future<void> requestPermission() async {
    // TODO(FCM): Firebase Messaging paketi eklendiğinde bildirim izinleri burada istenecek.
  }

  Future<String?> getDeviceToken() async {
    // TODO(FCM): Firebase Messaging paketi eklendiğinde gerçek FCM token burada alınacak.
    return null;
  }

  Future<void> registerCurrentDeviceToken() async {
    final token = await getDeviceToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }
    await _notificationsRepository.registerDeviceToken(
      token: token,
      platform: 'unknown',
    );
  }
}
