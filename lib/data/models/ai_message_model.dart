class AiMessageModel {
  const AiMessageModel({
    required this.id,
    required this.userId,
    required this.conversationId,
    this.businessId,
    required this.role,
    required this.content,
    required this.messageType,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String conversationId;
  final String? businessId;
  final String role;
  final String content;
  final String messageType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
  bool get isWarning => messageType == 'warning';
  bool get isAction => messageType == 'action';

  AiMessageModel copyWith({
    String? id,
    String? userId,
    String? conversationId,
    String? businessId,
    String? role,
    String? content,
    String? messageType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool clearBusinessId = false,
  }) {
    return AiMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      role: role ?? this.role,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return AiMessageModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      businessId: json['business_id']?.toString(),
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
              ? Map<String, dynamic>.from(rawMetadata)
              : const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'conversation_id': conversationId,
      'business_id': businessId,
      'role': role,
      'content': content,
      'message_type': messageType,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
