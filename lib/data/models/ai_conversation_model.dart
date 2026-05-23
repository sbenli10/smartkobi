class AiConversationModel {
  const AiConversationModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.title,
    required this.topic,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String title;
  final String topic;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversationModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? title,
    String? topic,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearLastMessagePreview = false,
    bool clearLastMessageAt = false,
  }) {
    return AiConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      lastMessagePreview: clearLastMessagePreview
          ? null
          : lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: clearLastMessageAt ? null : lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AiConversationModel.fromJson(Map<String, dynamic> json) {
    return AiConversationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessId: json['business_id']?.toString(),
      title: json['title']?.toString() ?? 'Yeni Danışman Görüşmesi',
      topic: json['topic']?.toString() ?? 'general',
      lastMessagePreview: json['last_message_preview']?.toString(),
      lastMessageAt: DateTime.tryParse(json['last_message_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'title': title,
      'topic': topic,
      'last_message_preview': lastMessagePreview,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
