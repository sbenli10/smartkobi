import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monthly_summary_model.dart';

class DashboardRepository {
  final _client = Supabase.instance.client;

  Future<List<MonthlySummaryModel>> getLast6MonthsSummary(
      String businessId) async {
    final now = DateTime.now();
    final sixMonthsAgo =
        DateTime(now.year, now.month - 5, 1);

    final response = await _client
        .from('transactions')
        .select('amount,type,date')
        .eq('business_id', businessId)
        .gte('date', sixMonthsAgo.toIso8601String());

    final Map<String, double> incomeMap = {};
    final Map<String, double> expenseMap = {};

    for (final t in response) {
      final date = DateTime.parse(t['date']);
      final key = "${date.year}-${date.month}";
      final amount = (t['amount'] as num).toDouble();

      if (t['type'] == 'income') {
        incomeMap[key] = (incomeMap[key] ?? 0) + amount;
      } else {
        expenseMap[key] = (expenseMap[key] ?? 0) + amount;
      }
    }

    final List<MonthlySummaryModel> result = [];

    incomeMap.forEach((key, value) {
      result.add(
        MonthlySummaryModel(
          month: key,
          income: value,
          expense: expenseMap[key] ?? 0,
        ),
      );
    });

    return result;
  }
}
