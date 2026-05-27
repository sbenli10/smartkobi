import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profit_leakage/profit_leakage_calculations.dart';
import '../models/purchase_invoice_item_model.dart';
import '../models/supplier_price_alert_model.dart';

class ProfitLeakageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Oturum bulunamadı.');
    return user.id;
  }

  Future<void> addPurchaseItem(PurchaseInvoiceItemModel item) async {
    final normalized = ProfitLeakageCalculations.normalizeItemName(item.itemName);
    final unitPrice = ProfitLeakageCalculations.calculateUnitPrice(item.totalAmount, item.quantity, item.unitPrice);
    
    await _supabase.from('purchase_invoice_items').insert({
      'user_id': _userId,
      ...item.toJson(),
      'normalized_item_name': normalized,
      'unit_price': unitPrice,
    });
    
    // Eklendikten sonra analizi tetikle
    await analyzeAndSaveAlerts();
  }

  Future<List<SupplierPriceAlertModel>> fetchOpenAlerts() async {
    final response = await _supabase
        .from('supplier_price_alerts')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'open')
        .order('detected_at', ascending: false);
        
    return (response as List).map((e) => SupplierPriceAlertModel.fromJson(e)).toList();
  }

  Future<void> updateAlertStatus(String alertId, String status) async {
    await _supabase.from('supplier_price_alerts')
        .update({'status': status})
        .eq('id', alertId)
        .eq('user_id', _userId);
  }

  Future<void> analyzeAndSaveAlerts() async {
    // 1. Kullanıcının tüm alışlarını normalize_name ve tedarikçiye göre getir
    final response = await _supabase
        .from('purchase_invoice_items')
        .select()
        .eq('user_id', _userId)
        .order('invoice_date', ascending: false)
        .order('created_at', ascending: false);

    final items = (response as List).map((e) => PurchaseInvoiceItemModel.fromJson(e)).toList();
    final grouped = <String, List<PurchaseInvoiceItemModel>>{};
    
    for (var item in items) {
      if (item.unitPrice == null) continue;
      final key = '${item.normalizedItemName}_${item.supplierName ?? "Bilinmiyor"}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    for (var entry in grouped.entries) {
      final history = entry.value;
      if (history.length < 2) continue; // Karşılaştırma için en az 2 kayıt lazım

      final latest = history.first;
      final previous = history[1]; // Bir önceki kayıt

      if (latest.unitPrice! > previous.unitPrice!) {
        final increaseRate = ((latest.unitPrice! - previous.unitPrice!) / previous.unitPrice!) * 100;
        
        // %10'dan az artışları göz ardı et
        if (increaseRate < 10) continue;

        final severity = ProfitLeakageCalculations.determineSeverity(increaseRate);
        final supplierText = latest.supplierName != null ? "${latest.supplierName} tedarikçisinden alınan " : "";
        
        // Aynı ürün için aynı gün alert oluşturmamak adına kontrol yapılabilir (MVP'de basit insert/upsert)
        await _supabase.from('supplier_price_alerts').insert({
          'user_id': _userId,
          'latest_purchase_item_id': latest.id,
          'previous_purchase_item_id': previous.id,
          'severity': severity,
          'supplier_name': latest.supplierName,
          'item_name': latest.itemName,
          'normalized_item_name': latest.normalizedItemName,
          'previous_unit_price': previous.unitPrice,
          'latest_unit_price': latest.unitPrice,
          'increase_rate': increaseRate,
          'message': 'Dikkat: $supplierText"${latest.itemName}" birim fiyatı bir önceki alışınıza göre %${increaseRate.toStringAsFixed(1)} arttı.',
          'suggested_action': 'Kâr marjınız düşüyor olabilir. Satış fiyatınızı kontrol etmeniz önerilir.',
        });
      }
    }
  }
}