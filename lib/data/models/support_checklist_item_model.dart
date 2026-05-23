class SupportChecklistItemModel {
  const SupportChecklistItemModel({
    required this.id,
    required this.userId,
    this.analysisResultId,
    required this.title,
    this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? analysisResultId;
  final String title;
  final String? description;
  final String category;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  String get categoryLabel {
    switch (category) {
      case 'profile':
        return 'Profil';
      case 'document':
        return 'Belge';
      case 'finance':
        return 'Finans';
      case 'project':
        return 'Proje';
      case 'application':
        return 'Başvuru';
      default:
        return 'Genel';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'Yüksek';
      case 'low':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  SupportChecklistItemModel copyWith({
    String? id,
    String? userId,
    String? analysisResultId,
    bool clearAnalysisResultId = false,
    String? title,
    String? description,
    bool clearDescription = false,
    String? category,
    String? status,
    String? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportChecklistItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      analysisResultId:
          clearAnalysisResultId ? null : analysisResultId ?? this.analysisResultId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SupportChecklistItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return SupportChecklistItemModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      analysisResultId: json['analysis_result_id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'general',
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority']?.toString() ?? 'medium',
      dueDate: json['due_date'] == null ? null : parseDate(json['due_date']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'analysis_result_id': analysisResultId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
