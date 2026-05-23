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
      throw Exception('Finans kayıtları alınamadı: ${e.message}');
    } catch (e) {
      throw Exception('Finans kayıtları alınırken bir sorun oluştu.');
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

      final data = await _client
          .from('transactions')
          .insert(payload)
          .select()
          .single();

      return TransactionModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşlem kaydedilemedi: ${e.message}');
    } catch (e) {
      throw Exception('İşlem kaydedilirken bir sorun oluştu.');
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
      throw Exception('İşlem güncellenemedi: ${e.message}');
    } catch (e) {
      throw Exception('İşlem güncellenirken bir sorun oluştu.');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final user = _requireUser();
      await _client.from('transactions').delete().eq('id', id).eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşlem silinemedi: ${e.message}');
    } catch (e) {
      throw Exception('İşlem silinirken bir sorun oluştu.');
    }
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
