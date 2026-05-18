import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String businessId;
  final String? customerId;
  final TransactionType type;
  final String? category;
  final double amount;
  final String currency;
  final DateTime date;
  final String? notes;

  TransactionModel({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.type,
    this.category,
    required this.amount,
    required this.currency,
    required this.date,
    this.notes,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      businessId: json['business_id'],
      customerId: json['customer_id'],
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _supabase = Supabase.instance.client;

  List<TransactionModel> _transactions = [];
  bool _loading = true;

  TransactionType? _filterType;
  DateTimeRange? _dateRange;

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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

  Future<void> _loadTransactions() async {
    final businessId = await _getBusinessId();
    if (businessId == null) return;

    final data = await _supabase
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .order('date', ascending: false);

    setState(() {
      _transactions =
          (data as List).map((e) => TransactionModel.fromJson(e)).toList();
      _loading = false;
    });
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((t) {
      if (_filterType != null && t.type != _filterType) return false;
      if (_dateRange != null) {
        if (t.date.isBefore(_dateRange!.start) ||
            t.date.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _openAddTransactionSheet() {
    TransactionType type = TransactionType.income;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Yeni İşlem",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text("Gelir"),
                        icon: Icon(Icons.trending_up),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text("Gider"),
                        icon: Icon(Icons.trending_down),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) {
                      setModalState(() => type = value.first);
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: "Tutar"),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: categoryController,
                    decoration:
                        const InputDecoration(labelText: "Kategori"),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: "Açıklama"),
                  ),

                  const SizedBox(height: 12),

                  ListTile(
                    title: Text(
                        "Tarih: ${DateFormat('dd.MM.yyyy').format(selectedDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final businessId =
                          await _getBusinessId();
                      if (businessId == null) return;

                      await _supabase
                          .from('transactions')
                          .insert({
                        'business_id': businessId,
                        'type': type.name,
                        'amount':
                            double.parse(amountController.text),
                        'category': categoryController.text,
                        'notes':
                            descriptionController.text,
                        'date':
                            selectedDate.toIso8601String(),
                        'currency': 'TRY',
                      });

                      Navigator.pop(context);
                      _loadTransactions();
                    },
                    child: const Text("Kaydet"),
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gelir - Gider Takibi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          PopupMenuButton<TransactionType?>(
            onSelected: (value) {
              setState(() => _filterType = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text("Tümü")),
              PopupMenuItem(
                  value: TransactionType.income,
                  child: Text("Sadece Gelir")),
              PopupMenuItem(
                  value: TransactionType.expense,
                  child: Text("Sadece Gider")),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const Center(
                  child: Text(
                      "Henüz işlem yok."),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(16),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Tarih")),
                      DataColumn(label: Text("Tür")),
                      DataColumn(label: Text("Kategori")),
                      DataColumn(label: Text("Tutar")),
                      DataColumn(label: Text("Açıklama")),
                    ],
                    rows: filtered
                        .map((t) => DataRow(cells: [
                              DataCell(Text(
                                  DateFormat('dd.MM.yyyy')
                                      .format(t.date))),
                              DataCell(Text(
                                  t.type ==
                                          TransactionType
                                              .income
                                      ? "Gelir"
                                      : "Gider")),
                              DataCell(
                                  Text(t.category ?? "-")),
                              DataCell(Text(
                                _currencyFormat
                                    .format(t.amount),
                                style: TextStyle(
                                  color: t.type ==
                                          TransactionType
                                              .income
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              )),
                              DataCell(
                                  Text(t.notes ?? "-")),
                            ]))
                        .toList(),
                  ),
                ),
      floatingActionButton:
          FloatingActionButton.extended(
        heroTag: "transactionsFab",
        onPressed: _openAddTransactionSheet,
        icon: const Icon(Icons.add),
        label: const Text("Yeni İşlem"),
      ),
    );
  }
}
