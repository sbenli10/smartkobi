class DraftTransactionModel {
  const DraftTransactionModel({
    required this.operation,
    required this.transactionType,
    required this.amount,
    required this.contact,
    required this.category,
    required this.title,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalAmount,
    required this.stockDelta,
    required this.needsProductMatch,
    required this.needsConfirmation,
    required this.confidence,
    required this.rawText,
  });

  final String operation;
  final String transactionType;
  final double amount;
  final String contact;
  final String category;
  final String title;
  final String productName;
  final double? quantity;
  final String unit;
  final double? unitPrice;
  final double? totalAmount;
  final double stockDelta;
  final bool needsProductMatch;
  final bool needsConfirmation;
  final double confidence;
  final String rawText;

  String get type => transactionType;
  bool get isProductOperation => operation == 'product_sale' || operation == 'product_purchase';
  bool get isProductSale => operation == 'product_sale';
  bool get isProductPurchase => operation == 'product_purchase';
  bool get isFinanceOnly => !isProductOperation;

  DraftTransactionModel copyWith({
    String? operation,
    String? transactionType,
    double? amount,
    String? contact,
    String? category,
    String? title,
    String? productName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalAmount,
    double? stockDelta,
    bool? needsProductMatch,
    bool? needsConfirmation,
    double? confidence,
    String? rawText,
    bool clearQuantity = false,
    bool clearUnitPrice = false,
    bool clearTotalAmount = false,
  }) {
    return DraftTransactionModel(
      operation: operation ?? this.operation,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      contact: contact ?? this.contact,
      category: category ?? this.category,
      title: title ?? this.title,
      productName: productName ?? this.productName,
      quantity: clearQuantity ? null : quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
      totalAmount: clearTotalAmount ? null : totalAmount ?? this.totalAmount,
      stockDelta: stockDelta ?? this.stockDelta,
      needsProductMatch: needsProductMatch ?? this.needsProductMatch,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }

  factory DraftTransactionModel.fromJson(Map<String, dynamic> json) {
    final transactionType = (json['transactionType'] ?? json['type'] ?? '').toString();
    final totalAmount = _parseNullableAmount(json['totalAmount']);
    final amount = _parseAmount(json['amount']) ?? totalAmount ?? 0;

    return DraftTransactionModel(
      operation: (json['operation'] ?? transactionType).toString(),
      transactionType: transactionType,
      amount: amount,
      contact: (json['contact'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      quantity: _parseNullableAmount(json['quantity']),
      unit: (json['unit'] ?? 'adet').toString(),
      unitPrice: _parseNullableAmount(json['unitPrice']),
      totalAmount: totalAmount,
      stockDelta: _parseAmount(json['stockDelta']) ?? 0,
      needsProductMatch: json['needsProductMatch'] as bool? ?? false,
      needsConfirmation: json['needsConfirmation'] as bool? ?? true,
      confidence: _parseAmount(json['confidence']) ?? 0,
      rawText: (json['rawText'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'transactionType': transactionType,
      'amount': amount,
      'contact': contact,
      'category': category,
      'title': title,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'stockDelta': stockDelta,
      'needsProductMatch': needsProductMatch,
      'needsConfirmation': needsConfirmation,
      'confidence': confidence,
      'rawText': rawText,
      'type': transactionType,
    };
  }

  static double? _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final normalized = value?.toString().replaceAll(',', '.').trim() ?? '';
    return double.tryParse(normalized);
  }

  static double? _parseNullableAmount(dynamic value) => _parseAmount(value);
}
