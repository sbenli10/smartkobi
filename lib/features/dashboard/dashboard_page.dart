import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/monthly_summary_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../ai/ai_service.dart';
import '../auth/login_page.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/stat_card.dart';
import 'widgets/ai_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repository = DashboardRepository();
  final _aiService = AiInsightService();

  bool _loading = true;

  List<MonthlySummaryModel> monthlyData = [];

  double income = 0;
  double expense = 0;

  String? selectedBusinessId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final role = await Supabase.instance.client
          .from('user_business_roles')
          .select('business_id')
          .eq('user_id', user.id)
          .single();

      final businessId = role['business_id'];
      selectedBusinessId = businessId;

      final summary =
          await _repository.getLast6MonthsSummary(businessId);

      income = summary.fold(0, (a, b) => a + b.income);
      expense = summary.fold(0, (a, b) => a + b.expense);

      if (!mounted) return;

      setState(() {
        monthlyData = summary;
        _loading = false;
      });

      await _callAI();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _callAI() async {
    if (selectedBusinessId == null) return;

    final response = await Supabase.instance.client.functions.invoke(
      'ai-insight',
      body: {
        "businessId": selectedBusinessId,
        "income": income,
        "expense": expense,
        "lowStock": 0,
      },
    );

    debugPrint("AI Response: ${response.data}");
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final insight =
        _aiService.generateInsight(income: income, expense: expense);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartKOBİ Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPagePremium(
                    style: LoginStyle.corporateSaaS,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IncomeExpenseChart(data: monthlyData),
          const SizedBox(height: 20),

          StatCard(
            title: "Toplam Gelir (6 Ay)",
            value: income,
            color: Colors.green,
            icon: Icons.trending_up,
          ),
          StatCard(
            title: "Toplam Gider (6 Ay)",
            value: expense,
            color: Colors.red,
            icon: Icons.trending_down,
          ),

          const SizedBox(height: 10),

          AiCard(insight: insight),
        ],
      ),
    );
  }
}
