import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_page.dart'; // ProductModel için

class InventoryHistoryPage extends StatefulWidget {
  final ProductModel product;

  const InventoryHistoryPage({
    super.key,
    required this.product,
  });

  @override
  State<InventoryHistoryPage> createState() =>
      _InventoryHistoryPageState();
}

class _InventoryHistoryPageState
    extends State<InventoryHistoryPage> {
  final _supabase = Supabase.instance.client;

  List<dynamic> _movements = [];
  bool _loading = true;

  double _totalIn = 0;
  double _totalOut = 0;

  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '');

  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
    _loadHistory();
  }

  void _subscribeRealtime() {
    _channel = _supabase.channel('inventory_history')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'inventory_movements',
        callback: (_) => _loadHistory(),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final data = await _supabase
        .from('inventory_movements')
        .select()
        .eq('product_id', widget.product.id)
        .isFilter('deleted_at', null)
        .order('occurred_at', ascending: false);

    double totalIn = 0;
    double totalOut = 0;

    for (var m in data) {
      final qty = (m['quantity'] as num).toDouble();
      if (qty > 0) {
        totalIn += qty;
      } else {
        totalOut += qty.abs();
      }
    }

    setState(() {
      _movements = data;
      _totalIn = totalIn;
      _totalOut = totalOut;
      _loading = false;
    });
  }

  String _reasonLabel(String reason) {
  switch (reason) {
    case 'sale':
      return 'Satış';
    case 'purchase':
      return 'Alım';
    case 'adjustment':
      return 'Stok Düzeltme';
    default:
      return reason;
  }
}


  Future<void> _softDeleteMovement(String id) async {
    await _supabase
        .from('inventory_movements')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    _loadHistory();
  }

  Color _reasonColor(String reason) {
    switch (reason) {
      case 'sale':
        return Colors.red;
      case 'purchase':
        return Colors.green;
      case 'adjustment':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }


  @override
  Widget build(BuildContext context) {
    final net = _totalIn - _totalOut;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.product.name}"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// 🔹 SUMMARY CARD
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade600,
                        Colors.blue.shade400
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Stok Özeti",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currency.format(net),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(
                              "Giriş", _totalIn, Colors.green),
                          _buildMiniStat(
                              "Çıkış", _totalOut, Colors.red),
                        ],
                      )
                    ],
                  ),
                ),

                /// 🔹 LIST
                Expanded(
                  child: _movements.isEmpty
                      ? const Center(
                          child: Text(
                              "Henüz stok hareketi yok."),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                          itemCount: _movements.length,
                          itemBuilder: (_, i) {
                            final m = _movements[i];
                            final qty =
                                (m['quantity'] as num)
                                    .toDouble();
                            final isIn = qty > 0;

                            return GestureDetector(
                              onLongPress: () =>
                                  _softDeleteMovement(
                                      m['id']),
                              child: Container(
                                margin:
                                    const EdgeInsets.only(
                                        bottom: 12),
                                padding:
                                    const EdgeInsets.all(
                                        16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(
                                              0.05),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [

                                    /// ICON
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .all(10),
                                      decoration:
                                          BoxDecoration(
                                        color: isIn
                                            ? Colors
                                                .green
                                                .withOpacity(
                                                    0.15)
                                            : Colors.red
                                                .withOpacity(
                                                    0.15),
                                        shape: BoxShape
                                            .circle,
                                      ),
                                      child: Icon(
                                        isIn
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: isIn ? Colors.green : Colors.red,
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    /// DETAILS
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            "${isIn ? "+" : "-"} ${qty.abs().toStringAsFixed(0)} ${widget.product.unit}",
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  16,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal:
                                                  8,
                                              vertical:
                                                  4,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: _reasonColor(
                                                      m['reason'])
                                                  .withOpacity(
                                                      0.15),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          8),
                                            ),
                                           child: Text(
                                             _reasonLabel(m['reason']),
                                              style:
                                                  TextStyle(
                                                color:
                                                    _reasonColor(
                                                        m['reason']),
                                                fontSize:
                                                    12,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// DATE
                                    Text(
                                      _dateFormat.format(
                                          DateTime.parse(
                                              m['occurred_at'])),
                                      style: const TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMiniStat(
      String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style:
              const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          _currency.format(value),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
