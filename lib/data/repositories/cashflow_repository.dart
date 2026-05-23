import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/cashflow/cashflow_calculations.dart';
import '../models/cashflow_entry_model.dart';
import '../models/cashflow_projection_model.dart';
import '../models/cashflow_scenario_model.dart';
import '../models/cashflow_snapshot_model.dart';

class CashflowRepository {
  CashflowRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CashflowEntryModel>> fetchCashflowEntries() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('cashflow_entries')
          .select()
          .eq('user_id', user.id)
          .order('expected_date', ascending: true)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) => CashflowEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Nakit akışı verileri alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Nakit akışı verileri alınamadı. Lütfen bağlantınızı kontrol edin.');
    }
  }

  Future<List<CashflowEntryModel>> fetchCashflowEntriesBetween(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('cashflow_entries')
          .select()
          .eq('user_id', user.id)
          .gte('expected_date', _isoDate(start))
          .lte('expected_date', _isoDate(end))
          .order('expected_date', ascending: true);

      return (data as List<dynamic>)
          .map((item) => CashflowEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Belirli tarih aralığındaki nakit kayıtları alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Nakit kayıtları alınırken bir sorun oluştu.');
    }
  }

  Future<CashflowEntryModel> addCashflowEntry(CashflowEntryModel entry) async {
    try {
      final user = _requireUser();
      final payload = entry.copyWith(userId: user.id).toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client.from('cashflow_entries').insert(payload).select().single();
      return CashflowEntryModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Nakit kaydı kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Nakit kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<CashflowEntryModel> updateCashflowEntry(CashflowEntryModel entry) async {
    try {
      final user = _requireUser();
      final payload = entry.copyWith(userId: user.id).toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('cashflow_entries')
          .update(payload)
          .eq('id', entry.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return CashflowEntryModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Nakit kaydı güncellenemedi. ${e.message}');
    } catch (_) {
      throw Exception('Nakit kaydı güncellenirken bir sorun oluştu.');
    }
  }

  Future<void> deleteCashflowEntry(String id) async {
    try {
      final user = _requireUser();
      await _client.from('cashflow_entries').delete().eq('id', id).eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Nakit kaydı silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('Nakit kaydı silinirken bir sorun oluştu.');
    }
  }

  Future<List<CashflowScenarioModel>> fetchCashflowScenarios() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('cashflow_scenarios')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) => CashflowScenarioModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Senaryo kayıtları alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Senaryo kayıtları alınırken bir sorun oluştu.');
    }
  }

  Future<CashflowScenarioModel> addCashflowScenario(
    CashflowScenarioModel scenario,
  ) async {
    try {
      final user = _requireUser();
      final payload = scenario.copyWith(userId: user.id).toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client.from('cashflow_scenarios').insert(payload).select().single();
      return CashflowScenarioModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Senaryo kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Senaryo kaydı sırasında bir sorun oluştu.');
    }
  }

  Future<CashflowSnapshotModel> saveSnapshot(CashflowSnapshotModel snapshot) async {
    try {
      final user = _requireUser();
      final payload = snapshot.copyWith(userId: user.id).toJson()..remove('id');
      final data = await _client.from('cashflow_snapshots').insert(payload).select().single();
      return CashflowSnapshotModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Nakit özeti kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('Nakit özeti kaydedilirken bir sorun oluştu.');
    }
  }

  Future<List<CashflowSnapshotModel>> fetchSnapshots() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('cashflow_snapshots')
          .select()
          .eq('user_id', user.id)
          .order('snapshot_date', ascending: false);

      return (data as List<dynamic>)
          .map((item) => CashflowSnapshotModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Nakit özetleri alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('Nakit özetleri alınırken bir sorun oluştu.');
    }
  }

  Future<CashflowProjectionModel> buildProjection({double openingBalance = 0}) async {
    final entries = await fetchCashflowEntries();
    final supplemented = <CashflowEntryModel>[...entries];
    supplemented.addAll(await _buildTransactionEntries());
    supplemented.addAll(await _buildCustomerEntries());

    final expectedInflow30d = calculateExpectedInflow(supplemented, 30);
    final expectedOutflow30d = calculateExpectedOutflow(supplemented, 30);
    final netCash30d =
        calculateNetCash(openingBalance, expectedInflow30d, expectedOutflow30d);
    final expectedInflow60d = calculateExpectedInflow(supplemented, 60);
    final expectedOutflow60d = calculateExpectedOutflow(supplemented, 60);
    final netCash60d =
        calculateNetCash(openingBalance, expectedInflow60d, expectedOutflow60d);
    final overdueInflowTotal = calculateOverdueInflow(supplemented);
    final upcomingOutflowTotal = calculateUpcomingOutflow(supplemented, 30);
    final cashScore = calculateCashScore(
      netCash30d: netCash30d,
      netCash60d: netCash60d,
      overdueInflow: overdueInflowTotal,
      expectedInflow30d: expectedInflow30d,
      upcomingOutflow30d: upcomingOutflowTotal,
      entries: supplemented,
    );
    final riskLevel = detectCashRiskLevel(cashScore);
    final aiSummary = generateCashflowAiSummary(
      entries: supplemented,
      netCash30d: netCash30d,
      overdueInflow: overdueInflowTotal,
      upcomingOutflow30d: upcomingOutflowTotal,
      expectedInflow30d: expectedInflow30d,
    );
    final suggestions = generateCashflowSuggestions(
      entries: supplemented,
      overdueInflow: overdueInflowTotal,
      expectedInflow30d: expectedInflow30d,
      upcomingOutflow30d: upcomingOutflowTotal,
    );

    return CashflowProjectionModel(
      openingBalance: openingBalance,
      expectedInflow30d: expectedInflow30d,
      expectedOutflow30d: expectedOutflow30d,
      netCash30d: netCash30d,
      expectedInflow60d: expectedInflow60d,
      expectedOutflow60d: expectedOutflow60d,
      netCash60d: netCash60d,
      overdueInflowTotal: overdueInflowTotal,
      upcomingOutflowTotal: upcomingOutflowTotal,
      cashScore: cashScore,
      riskLevel: riskLevel,
      aiSummary: aiSummary,
      criticalDate: detectCriticalDate(
        openingBalance: openingBalance,
        entries: supplemented,
      ),
      suggestions: suggestions,
    );
  }

  Future<List<CashflowEntryModel>> _buildTransactionEntries() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .neq('payment_status', 'paid');

      return (data as List<dynamic>).map((item) {
        final row = item as Map<String, dynamic>;

        return CashflowEntryModel(
          id: 'transaction-${row['id']}',
          userId: user.id,
          businessId: row['business_id']?.toString(),
          sourceType: 'transaction',
          sourceId: row['id']?.toString(),
          entryType: row['type'] == 'income' ? 'inflow' : 'outflow',
          title: row['title']?.toString() ?? 'Finans kaydı',
          category: row['category']?.toString(),
          amount: (row['amount'] as num?)?.toDouble() ?? 0,
          expectedDate:
              DateTime.tryParse(row['transaction_date']?.toString() ?? '') ?? DateTime.now(),
          status: row['payment_status']?.toString() ?? 'expected',
          recurrence: 'none',
          confidenceLevel: 'high',
          description: row['description']?.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CashflowEntryModel>> _buildCustomerEntries() async {
    try {
      final user = _requireUser();
      final data = await _client
          .from('customer_transactions')
          .select()
          .eq('user_id', user.id)
          .inFilter('payment_status', ['pending', 'overdue']);

      return (data as List<dynamic>).map((item) {
        final row = item as Map<String, dynamic>;
        final type = row['type']?.toString() ?? 'receivable';
        final entryType = type == 'receivable' ? 'inflow' : 'outflow';

        return CashflowEntryModel(
          id: 'customer-${row['id']}',
          userId: user.id,
          businessId: row['business_id']?.toString(),
          sourceType: 'customer',
          sourceId: row['id']?.toString(),
          entryType: entryType,
          title: row['title']?.toString() ?? 'Cari hareket',
          category: 'Cari',
          amount: (row['amount'] as num?)?.toDouble() ?? 0,
          expectedDate: DateTime.tryParse(row['due_date']?.toString() ?? '') ??
              DateTime.tryParse(row['transaction_date']?.toString() ?? '') ??
              DateTime.now(),
          status: row['payment_status']?.toString() ?? 'expected',
          recurrence: 'none',
          confidenceLevel: 'medium',
          description: row['description']?.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }

  String _isoDate(DateTime value) => value.toIso8601String().split('T').first;
}
