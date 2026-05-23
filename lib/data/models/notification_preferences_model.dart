class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    required this.id,
    required this.userId,
    required this.collectionEnabled,
    required this.paymentEnabled,
    required this.inventoryEnabled,
    required this.cashflowEnabled,
    required this.documentEnabled,
    required this.supportEnabled,
    required this.reportEnabled,
    required this.profileEnabled,
    required this.dailyPlanEnabled,
    required this.dailyPlanTime,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.inAppEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final bool collectionEnabled;
  final bool paymentEnabled;
  final bool inventoryEnabled;
  final bool cashflowEnabled;
  final bool documentEnabled;
  final bool supportEnabled;
  final bool reportEnabled;
  final bool profileEnabled;
  final bool dailyPlanEnabled;
  final String dailyPlanTime;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferencesModel copyWith({
    String? id,
    String? userId,
    bool? collectionEnabled,
    bool? paymentEnabled,
    bool? inventoryEnabled,
    bool? cashflowEnabled,
    bool? documentEnabled,
    bool? supportEnabled,
    bool? reportEnabled,
    bool? profileEnabled,
    bool? dailyPlanEnabled,
    String? dailyPlanTime,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    String? quietHoursStart,
    bool clearQuietHoursStart = false,
    String? quietHoursEnd,
    bool clearQuietHoursEnd = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      collectionEnabled: collectionEnabled ?? this.collectionEnabled,
      paymentEnabled: paymentEnabled ?? this.paymentEnabled,
      inventoryEnabled: inventoryEnabled ?? this.inventoryEnabled,
      cashflowEnabled: cashflowEnabled ?? this.cashflowEnabled,
      documentEnabled: documentEnabled ?? this.documentEnabled,
      supportEnabled: supportEnabled ?? this.supportEnabled,
      reportEnabled: reportEnabled ?? this.reportEnabled,
      profileEnabled: profileEnabled ?? this.profileEnabled,
      dailyPlanEnabled: dailyPlanEnabled ?? this.dailyPlanEnabled,
      dailyPlanTime: dailyPlanTime ?? this.dailyPlanTime,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      quietHoursStart: clearQuietHoursStart ? null : quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: clearQuietHoursEnd ? null : quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      collectionEnabled: json['collection_enabled'] != false,
      paymentEnabled: json['payment_enabled'] != false,
      inventoryEnabled: json['inventory_enabled'] != false,
      cashflowEnabled: json['cashflow_enabled'] != false,
      documentEnabled: json['document_enabled'] != false,
      supportEnabled: json['support_enabled'] != false,
      reportEnabled: json['report_enabled'] != false,
      profileEnabled: json['profile_enabled'] != false,
      dailyPlanEnabled: json['daily_plan_enabled'] != false,
      dailyPlanTime: json['daily_plan_time']?.toString() ?? '09:00',
      pushEnabled: json['push_enabled'] == true,
      emailEnabled: json['email_enabled'] == true,
      inAppEnabled: json['in_app_enabled'] != false,
      quietHoursStart: json['quiet_hours_start']?.toString(),
      quietHoursEnd: json['quiet_hours_end']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'collection_enabled': collectionEnabled,
      'payment_enabled': paymentEnabled,
      'inventory_enabled': inventoryEnabled,
      'cashflow_enabled': cashflowEnabled,
      'document_enabled': documentEnabled,
      'support_enabled': supportEnabled,
      'report_enabled': reportEnabled,
      'profile_enabled': profileEnabled,
      'daily_plan_enabled': dailyPlanEnabled,
      'daily_plan_time': dailyPlanTime,
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'in_app_enabled': inAppEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotificationPreferencesModel.defaults(String userId) {
    final now = DateTime.now();
    return NotificationPreferencesModel(
      id: '',
      userId: userId,
      collectionEnabled: true,
      paymentEnabled: true,
      inventoryEnabled: true,
      cashflowEnabled: true,
      documentEnabled: true,
      supportEnabled: true,
      reportEnabled: true,
      profileEnabled: true,
      dailyPlanEnabled: true,
      dailyPlanTime: '09:00',
      pushEnabled: false,
      emailEnabled: false,
      inAppEnabled: true,
      quietHoursStart: null,
      quietHoursEnd: null,
      createdAt: now,
      updatedAt: now,
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
