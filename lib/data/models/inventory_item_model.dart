class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.name,
    this.sku,
    this.barcode,
    this.category,
    required this.unit,
    required this.stockQuantity,
    required this.minStockLevel,
    required this.purchasePrice,
    required this.salePrice,
    this.supplierName,
    this.supplierPhone,
    this.description,
    required this.isActive,
    this.lastMovementDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? businessId;
  final String name;
  final String? sku;
  final String? barcode;
  final String? category;
  final String unit;
  final double stockQuantity;
  final double minStockLevel;
  final double purchasePrice;
  final double salePrice;
  final String? supplierName;
  final String? supplierPhone;
  final String? description;
  final bool isActive;
  final DateTime? lastMovementDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCriticalStock => stockQuantity <= minStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;
  double get profitAmount => salePrice - purchasePrice;
  double get profitMarginPercent =>
      purchasePrice > 0 ? ((salePrice - purchasePrice) / purchasePrice) * 100 : 0;
  double get stockValue => stockQuantity * purchasePrice;
  double get saleValue => stockQuantity * salePrice;

  InventoryItemModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? unit,
    double? stockQuantity,
    double? minStockLevel,
    double? purchasePrice,
    double? salePrice,
    String? supplierName,
    String? supplierPhone,
    String? description,
    bool? isActive,
    DateTime? lastMovementDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBusinessId = false,
    bool clearSku = false,
    bool clearBarcode = false,
    bool clearCategory = false,
    bool clearSupplierName = false,
    bool clearSupplierPhone = false,
    bool clearDescription = false,
    bool clearLastMovementDate = false,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: clearBusinessId ? null : businessId ?? this.businessId,
      name: name ?? this.name,
      sku: clearSku ? null : sku ?? this.sku,
      barcode: clearBarcode ? null : barcode ?? this.barcode,
      category: clearCategory ? null : category ?? this.category,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      supplierName: clearSupplierName ? null : supplierName ?? this.supplierName,
      supplierPhone: clearSupplierPhone ? null : supplierPhone ?? this.supplierPhone,
      description: clearDescription ? null : description ?? this.description,
      isActive: isActive ?? this.isActive,
      lastMovementDate: clearLastMovementDate
          ? null
          : lastMovementDate ?? this.lastMovementDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      name: (json['name'] ?? '') as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String?,
      unit: (json['unit'] ?? 'adet') as String,
      stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0,
      minStockLevel: (json['min_stock_level'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0,
      supplierName: json['supplier_name'] as String?,
      supplierPhone: json['supplier_phone'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastMovementDate: DateTime.tryParse(json['last_movement_date']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'min_stock_level': minStockLevel,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'supplier_name': supplierName,
      'supplier_phone': supplierPhone,
      'description': description,
      'is_active': isActive,
      'last_movement_date': lastMovementDate?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
