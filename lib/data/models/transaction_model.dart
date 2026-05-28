import 'package:intl/intl.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    this.contactName,
    required this.transactionDate,
    required this.paymentStatus,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String type;
  final String title;
  final String category;
  final double amount;
  final String? contactName;
  final DateTime transactionDate;
  final String paymentStatus;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  String get formattedAmount =>
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount);

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? type,
    String? title,
    String? category,
    double? amount,
    String? contactName,
    DateTime? transactionDate,
    String? paymentStatus,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearContactName = false,
    bool clearDescription = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      contactName: clearContactName ? null : contactName ?? this.contactName,
      transactionDate: transactionDate ?? this.transactionDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      description: clearDescription ? null : description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      contactName: json['contact_name'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      paymentStatus: json['payment_status'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'contact_name': contactName,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'payment_status': paymentStatus,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
