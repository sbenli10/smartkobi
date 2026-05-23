import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/widgets/metric_card.dart';
import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';

class KpiPage extends StatefulWidget {
  const KpiPage({super.key});

  @override
  State<KpiPage> createState() => _KpiPageState();
}

class _KpiPageState extends State<KpiPage> {
  final _supabase = Supabase.instance.client;
  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

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
    if (user == null) {
      return null;
    }

    final res = await _supabase
        .from('user_business_roles')
        .select('business_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return res?['business_id'] as String?;
  }

  Future<void> _loadKpis() async {
    try {
      final businessId = await _getBusinessId();
      if (businessId == null) {
        setState(() => _loading = false);
        return;
      }

      final tx = await _supabase
          .from('transactions')
          .select('amount,type')
          .eq('business_id', businessId);

      double income = 0;
      double expense = 0;

      for (final transaction in tx) {
        if (transaction['type'] == 'income') {
          income += (transaction['amount'] as num).toDouble();
        } else {
          expense += (transaction['amount'] as num).toDouble();
        }
      }

      final invoices = await _supabase
          .from('invoices')
          .select('total,status')
          .eq('business_id', businessId)
          .neq('status', 'paid');

      double unpaid = 0;
      for (final invoice in invoices) {
        unpaid += (invoice['total'] as num).toDouble();
      }

      setState(() {
        totalIncome = income;
        totalExpense = expense;
        unpaidInvoices = unpaid;
        totalTransactions = tx.length;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = totalIncome - totalExpense;
    final profitMargin = totalIncome == 0 ? 0.0 : (netProfit / totalIncome) * 100;
    final averageTransaction = totalTransactions == 0 ? 0.0 : totalIncome / totalTransactions;

    return PageScaffold(
      title: 'KPI Merkezi',
      subtitle: 'Temel finansal göstergeleri ve yönetici yorumlarını takip edin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadKpis,
          icon: const Icon(Icons.refresh),
          tooltip: 'Yenile',
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 250,
                      child: MetricCard(
                        title: 'Toplam Gelir',
                        value: _currency.format(totalIncome),
                        icon: Icons.trending_up,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: MetricCard(
                        title: 'Toplam Gider',
                        value: _currency.format(totalExpense),
                        icon: Icons.trending_down,
                        color: AppColors.danger,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: MetricCard(
                        title: 'Net Kar',
                        value: _currency.format(netProfit),
                        icon: Icons.account_balance_outlined,
                        color: netProfit >= 0 ? AppColors.gold500 : AppColors.warning,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: MetricCard(
                        title: 'Kar Marjı',
                        value: '%${profitMargin.toStringAsFixed(1)}',
                        icon: Icons.percent,
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: MetricCard(
                        title: 'Tahsil Edilmemiş Fatura',
                        value: _currency.format(unpaidInvoices),
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: MetricCard(
                        title: 'Ortalama İşlem',
                        value: _currency.format(averageTransaction),
                        icon: Icons.bar_chart_outlined,
                        color: AppColors.gold400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SmartCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'AI Yönetim Yorumu',
                        subtitle: 'KPI görünümüne göre üretilen kısa yorum',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _buildComment(
                            netProfit: netProfit,
                            unpaidInvoices: unpaidInvoices,
                            totalIncome: totalIncome,
                            profitMargin: profitMargin,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _buildComment({
    required double netProfit,
    required double unpaidInvoices,
    required double totalIncome,
    required double profitMargin,
  }) {
    if (netProfit < 0) {
      return 'Kârlılık baskı altında. Gider kalemlerini ve düşük marjlı işleri öncelikle gözden geçirin.';
    }
    if (unpaidInvoices > totalIncome * 0.3) {
      return 'Tahsilat yükü yüksek. Nakit akışı riskini azaltmak için cari takip temposunu artırın.';
    }
    if (profitMargin < 15) {
      return 'Kar marjı düşük seyrediyor. Operasyon verimliliği ve fiyatlama stratejisi yeniden değerlendirilmeli.';
    }
    return 'Finansal yapı dengeli görünüyor. Büyüme yatırımları için kontrollü alan oluşmuş durumda.';
  }
}
