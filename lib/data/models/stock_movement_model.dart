class StockMovementModel {
  const StockMovementModel({
    required this.id,
    required this.userId,
    required this.inventoryItemId,
    this.businessId,
    required this.movementType,
    required this.quantity,
    this.unitPrice,
    required this.movementDate,
    this.referenceNo,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String inventoryItemId;
  final String? businessId;
  final String movementType;
  final double quantity;
  final double? unitPrice;
  final DateTime movementDate;
  final String? referenceNo;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEntry => movementType == 'in';
  bool get isExit => movementType == 'out';
  bool get isAdjustment => movementType == 'adjustment';
  bool get isReturn => movementType == 'return';
  double get totalValue => quantity * (unitPrice ?? 0);

  StockMovementModel copyWith({
    String? id,
    String? userId,
    String? inventoryItemId,
    String? businessId,
    String? movementType,
    double? quantity,
    double? unitPrice,
    DateTime? movementDate,
    String? referenceNo,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearUnitPrice = false,
    bool clearReferenceNo = false,
    bool clearNote = false,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
      movementDate: movementDate ?? this.movementDate,
      referenceNo: clearReferenceNo ? null : referenceNo ?? this.referenceNo,
      note: clearNote ? null : note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      inventoryItemId: json['inventory_item_id'] as String,
      businessId: json['business_id'] as String?,
      movementType: (json['movement_type'] ?? 'in') as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      movementDate: DateTime.tryParse(json['movement_date']?.toString() ?? '') ??
          DateTime.now(),
      referenceNo: json['reference_no'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'inventory_item_id': inventoryItemId,
      'business_id': businessId,
      'movement_type': movementType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'movement_date': movementDate.toIso8601String().split('T').first,
      'reference_no': referenceNo,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
