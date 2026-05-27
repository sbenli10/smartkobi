class PurchaseInvoiceItemModel {
  final String id;
  final String userId;
  final String? supplierName;
  final DateTime? invoiceDate;
  final String itemName;
  final String? normalizedItemName;
  final double quantity;
  final String? unit;
  final double? unitPrice;
  final double? totalAmount;
  final String currency;
  final String source;
  final DateTime createdAt;

  PurchaseInvoiceItemModel({
    required this.id,
    required this.userId,
    this.supplierName,
    this.invoiceDate,
    required this.itemName,
    this.normalizedItemName,
    this.quantity = 1,
    this.unit,
    this.unitPrice,
    this.totalAmount,
    this.currency = 'TRY',
    this.source = 'manual',
    required this.createdAt,
  });

  factory PurchaseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItemModel(
      id: json['id'],
      userId: json['user_id'],
      supplierName: json['supplier_name'],
      invoiceDate: json['invoice_date'] != null ? DateTime.parse(json['invoice_date']) : null,
      itemName: json['item_name'],
      normalizedItemName: json['normalized_item_name'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'],
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'TRY',
      source: json['source'] ?? 'manual',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'item_name': itemName,
    'normalized_item_name': normalizedItemName,
    'supplier_name': supplierName,
    'invoice_date': invoiceDate?.toIso8601String().split('T').first,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'total_amount': totalAmount,
    'source': source,
    'currency': currency,
  };
}