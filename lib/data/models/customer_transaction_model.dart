class CustomerTransactionModel {
  const CustomerTransactionModel({
    required this.id,
    required this.userId,
    required this.customerId,
    this.businessId,
    required this.type,
    required this.title,
    required this.amount,
    required this.transactionDate,
    this.dueDate,
    required this.paymentStatus,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String customerId;
  final String? businessId;
  final String type;
  final String title;
  final double amount;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final String paymentStatus;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReceivable => type == 'receivable';
  bool get isPayment => type == 'payment';
  bool get isOverdue =>
      paymentStatus == 'overdue' ||
      (paymentStatus != 'paid' &&
          dueDate != null &&
          dueDate!.isBefore(DateTime.now()));
  bool get isPaid => paymentStatus == 'paid';

  CustomerTransactionModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? businessId,
    String? type,
    String? title,
    double? amount,
    DateTime? transactionDate,
    DateTime? dueDate,
    String? paymentStatus,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearDueDate = false,
    bool clearDescription = false,
  }) {
    return CustomerTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      description: clearDescription ? null : description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerTransactionModel.fromJson(Map<String, dynamic> json) {
    return CustomerTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      customerId: json['customer_id'] as String,
      businessId: json['business_id'] as String?,
      type: (json['type'] ?? 'receivable') as String,
      title: (json['title'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      transactionDate: DateTime.tryParse(json['transaction_date']?.toString() ?? '') ??
          DateTime.now(),
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
      paymentStatus: (json['payment_status'] ?? 'pending') as String,
      description: json['description'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'business_id': businessId,
      'type': type,
      'title': title,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'payment_status': paymentStatus,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
