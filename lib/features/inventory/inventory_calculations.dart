import '../../data/models/inventory_item_model.dart';

int totalProductCount(List<InventoryItemModel> items) => items.length;

double totalStockValue(List<InventoryItemModel> items) =>
    items.fold(0, (sum, item) => sum + item.stockValue);

double totalSaleValue(List<InventoryItemModel> items) =>
    items.fold(0, (sum, item) => sum + item.saleValue);

int criticalStockCount(List<InventoryItemModel> items) =>
    items.where((item) => item.isCriticalStock && !item.isOutOfStock).length;

int outOfStockCount(List<InventoryItemModel> items) =>
    items.where((item) => item.isOutOfStock).length;

double averageProfitMargin(List<InventoryItemModel> items) {
  if (items.isEmpty) {
    return 0;
  }
  final total = items.fold<double>(0, (sum, item) => sum + item.profitMarginPercent);
  return total / items.length;
}

List<InventoryItemModel> lowProfitMarginItems(List<InventoryItemModel> items) =>
    items.where((item) => item.profitMarginPercent < 15).toList();

String detectStockStatus(InventoryItemModel item) {
  if (item.isOutOfStock) {
    return 'Tükendi';
  }
  if (item.isCriticalStock) {
    return 'Kritik';
  }
  return 'Stokta';
}

String detectStockRiskLevel(InventoryItemModel item) {
  if (item.isOutOfStock) {
    return 'high';
  }
  if (item.isCriticalStock || item.profitMarginPercent < 15) {
    return 'medium';
  }
  return 'low';
}

String generateInventoryAiInsight(List<InventoryItemModel> items) {
  if (items.isEmpty) {
    return 'Ürünlerinizi eklediğinizde SmartKOBİ kritik stok, kâr marjı ve sipariş önerilerini analiz eder.';
  }
  if (items.any((item) => item.isCriticalStock)) {
    return 'Bazı ürünler minimum stok seviyesine ulaşmış veya altına düşmüş. Yeniden sipariş planı oluşturmanız önerilir.';
  }
  if (items.any((item) => item.isOutOfStock)) {
    return 'Stokta olmayan ürünler satış kaybına neden olabilir.';
  }
  if (items.any((item) => item.profitMarginPercent < 15)) {
    return 'Bazı ürünlerin kâr marjı düşük görünüyor. Alış ve satış fiyatlarını gözden geçirin.';
  }
  return 'Stok yapınız dengeli görünüyor.';
}

double calculateProfitAmount(double purchasePrice, double salePrice) => salePrice - purchasePrice;

double calculateProfitMarginPercent(double purchasePrice, double salePrice) {
  if (purchasePrice <= 0) {
    return 0;
  }
  return ((salePrice - purchasePrice) / purchasePrice) * 100;
}