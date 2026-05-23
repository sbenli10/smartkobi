class CashflowEntryModel {
  const CashflowEntryModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.sourceType,
    this.sourceId,
    required this.entryType,
    required this.title,
    this.category,
    required this.amount,
    required this.expectedDate,
    required this.status,
    this.recurrence,
    required this.confidenceLevel,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String sourceType;
  final String? sourceId;
  final String entryType;
  final String title;
  final String? category;
  final double amount;
  final DateTime expectedDate;
  final String status;
  final String? recurrence;
  final String confidenceLevel;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isInflow => entryType == 'inflow';
  bool get isOutflow => entryType == 'outflow';
  bool get isOverdue =>
      status == 'overdue' ||
      ((status == 'expected' || status == 'confirmed') &&
          expectedDate.isBefore(DateTime.now()));
  bool get isPaid => status == 'paid';
  bool get isExpected => status == 'expected' || status == 'confirmed';

  CashflowEntryModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? sourceType,
    String? sourceId,
    String? entryType,
    String? title,
    String? category,
    double? amount,
    DateTime? expectedDate,
    String? status,
    String? recurrence,
    String? confidenceLevel,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearSourceId = false,
    bool clearCategory = false,
    bool clearRecurrence = false,
    bool clearDescription = false,
  }) {
    return CashflowEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: clearSourceId ? null : sourceId ?? this.sourceId,
      entryType: entryType ?? this.entryType,
      title: title ?? this.title,
      category: clearCategory ? null : category ?? this.category,
      amount: amount ?? this.amount,
      expectedDate: expectedDate ?? this.expectedDate,
      status: status ?? this.status,
      recurrence: clearRecurrence ? null : recurrence ?? this.recurrence,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      description: clearDescription ? null : description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CashflowEntryModel.fromJson(Map<String, dynamic> json) {
    return CashflowEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      sourceType: (json['source_type'] ?? 'manual') as String,
      sourceId: json['source_id']?.toString(),
      entryType: (json['entry_type'] ?? 'inflow') as String,
      title: (json['title'] ?? '') as String,
      category: json['category'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      expectedDate:
          DateTime.tryParse(json['expected_date']?.toString() ?? '') ?? DateTime.now(),
      status: (json['status'] ?? 'expected') as String,
      recurrence: json['recurrence'] as String?,
      confidenceLevel: (json['confidence_level'] ?? 'medium') as String,
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'source_type': sourceType,
      'source_id': sourceId,
      'entry_type': entryType,
      'title': title,
      'category': category,
      'amount': amount,
      'expected_date': expectedDate.toIso8601String().split('T').first,
      'status': status,
      'recurrence': recurrence,
      'confidence_level': confidenceLevel,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
