import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/inventory/inventory_calculations.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';

class InventoryRepository {
  InventoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<InventoryItemModel>> fetchInventoryItems() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('inventory_items')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((item) => InventoryItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Stok kayıtları alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Stok kayıtları alınamadı. Lütfen bağlantınızı kontrol edin.');
    }
  }

  Future<InventoryItemModel?> getInventoryItemById(String id) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('inventory_items')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();
      if (data == null) {
        return null;
      }
      return InventoryItemModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Ürün detayı alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Ürün detayı alınırken bir sorun oluştu.');
    }
  }

  Future<InventoryItemModel?> getInventoryItemByBarcode(String barcode) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('inventory_items')
          .select()
          .eq('barcode', barcode)
          .eq('user_id', user.id)
          .maybeSingle();
      if (data == null) {
        return null;
      }
      return InventoryItemModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<InventoryItemModel?> findInventoryItemByName(String name) async {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) {
      return null;
    }

    final items = await fetchInventoryItems();
    for (final item in items) {
      if (_normalizeName(item.name) == normalized) {
        return item;
      }
    }

    for (final item in items) {
      final itemName = _normalizeName(item.name);
      if (itemName.contains(normalized) || normalized.contains(itemName)) {
        return item;
      }
    }

    return null;
  }

  Future<InventoryItemModel> addInventoryItem(InventoryItemModel item) async {
    try {
      final user = _requireUser();
      final businessId = item.businessId ?? await _getCurrentBusinessId();
      final payload = item
          .copyWith(
            userId: user.id,
            businessId: businessId,
            stockQuantity: item.stockQuantity,
          )
          .toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client.from('inventory_items').insert(payload).select().single();
      return InventoryItemModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Ürün kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Ürün kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<InventoryItemModel> updateInventoryItem(InventoryItemModel item) async {
    try {
      final user = _requireUser();
      final payload = item.copyWith(userId: user.id).toJson()
        ..remove('created_at')
        ..remove('updated_at');
      final data = await _client
          .from('inventory_items')
          .update(payload)
          .eq('id', item.id)
          .eq('user_id', user.id)
          .select()
          .single();
      return InventoryItemModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Ürün güncellenemedi. ${e.message}');
    } catch (_) {
      throw Exception('Ürün güncellenirken bir sorun oluştu.');
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    try {
      final user = _requireUser();
      await _client.from('inventory_items').delete().eq('id', id).eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Ürün silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('Ürün silinirken bir sorun oluştu.');
    }
  }

  Future<void> deactivateInventoryItem(String id) async {
    try {
      final user = _requireUser();
      await _client
          .from('inventory_items')
          .update({'is_active': false})
          .eq('id', id)
          .eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Ürün pasifleştirilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Ürün pasifleştirilirken bir sorun oluştu.');
    }
  }

  Future<List<StockMovementModel>> fetchStockMovements(String inventoryItemId) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('stock_movements')
          .select()
          .eq('inventory_item_id', inventoryItemId)
          .eq('user_id', user.id)
          .order('movement_date', ascending: false)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((item) => StockMovementModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Stok hareketleri alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Stok hareketleri alınırken bir sorun oluştu.');
    }
  }

  Future<StockMovementModel> addStockMovement(StockMovementModel movement) async {
    try {
      final user = _requireUser();
      final item = await getInventoryItemById(movement.inventoryItemId);
      if (item == null) {
        throw Exception('Ürün bulunamadı.');
      }
      if (movement.isExit && movement.quantity > item.stockQuantity) {
        throw Exception('Stok miktarından fazla çıkış yapılamaz.');
      }
      final payload = movement
          .copyWith(
            userId: user.id,
            businessId: movement.businessId ?? item.businessId,
          )
          .toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client.from('stock_movements').insert(payload).select().single();
      await recalculateStockQuantity(movement.inventoryItemId);
      return StockMovementModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Stok hareketi kaydedilemedi. ${e.message}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Stok hareketi kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<void> deleteStockMovement(String id) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('stock_movements')
          .select('inventory_item_id')
          .eq('id', id)
          .eq('user_id', user.id)
          .single();
      final inventoryItemId = data['inventory_item_id'] as String;
      await _client.from('stock_movements').delete().eq('id', id).eq('user_id', user.id);
      await recalculateStockQuantity(inventoryItemId);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Stok hareketi silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('Stok hareketi silinirken bir sorun oluştu.');
    }
  }

  Future<void> recalculateStockQuantity(String inventoryItemId) async {
    final item = await getInventoryItemById(inventoryItemId);
    if (item == null) {
      return;
    }
    final movements = await fetchStockMovements(inventoryItemId);
    final newQuantity = calculateStockQuantityFromMovements(movements, 0);
    final lastMovementDate = movements.isEmpty
        ? null
        : movements
            .map((movement) => movement.movementDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    await _client
        .from('inventory_items')
        .update({
          'stock_quantity': newQuantity,
          'last_movement_date': lastMovementDate?.toIso8601String().split('T').first,
        })
        .eq('id', inventoryItemId)
        .eq('user_id', _requireUser().id);
  }

  double calculateStockQuantityFromMovements(
    List<StockMovementModel> movements,
    double initialQuantity,
  ) {
    double stock = initialQuantity;
    final ordered = [...movements]..sort((a, b) => a.movementDate.compareTo(b.movementDate));
    for (final movement in ordered) {
      switch (movement.movementType) {
        case 'in':
        case 'return':
          stock += movement.quantity;
          break;
        case 'out':
          stock -= movement.quantity;
          break;
        case 'adjustment':
          stock = movement.quantity;
          break;
      }
    }
    return stock < 0 ? 0 : stock;
  }

  String calculateStockStatus(InventoryItemModel item) => detectStockStatus(item);

  String calculateStockRiskLevel(InventoryItemModel item) => detectStockRiskLevel(item);

  Future<List<InventoryItemModel>> fetchCriticalStockItems() async {
    final items = await fetchInventoryItems();
    return items.where((item) => item.isCriticalStock).toList();
  }

  Future<List<InventoryItemModel>> fetchOutOfStockItems() async {
    final items = await fetchInventoryItems();
    return items.where((item) => item.isOutOfStock).toList();
  }

  String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  Future<String?> _getCurrentBusinessId() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('user_business_roles')
          .select('business_id')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();
      return data?['business_id'] as String?;
    } catch (_) {
      return null;
    }
  }
}
