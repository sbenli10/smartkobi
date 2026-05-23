import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/customers/customer_calculations.dart';
import '../models/customer_model.dart';
import '../models/customer_transaction_model.dart';

class CustomersRepository {
  CustomersRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CustomerModel>> fetchCustomers() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('customers')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) => CustomerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Cari kayıtlar alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Cari kayıtlar alınamadı. Lütfen bağlantınızı kontrol edin.');
    }
  }

  Future<CustomerModel> addCustomer(CustomerModel customer) async {
    try {
      final user = _requireUser();
      final businessId = customer.businessId ?? await _getCurrentBusinessId();
      final payload = customer
          .copyWith(
            userId: user.id,
            businessId: businessId,
            currentBalance: customer.openingBalance,
          )
          .toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client.from('customers').insert(payload).select().single();
      return CustomerModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Müşteri kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Müşteri kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final user = _requireUser();
      final payload = customer.copyWith(userId: user.id).toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('customers')
          .update(payload)
          .eq('id', customer.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return CustomerModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Müşteri güncellenemedi. ${e.message}');
    } catch (_) {
      throw Exception('Müşteri güncellenirken bir sorun oluştu.');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      final user = _requireUser();
      await _client.from('customers').delete().eq('id', id).eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Müşteri silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('Müşteri silinirken bir sorun oluştu.');
    }
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();
      if (data == null) {
        return null;
      }
      return CustomerModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Müşteri detayı alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Müşteri detayı alınırken bir sorun oluştu.');
    }
  }

  Future<List<CustomerTransactionModel>> fetchCustomerTransactions(String customerId) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('customer_transactions')
          .select()
          .eq('customer_id', customerId)
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) =>
              CustomerTransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Cari hareketler alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Cari hareketler alınırken bir sorun oluştu.');
    }
  }

  Future<CustomerTransactionModel> addCustomerTransaction(
    CustomerTransactionModel transaction,
  ) async {
    try {
      final user = _requireUser();
      final customer = await getCustomerById(transaction.customerId);
      final businessId = transaction.businessId ??
          customer?.businessId ??
          await _getCurrentBusinessId();

      final payload = transaction
          .copyWith(userId: user.id, businessId: businessId)
          .toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('customer_transactions')
          .insert(payload)
          .select()
          .single();

      await recalculateCustomerBalance(transaction.customerId);
      return CustomerTransactionModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Cari hareket kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Cari hareket kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<CustomerTransactionModel> updateCustomerTransaction(
    CustomerTransactionModel transaction,
  ) async {
    try {
      final user = _requireUser();
      final payload = transaction.copyWith(userId: user.id).toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('customer_transactions')
          .update(payload)
          .eq('id', transaction.id)
          .eq('user_id', user.id)
          .select()
          .single();

      await recalculateCustomerBalance(transaction.customerId);
      return CustomerTransactionModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Cari hareket güncellenemedi. ${e.message}');
    } catch (_) {
      throw Exception('Cari hareket güncellenirken bir sorun oluştu.');
    }
  }

  Future<void> deleteCustomerTransaction(String id) async {
    try {
      final user = _requireUser();
      final row = await _client
          .from('customer_transactions')
          .select('customer_id')
          .eq('id', id)
          .eq('user_id', user.id)
          .single();
      final customerId = row['customer_id'] as String;
      await _client
          .from('customer_transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      await recalculateCustomerBalance(customerId);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Cari hareket silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('Cari hareket silinirken bir sorun oluştu.');
    }
  }

  Future<void> recalculateCustomerBalance(String customerId) async {
    try {
      final customer = await getCustomerById(customerId);
      if (customer == null) {
        return;
      }

      final transactions = await fetchCustomerTransactions(customerId);
      final balance = customer.openingBalance + calculateBalanceFromTransactions(transactions);
      final riskLevel = calculateRiskLevel(customer, transactions);
      final nextCollectionDate = calculateNextCollectionDate(transactions);
      final lastTransactionDate = transactions.isEmpty ? null : transactions
          .map((transaction) => transaction.transactionDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      await _client
          .from('customers')
          .update({
            'current_balance': balance,
            'risk_level': riskLevel,
            'next_collection_date': nextCollectionDate?.toIso8601String().split('T').first,
            'last_transaction_date': lastTransactionDate?.toIso8601String().split('T').first,
          })
          .eq('id', customerId)
          .eq('user_id', _requireUser().id);
    } catch (_) {
      rethrow;
    }
  }

  double calculateBalanceFromTransactions(List<CustomerTransactionModel> transactions) {
    return transactions.fold<double>(0, (sum, transaction) {
      switch (transaction.type) {
        case 'payment':
        case 'debt':
          return sum - transaction.amount;
        case 'adjustment':
        case 'receivable':
          return sum + transaction.amount;
        default:
          return sum;
      }
    });
  }

  String calculateRiskLevel(
    CustomerModel customer,
    List<CustomerTransactionModel> transactions,
  ) {
    return detectRiskLevel(customer, transactions);
  }

  DateTime? calculateNextCollectionDate(List<CustomerTransactionModel> transactions) {
    final dueDates = transactions
        .where((transaction) =>
            transaction.isReceivable &&
            !transaction.isPaid &&
            transaction.dueDate != null)
        .map((transaction) => transaction.dueDate!)
        .toList()
      ..sort();
    return dueDates.isEmpty ? null : dueDates.first;
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
