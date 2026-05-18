// lib/features/ai/ai_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _premium = false;

  double totalIncome = 0;
  double totalExpense = 0;
  double unpaidInvoices = 0;
  int criticalStockCount = 0;
  int financialHealthScore = 0;

  String riskLevel = "";
  List<String> actions = [];

  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _premium = await _isPremium();

    if (_premium) {
      _initRealtime();
      await _loadData();
    } else {
      setState(() => _loading = false);
    }
  }

 Future<bool> _isPremium() async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final role = await _supabase
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (role == null) return false;

    final businessId = role['business_id'];

    final business = await _supabase
        .from('businesses')
        .select('plan')
        .eq('id', businessId)
        .maybeSingle();

    if (business == null) return false;

    debugPrint("AI PAGE PLAN: ${business['plan']}");

    return business['plan'] == 'premium';
  } catch (e) {
    debugPrint("Premium check error: $e");
    return false;
  }
}


  void _initRealtime() {
    _channel = _supabase.channel('ai-dashboard')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        callback: (_) => _loadData(),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    if (_premium) {
      _supabase.removeChannel(_channel);
    }
    super.dispose();
  }

  Future<String?> _getBusinessId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final res = await _supabase
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id)
        .single();

    return res['business_id'];
  }

  Future<void> _loadData() async {
    final businessId = await _getBusinessId();
    if (businessId == null) return;

    /// TRANSACTIONS
    final tx = await _supabase
        .from('transactions')
        .select('amount,type')
        .eq('business_id', businessId);

    double income = 0;
    double expense = 0;

    for (var t in tx) {
      if (t['type'] == 'income') {
        income += (t['amount'] as num).toDouble();
      } else {
        expense += (t['amount'] as num).toDouble();
      }
    }

    /// UNPAID
    final invoices = await _supabase
        .from('invoices')
        .select('total,status')
        .eq('business_id', businessId)
        .neq('status', 'paid');

    double unpaid = 0;
    for (var i in invoices) {
      unpaid += (i['total'] as num).toDouble();
    }

    /// CRITICAL STOCK
    final stocks = await _supabase
        .from('product_stocks')
        .select('stock,min_stock')
        .eq('business_id', businessId);

    int critical = 0;
    for (var s in stocks) {
      if ((s['stock'] as num) <= (s['min_stock'] as num)) {
        critical++;
      }
    }

    /// CALL EDGE FUNCTION
    final response = await _supabase.functions.invoke(
       'ai-insight',
      body: {
        "businessId": businessId,
        "income": income,
        "expense": expense,
        "unpaidInvoices": unpaid,
        "criticalStock": critical,
        "totalProducts": stocks.length
      },
    );

    final data = response.data;

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      unpaidInvoices = unpaid;
      criticalStockCount = critical;
      financialHealthScore = data['financialHealthScore'];
      riskLevel = data['risk_level'];
      actions = List<String>.from(data['actions']);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    if (!_premium) {
      return Scaffold(
        appBar: AppBar(title: const Text("AI CFO")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 60, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                "Finansal Sağlık Skoru Premium Özelliktir",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Pro plana geçerek erişebilirsiniz."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/upgrade');
                },
                child: const Text("Planı Yükselt"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("AI CFO")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _scoreCard(),
                  const SizedBox(height: 20),
                  _metricCard("Toplam Gelir",
                      currency.format(totalIncome), Colors.green),
                  _metricCard("Toplam Gider",
                      currency.format(totalExpense), Colors.red),
                  _metricCard("Tahsil Edilmemiş",
                      currency.format(unpaidInvoices), Colors.orange),
                  _metricCard("Kritik Stok",
                      criticalStockCount.toString(), Colors.purple),
                  const SizedBox(height: 30),
                  const Text(
                    "AI Stratejik Öneriler",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...actions.map((a) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: Colors.blue),
                          title: Text(a),
                        ),
                      ))
                ],
              ),
            ),
    );
  }

  Widget _scoreCard() {
    Color scoreColor = Colors.green;
    if (financialHealthScore < 50) scoreColor = Colors.red;
    else if (financialHealthScore < 75) scoreColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.8), scoreColor],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Finansal Sağlık Skoru",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            "$financialHealthScore / 100",
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            riskLevel,
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
