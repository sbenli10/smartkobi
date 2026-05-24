class CollectionReminderModel {
  final String id;
  final String userId;
  final String? businessId;
  final String? customerId;
  final String? customerTransactionId;
  final String reminderType;
  final String tone;
  final String title;
  final String message;
  final double? amount;
  final DateTime? dueDate;
  final String status;
  final String? phoneNumber;
  final String? whatsappUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollectionReminderModel({
    required this.id,
    required this.userId,
    this.businessId,
    this.customerId,
    this.customerTransactionId,
    required this.reminderType,
    required this.tone,
    required this.title,
    required this.message,
    this.amount,
    this.dueDate,
    required this.status,
    this.phoneNumber,
    this.whatsappUrl,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isCopied => status == 'copied';
  bool get isOpenedWhatsapp => status == 'opened_whatsapp';

  String get toneLabel {
    switch (tone) {
      case 'polite': return 'Kibar';
      case 'clear': return 'Net';
      case 'formal': return 'Resmi';
      case 'reminder': return 'Hatırlatma';
      default: return 'Bilinmiyor';
    }
  }

  factory CollectionReminderModel.fromJson(Map<String, dynamic> json) {
    return CollectionReminderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      customerId: json['customer_id'] as String?,
      customerTransactionId: json['customer_transaction_id'] as String?,
      reminderType: json['reminder_type'] as String? ?? 'whatsapp',
      tone: json['tone'] as String? ?? 'polite',
      title: json['title'] as String,
      message: json['message'] as String,
      amount: json['amount'] != null ? double.parse(json['amount'].toString()) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'].toString()) : null,
      status: json['status'] as String? ?? 'draft',
      phoneNumber: json['phone_number'] as String?,
      whatsappUrl: json['whatsapp_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      if (businessId != null) 'business_id': businessId,
      if (customerId != null) 'customer_id': customerId,
      if (customerTransactionId != null) 'customer_transaction_id': customerTransactionId,
      'reminder_type': reminderType,
      'tone': tone,
      'title': title,
      'message': message,
      if (amount != null) 'amount': amount,
      if (dueDate != null) 'due_date': dueDate?.toIso8601String(),
      'status': status,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (whatsappUrl != null) 'whatsapp_url': whatsappUrl,
      'metadata': metadata,
    };
  }

  CollectionReminderModel copyWith({String? status, String? message}) {
    return CollectionReminderModel(
      id: id,
      userId: userId,
      businessId: businessId,
      customerId: customerId,
      customerTransactionId: customerTransactionId,
      reminderType: reminderType,
      tone: tone,
      title: title,
      message: message ?? this.message,
      amount: amount,
      dueDate: dueDate,
      status: status ?? this.status,
      phoneNumber: phoneNumber,
      whatsappUrl: whatsappUrl,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}