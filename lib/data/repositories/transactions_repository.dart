import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';

class TransactionsRepository {
  TransactionsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Finans kayıtları yüklenemedi. Lütfen tekrar deneyin.');
    } catch (_) {
      throw Exception('Finans kayıtları yüklenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      final user = _requireUser();
      final businessId = transaction.businessId ?? await _getCurrentBusinessId();
      final payload = transaction
          .copyWith(userId: user.id, businessId: businessId)
          .toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _insertTransactionPayload(payload);
      return TransactionModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşlem kaydedilemedi. Lütfen tekrar deneyin.');
    } catch (_) {
      throw Exception('İşlem kaydedilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    try {
      final user = _requireUser();
      final payload = transaction.copyWith(userId: user.id).toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('transactions')
          .update(payload)
          .eq('id', transaction.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return TransactionModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşlem güncellenemedi. Lütfen tekrar deneyin.');
    } catch (_) {
      throw Exception('İşlem güncellenemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final user = _requireUser();
      await _client.from('transactions').delete().eq('id', id).eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşlem silinemedi. Lütfen tekrar deneyin.');
    } catch (_) {
      throw Exception('İşlem silinemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<Map<String, dynamic>> _insertTransactionPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      final data = await _client
          .from('transactions')
          .insert(payload)
          .select()
          .single();
      return Map<String, dynamic>.from(data);
    } on PostgrestException catch (e) {
      if (_isMissingContactNameColumnError(e) && payload.containsKey('contact_name')) {
        final fallbackPayload = Map<String, dynamic>.from(payload);
        fallbackPayload.remove('contact_name');

        final existingDescription = fallbackPayload['description']?.toString().trim();
        final contactName = payload['contact_name']?.toString().trim();
        if (contactName != null && contactName.isNotEmpty) {
          fallbackPayload['description'] =
              (existingDescription == null || existingDescription.isEmpty)
              ? 'Kişi/Firma: $contactName'
              : '$existingDescription\nKişi/Firma: $contactName';
        }

        final data = await _client
            .from('transactions')
            .insert(fallbackPayload)
            .select()
            .single();
        return Map<String, dynamic>.from(data);
      }

      rethrow;
    }
  }

  bool _isMissingContactNameColumnError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('contact_name') &&
        (message.contains('column') || message.contains('schema cache'));
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Lütfen finans modülünü kullanmak için giriş yapın.');
    }
    return user;
  }

  Future<String?> _getCurrentBusinessId() async {
    final user = _requireUser();
    final data = await _client
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return data?['business_id'] as String?;
  }
}
