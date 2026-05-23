class DeviceTokenModel {
  const DeviceTokenModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    this.deviceName,
    this.appVersion,
    required this.isActive,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String token;
  final String platform;
  final String? deviceName;
  final String? appVersion;
  final bool isActive;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'unknown',
      deviceName: json['device_name']?.toString(),
      appVersion: json['app_version']?.toString(),
      isActive: json['is_active'] != false,
      lastSeenAt: _parseDateTime(json['last_seen_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'platform': platform,
      'device_name': deviceName,
      'app_version': appVersion,
      'is_active': isActive,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
