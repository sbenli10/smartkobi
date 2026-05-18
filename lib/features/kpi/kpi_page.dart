import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KpiPage extends StatefulWidget {
  const KpiPage({super.key});

  @override
  State<KpiPage> createState() => _KpiPageState();
}

class _KpiPageState extends State<KpiPage> {
  final _supabase = Supabase.instance.client;
  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  bool _loading = true;

  double totalIncome = 0;
  double totalExpense = 0;
  double unpaidInvoices = 0;
  int totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<String?> _getBusinessId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final res = await _supabase
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return res?['business_id'];

  }

  Future<void> _loadKpis() async {
    try {
      final businessId = await _getBusinessId();
      if (businessId == null) return;

      // 🔹 Transactions
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

      // 🔹 Unpaid invoices
      final invoices = await _supabase
          .from('invoices')
          .select('total,status')
          .eq('business_id', businessId)
          .neq('status', 'paid');

      double unpaid = 0;
      for (var i in invoices) {
        unpaid += (i['total'] as num).toDouble();
      }

      setState(() {
        totalIncome = income;
        totalExpense = expense;
        unpaidInvoices = unpaid;
        totalTransactions = tx.length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;
    final profitMargin =
        totalIncome == 0 ? 0 : (netProfit / totalIncome) * 100;
    final averageTransaction =
        totalTransactions == 0 ? 0 : totalIncome / totalTransactions;

    String aiComment;

    if (netProfit < 0) {
      aiComment =
          "Zarar söz konusu. Gider kalemleri ve maliyet yapısı acilen gözden geçirilmeli.";
    } else if (unpaidInvoices > totalIncome * 0.3) {
      aiComment =
          "Tahsil edilmemiş faturalar yüksek. Nakit akışı riski oluşabilir.";
    } else if (profitMargin < 15) {
      aiComment =
          "Kar marjı düşük. Operasyonel giderler optimize edilmeli.";
    } else {
      aiComment =
          "Finansal performans stabil ve sağlıklı görünüyor.";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("KPI & AI Analiz"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth > 900;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            _kpiCard(
                              context,
                              title: "Toplam Gelir",
                              value:
                                  _currency.format(totalIncome),
                              icon: Icons.trending_up,
                              color: Colors.green,
                              width: isWide
                                  ? 260
                                  : double.infinity,
                            ),
                            _kpiCard(
                              context,
                              title: "Toplam Gider",
                              value:
                                  _currency.format(totalExpense),
                              icon: Icons.trending_down,
                              color: Colors.red,
                              width: isWide
                                  ? 260
                                  : double.infinity,
                            ),
                            _kpiCard(
                              context,
                              title: "Net Kar",
                              value:
                                  _currency.format(netProfit),
                              icon:
                                  Icons.account_balance,
                              color: netProfit >= 0
                                  ? Colors.green
                                  : Colors.red,
                              width: isWide
                                  ? 260
                                  : double.infinity,
                            ),
                            _kpiCard(
                              context,
                              title: "Kar Marjı",
                              value:
                                  "${profitMargin.toStringAsFixed(1)}%",
                              icon: Icons.percent,
                              color: Colors.blue,
                              width: isWide
                                  ? 260
                                  : double.infinity,
                            ),
                            _kpiCard(
                              context,
                              title:
                                  "Tahsil Edilmemiş Fatura",
                              value: _currency
                                  .format(unpaidInvoices),
                              icon:
                                  Icons.warning_amber,
                              color: Colors.orange,
                              width: isWide
                                  ? 260
                                  : double.infinity,
                            ),
                            _kpiCard(
                              context,
                              title:
                                  "Ort. İşlem Tutarı",
                              value: _currency
                                  .format(
                                      averageTransaction),
                              icon: Icons.bar_chart,
                              color:
                                  Colors.deepPurple,
                              width: isWide
                                  ? 260
                                  : double.infinity,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        Text(
                          "AI Finansal Analiz",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                                    16),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                              const SizedBox(
                                  width: 12),
                              Expanded(
                                child: Text(
                                  aiComment,
                                  style:
                                      const TextStyle(
                                          fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color:
                Colors.black.withOpacity(0.05),
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
