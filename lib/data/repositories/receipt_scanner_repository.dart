import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/receipt_scan_model.dart';
import '../models/purchase_invoice_item_model.dart';
import 'profit_leakage_repository.dart';

class ReceiptScannerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ReceiptScanModel> uploadAndCreateScan({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    String sourceType = 'expense',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');

    final safeFileName = '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';
    final filePath = '${user.id}/receipt-scans/$safeFileName';

    // 1. Dosyayı business-documents bucket'ına yükle
    await _supabase.storage.from('business-documents').uploadBinary(
      filePath,
      fileBytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    // 2. Veritabanında scan kaydı oluştur
    final response = await _supabase.from('receipt_scans').insert({
      'user_id': user.id,
      'source_type': sourceType,
      'file_name': fileName,
      'file_path': filePath,
      'file_mime_type': mimeType,
      'file_size_bytes': fileBytes.length,
      'scan_status': 'pending',
    }).select().single();

    return ReceiptScanModel.fromJson(response);
  }

  Future<ReceiptScanModel> processScanWithAI(String scanId) async {
    try {
      // 3. Edge Function Çağrısı
      final response = await _supabase.functions.invoke(
        'scan-receipt-invoice',
        body: {'scanId': scanId},
      );

      if (response.status != 200) {
        throw Exception('Fiş/Fatura okunamadı. Lütfen daha net bir fotoğrafla tekrar deneyin.');
      }

      // Güncellenmiş kaydı geri çek
      final updatedRecord = await _supabase.from('receipt_scans').select().eq('id', scanId).single();
      return ReceiptScanModel.fromJson(updatedRecord);
    } catch (e) {
      await _supabase.from('receipt_scans').update({'scan_status': 'failed', 'error_message': e.toString()}).eq('id', scanId);
      throw Exception('Fiş okuma servisi yanıt vermiyor. Lütfen manuel girin.');
    }
  }

  Future<void> saveAsExpenseTransaction({
    required ReceiptScanModel scan,
    required double amount,
    required DateTime transactionDate,
    required String category,
    required String title,
    String? description,
    double? taxAmount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Oturum bulunamadı.');

    // 1. Finans (Transactions) tablosuna gider kaydı ekle
    final txResponse = await _supabase.from('transactions').insert({
      'user_id': user.id,
      'type': 'expense',
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'category': category,
      'title': title,
      'description': description ?? 'Fiş/Fatura tarayıcı ile eklendi.',
      // Eğer veritabanınızda tax_amount varsa buraya ekleyebilirsin
    }).select().single();

    // 2. Scan kaydını güncelleyip tamamlandı olarak işaretle
    await _supabase.from('receipt_scans').update({
      'scan_status': 'saved',
      'transaction_id': txResponse['id'],
    }).eq('id', scan.id);

    // 3. Kâr Sızıntısı Analizi / Fiyat Radarı için kalemleri kaydet
    if (scan.aiResult != null && scan.aiResult!['lineItems'] != null) {
      final leakageRepo = ProfitLeakageRepository();
      final items = scan.aiResult!['lineItems'] as List;
      
      for (var item in items) {
        try {
          await leakageRepo.addPurchaseItem(PurchaseInvoiceItemModel(
            id: '', // Supabase (PostgreSQL) otomatik olarak UUID üretecek
            userId: user.id,
            // receiptScanId: scan.id, // Eğer modelinde bu alanı tanımlamadıysan yorum satırında kalabilir veya modeline ekleyebilirsin
            supplierName: scan.extractedVendorName,
            invoiceDate: transactionDate,
            itemName: item['itemName']?.toString() ?? 'Bilinmeyen Ürün',
            quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
            unit: item['unit']?.toString(),
            unitPrice: (item['unitPrice'] as num?)?.toDouble(),
            totalAmount: (item['totalAmount'] as num?)?.toDouble(),
            source: 'receipt_scan',
            createdAt: DateTime.now(),
          ));
        } catch (e) {
          debugPrint('Fatura kalemi eklenirken hata: $e');
        }
      }
    }
  }
}