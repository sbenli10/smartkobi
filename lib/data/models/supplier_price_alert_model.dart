class SupplierPriceAlertModel {
  final String id;
  final String userId;
  final String severity;
  final String? supplierName;
  final String itemName;
  final double? previousUnitPrice;
  final double? latestUnitPrice;
  final double? increaseRate;
  final String message;
  final String? suggestedAction;
  final String status;
  final DateTime detectedAt;

  SupplierPriceAlertModel({
    required this.id,
    required this.userId,
    this.severity = 'medium',
    this.supplierName,
    required this.itemName,
    this.previousUnitPrice,
    this.latestUnitPrice,
    this.increaseRate,
    required this.message,
    this.suggestedAction,
    this.status = 'open',
    required this.detectedAt,
  });

  factory SupplierPriceAlertModel.fromJson(Map<String, dynamic> json) {
    return SupplierPriceAlertModel(
      id: json['id'],
      userId: json['user_id'],
      severity: json['severity'] ?? 'medium',
      supplierName: json['supplier_name'],
      itemName: json['item_name'],
      previousUnitPrice: (json['previous_unit_price'] as num?)?.toDouble(),
      latestUnitPrice: (json['latest_unit_price'] as num?)?.toDouble(),
      increaseRate: (json['increase_rate'] as num?)?.toDouble(),
      message: json['message'] ?? '',
      suggestedAction: json['suggested_action'],
      status: json['status'] ?? 'open',
      detectedAt: DateTime.parse(json['detected_at']),
    );
  }
}