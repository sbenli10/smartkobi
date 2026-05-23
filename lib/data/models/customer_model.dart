import 'package:intl/intl.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.taxNumber,
    this.address,
    this.city,
    required this.openingBalance,
    required this.currentBalance,
    required this.riskLevel,
    required this.paymentTermDays,
    this.lastTransactionDate,
    this.nextCollectionDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? taxNumber;
  final String? address;
  final String? city;
  final double openingBalance;
  final double currentBalance;
  final String riskLevel;
  final int paymentTermDays;
  final DateTime? lastTransactionDate;
  final DateTime? nextCollectionDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isHighRisk => riskLevel == 'high';
  bool get isMediumRisk => riskLevel == 'medium';
  bool get hasOverdueCollection =>
      nextCollectionDate != null &&
      nextCollectionDate!.isBefore(DateTime.now()) &&
      currentBalance > 0;
  String get displayBalance =>
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(currentBalance);

  CustomerModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? taxNumber,
    String? address,
    String? city,
    double? openingBalance,
    double? currentBalance,
    String? riskLevel,
    int? paymentTermDays,
    DateTime? lastTransactionDate,
    DateTime? nextCollectionDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearLastTransactionDate = false,
    bool clearNextCollectionDate = false,
    bool clearNotes = false,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxNumber: taxNumber ?? this.taxNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      riskLevel: riskLevel ?? this.riskLevel,
      paymentTermDays: paymentTermDays ?? this.paymentTermDays,
      lastTransactionDate: clearLastTransactionDate
          ? null
          : lastTransactionDate ?? this.lastTransactionDate,
      nextCollectionDate: clearNextCollectionDate
          ? null
          : nextCollectionDate ?? this.nextCollectionDate,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      name: (json['name'] ?? '') as String,
      contactName: json['contact_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      taxNumber: json['tax_number'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      riskLevel: (json['risk_level'] ?? 'low') as String,
      paymentTermDays: (json['payment_term_days'] as num?)?.toInt() ?? 30,
      lastTransactionDate: _parseDate(json['last_transaction_date']),
      nextCollectionDate: _parseDate(json['next_collection_date']),
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'name': name,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'tax_number': taxNumber,
      'address': address,
      'city': city,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'risk_level': riskLevel,
      'payment_term_days': paymentTermDays,
      'last_transaction_date': lastTransactionDate?.toIso8601String().split('T').first,
      'next_collection_date': nextCollectionDate?.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
