class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.priority,
    required this.status,
    this.sourceModule,
    this.sourceId,
    this.actionRoute,
    this.actionLabel,
    required this.metadata,
    this.scheduledFor,
    this.expiresAt,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String title;
  final String message;
  final String notificationType;
  final String priority;
  final String status;
  final String? sourceModule;
  final String? sourceId;
  final String? actionRoute;
  final String? actionLabel;
  final Map<String, dynamic> metadata;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get typeLabel => _typeLabels[notificationType] ?? 'Genel';

  String get priorityLabel => _priorityLabels[priority] ?? 'Orta';

  String get statusLabel => _statusLabels[status] ?? 'Bilinmiyor';

  bool get isUnread => status == 'unread';

  bool get isRead => status == 'read';

  bool get isArchived => status == 'archived';

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isHighPriority => priority == 'high' || priority == 'critical';

  bool get isCritical => priority == 'critical';

  String get displayTime {
    final target = scheduledFor ?? createdAt;
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    final difference = targetDay.difference(dayStart).inDays;
    final hour = target.hour.toString().padLeft(2, '0');
    final minute = target.minute.toString().padLeft(2, '0');
    if (difference == 0) {
      return 'Bugün $hour:$minute';
    }
    if (difference == -1) {
      return 'Dün $hour:$minute';
    }
    if (difference == 1) {
      return 'Yarın $hour:$minute';
    }
    final day = target.day.toString().padLeft(2, '0');
    final month = target.month.toString().padLeft(2, '0');
    return '$day.$month.${target.year} $hour:$minute';
  }

  AppNotificationModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    bool clearBusinessId = false,
    String? title,
    String? message,
    String? notificationType,
    String? priority,
    String? status,
    String? sourceModule,
    bool clearSourceModule = false,
    String? sourceId,
    bool clearSourceId = false,
    String? actionRoute,
    bool clearActionRoute = false,
    String? actionLabel,
    bool clearActionLabel = false,
    Map<String, dynamic>? metadata,
    DateTime? scheduledFor,
    bool clearScheduledFor = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    DateTime? readAt,
    bool clearReadAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      sourceModule: clearSourceModule ? null : sourceModule ?? this.sourceModule,
      sourceId: clearSourceId ? null : sourceId ?? this.sourceId,
      actionRoute: clearActionRoute ? null : actionRoute ?? this.actionRoute,
      actionLabel: clearActionLabel ? null : actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
      scheduledFor: clearScheduledFor ? null : scheduledFor ?? this.scheduledFor,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
      readAt: clearReadAt ? null : readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessId: json['business_id']?.toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? 'system',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'unread',
      sourceModule: json['source_module']?.toString(),
      sourceId: json['source_id']?.toString(),
      actionRoute: json['action_route']?.toString(),
      actionLabel: json['action_label']?.toString(),
      metadata: _parseMap(json['metadata']),
      scheduledFor: _parseNullableDateTime(json['scheduled_for']),
      expiresAt: _parseNullableDateTime(json['expires_at']),
      readAt: _parseNullableDateTime(json['read_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'priority': priority,
      'status': status,
      'source_module': sourceModule,
      'source_id': sourceId,
      'action_route': actionRoute,
      'action_label': actionLabel,
      'metadata': metadata,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

const Map<String, String> _typeLabels = {
  'collection': 'Tahsilat',
  'payment': 'Ödeme',
  'inventory': 'Stok',
  'cashflow': 'Nakit Akışı',
  'document': 'Belge',
  'support': 'Destek',
  'report': 'Rapor',
  'profile': 'Profil',
  'daily_plan': 'Günlük Plan',
  'system': 'Sistem',
};

const Map<String, String> _priorityLabels = {
  'low': 'Düşük öncelik',
  'medium': 'Orta öncelik',
  'high': 'Yüksek öncelik',
  'critical': 'Kritik',
};

const Map<String, String> _statusLabels = {
  'unread': 'Okunmadı',
  'read': 'Okundu',
  'archived': 'Arşivlendi',
  'dismissed': 'Kapatıldı',
};

Map<String, dynamic> _parseMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
