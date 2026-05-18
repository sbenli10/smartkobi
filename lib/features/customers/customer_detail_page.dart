import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'customers_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final _supabase = Supabase.instance.client;

  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;

  List<dynamic> _transactions = [];
  bool _loading = true;

  String _typeFilter = "all";
  DateTimeRange? _dateRange;

  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
    _loadData();
  }

  /// 🔴 REALTIME STREAM
  void _subscribeRealtime() {
  _supabase
      .channel('transactions_channel')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'customer_id',
          value: widget.customer.id,
        ),
        callback: (_) => _loadData(),
      )
      .subscribe();
}


  Future<void> _loadData() async {
    try {
      /// Balance view'dan
      final balanceData = await _supabase
          .from('customer_balances')
          .select('balance,total_income,total_expense')
          .eq('customer_id', widget.customer.id)
          .single();

      /// Transactions
      var query = _supabase
          .from('transactions')
          .select()
          .eq('customer_id', widget.customer.id)
          .eq('business_id', widget.customer.businessId)
          .isFilter('deleted_at', null);


      if (_typeFilter != "all") {
        query = query.eq('type', _typeFilter);
      }

      if (_dateRange != null) {
        query = query
            .gte('date',
                _dateRange!.start.toIso8601String())
            .lte('date',
                _dateRange!.end.toIso8601String());
      }

      final tx =
          await query.order('date', ascending: false);

      if (!mounted) return;

      setState(() {
        _balance =
            (balanceData['balance'] as num)
                .toDouble();
        _totalIncome =
            (balanceData['total_income'] as num)
                .toDouble();
        _totalExpense =
            (balanceData['total_expense'] as num)
                .toDouble();
        _transactions = tx;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// ➕ Yeni işlem
  void _addTransaction() async {
    final amountController =
        TextEditingController();
    String type = "income";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yeni İşlem"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(
                    value: "income",
                    child: Text("Gelir")),
                DropdownMenuItem(
                    value: "expense",
                    child: Text("Gider")),
              ],
              onChanged: (v) {
                type = v!;
              },
            ),
            TextField(
              controller: amountController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                      labelText: "Tutar"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              await _supabase
                  .from('transactions')
                  .insert({
                'business_id':
                    widget.customer.businessId,
                'customer_id':
                    widget.customer.id,
                'type': type,
                'amount':
                    double.parse(
                        amountController.text),
              });
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  /// 🗑 Soft delete
  Future<void> _softDelete(
      String transactionId) async {
    await _supabase
        .from('transactions')
        .update({
      'deleted_at':
          DateTime.now().toIso8601String()
    }).eq('id', transactionId);
  }

  Color _balanceColor() {
    if (_balance > 0) return Colors.green;
    if (_balance < 0) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
              onPressed: () async {
                final range =
                    await showDateRangePicker(
                  context: context,
                  firstDate:
                      DateTime(2020),
                  lastDate:
                      DateTime.now(),
                );
                if (range != null) {
                  setState(() {
                    _dateRange = range;
                  });
                  _loadData();
                }
              },
              icon:
                  const Icon(Icons.date_range))
        ],
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  /// 🔹 Balance Card
                  Card(
                    child: ListTile(
                      title: const Text(
                          "Cari Bakiye"),
                      trailing: Text(
                        _currency
                            .format(_balance),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              _balanceColor(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 Breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green
                              .withOpacity(0.1),
                          child: ListTile(
                            title:
                                const Text(
                                    "Toplam Gelir"),
                            trailing: Text(
                                _currency.format(
                                    _totalIncome),
                                style:
                                    const TextStyle(
                                        color: Colors
                                            .green)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.red
                              .withOpacity(0.1),
                          child: ListTile(
                            title:
                                const Text(
                                    "Toplam Gider"),
                            trailing: Text(
                                _currency.format(
                                    _totalExpense),
                                style:
                                    const TextStyle(
                                        color: Colors
                                            .red)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 Filter Buttons
                  Row(
                    children: [
                      FilterChip(
                        label:
                            const Text("Hepsi"),
                        selected:
                            _typeFilter ==
                                "all",
                        onSelected: (_) {
                          setState(() =>
                              _typeFilter =
                                  "all");
                          _loadData();
                        },
                      ),
                      const SizedBox(
                          width: 8),
                      FilterChip(
                        label:
                            const Text("Gelir"),
                        selected:
                            _typeFilter ==
                                "income",
                        onSelected: (_) {
                          setState(() =>
                              _typeFilter =
                                  "income");
                          _loadData();
                        },
                      ),
                      const SizedBox(
                          width: 8),
                      FilterChip(
                        label:
                            const Text("Gider"),
                        selected:
                            _typeFilter ==
                                "expense",
                        onSelected: (_) {
                          setState(() =>
                              _typeFilter =
                                  "expense");
                          _loadData();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          _transactions.length,
                      itemBuilder:
                          (_, i) {
                        final t =
                            _transactions[i];
                        final isIncome =
                            t['type'] ==
                                'income';

                        return ListTile(
                          onLongPress: () =>
                              _softDelete(
                                  t['id']),
                          leading: Icon(
                            isIncome
                                ? Icons
                                    .arrow_downward
                                : Icons
                                    .arrow_upward,
                            color: isIncome
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                              _currency.format(
                                  t['amount'])),
                          subtitle:
                              Text(t['type']),
                          trailing: Text(
                            DateFormat(
                                    'dd.MM.yyyy')
                                .format(
                                    DateTime.parse(
                                        t['date'])),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
