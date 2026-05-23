import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transactions_repository.dart';
import 'finance_calculations.dart';

enum TransactionFilter { all, income, expense, thisMonth, pending }

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TransactionsRepository _repository = TransactionsRepository();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  List<TransactionModel> _transactions = [];
  bool _loading = true;
  TransactionFilter _activeFilter = TransactionFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final transactions = await _repository.fetchTransactions();
      if (!mounted) {
        return;
      }
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showSnackBar(_friendlyError(e), isError: true);
    }
  }

  List<TransactionModel> get _filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((transaction) {
      switch (_activeFilter) {
        case TransactionFilter.income:
          return transaction.isIncome;
        case TransactionFilter.expense:
          return transaction.isExpense;
        case TransactionFilter.thisMonth:
          return transaction.transactionDate.year == now.year &&
              transaction.transactionDate.month == now.month;
        case TransactionFilter.pending:
          return transaction.paymentStatus != 'paid';
        case TransactionFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _openAddTransactionSheet() async {
    final created = await showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTransactionSheet(),
    );

    if (created == null) {
      return;
    }

    try {
      await _repository.addTransaction(created);
      await _loadTransactions();
      if (!mounted) {
        return;
      }
      _showSnackBar('İşlem başarıyla kaydedildi.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_friendlyError(e), isError: true);
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    try {
      await _repository.deleteTransaction(transaction.id);
      await _loadTransactions();
      if (!mounted) {
        return;
      }
      _showSnackBar('İşlem silindi.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_friendlyError(e), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('giriş')) {
      return message;
    }
    return message.isEmpty ? 'Finans işlemi sırasında bir sorun oluştu.' : message;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;

    return PageScaffold(
      title: 'Finans',
      subtitle: 'Gelir, gider ve net kâr durumunuzu takip edin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadTransactions,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transactionsFab',
        onPressed: _openAddTransactionSheet,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İşlem'),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _FinanceSummaryGrid(
                  transactions: _transactions,
                  currency: _currency,
                ),
                const SizedBox(height: 16),
                _FinanceInsightCard(transactions: _transactions),
                const SizedBox(height: 16),
                _FilterBar(
                  activeFilter: _activeFilter,
                  onChanged: (filter) => setState(() => _activeFilter = filter),
                ),
                const SizedBox(height: 16),
                if (filteredTransactions.isEmpty)
                  _EmptyFinanceState(onCreate: _openAddTransactionSheet)
                else
                  ...filteredTransactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionCard(
                        transaction: transaction,
                        onDelete: () => _deleteTransaction(transaction),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FinanceSummaryGrid extends StatelessWidget {
  const _FinanceSummaryGrid({
    required this.transactions,
    required this.currency,
  });

  final List<TransactionModel> transactions;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final income = totalIncome(transactions);
    final expense = totalExpense(transactions);
    final profit = netProfit(transactions);
    final ratio = expenseIncomeRatio(transactions);
    final pending = pendingPaymentsTotal(transactions);
    final receivable = receivablesTotal(transactions);

    final cards = [
      _SummaryData(
        title: 'Toplam Gelir',
        value: currency.format(income),
        description: 'Kaydedilen tüm gelir toplamı',
        icon: Icons.trending_up,
        color: AppColors.success,
      ),
      _SummaryData(
        title: 'Toplam Gider',
        value: currency.format(expense),
        description: 'Kaydedilen tüm gider toplamı',
        icon: Icons.trending_down,
        color: AppColors.danger,
      ),
      _SummaryData(
        title: 'Net Kâr/Zarar',
        value: currency.format(profit),
        description: profit >= 0 ? 'Pozitif finansal denge' : 'Gider baskısı dikkat çekiyor',
        icon: Icons.account_balance_wallet_outlined,
        color: profit >= 0 ? AppColors.gold500 : AppColors.warning,
      ),
      _SummaryData(
        title: 'Gider/Gelir Oranı',
        value: '${(ratio * 100).toStringAsFixed(0)}%',
        description: 'Gelire göre gider yükü',
        icon: Icons.pie_chart_outline,
        color: AppColors.info,
      ),
      _SummaryData(
        title: 'Bekleyen Ödemeler',
        value: currency.format(pending),
        description: 'Ödenmemiş gider yükümlülükleri',
        icon: Icons.payments_outlined,
        color: AppColors.warning,
      ),
      _SummaryData(
        title: 'Tahsil Edilecek Tutar',
        value: currency.format(receivable),
        description: 'Bekleyen gelir tahsilatları',
        icon: Icons.request_quote_outlined,
        color: AppColors.gold400,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 1180) {
          columns = 3;
        } else if (constraints.maxWidth >= 760) {
          columns = 2;
        }

        final itemWidth = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: SmartCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: card.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(card.icon, color: card.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                card.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          card.value,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: card.color),
                        ),
                        const SizedBox(height: 6),
                        Text(card.description, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FinanceInsightCard extends StatelessWidget {
  const _FinanceInsightCard({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ AI Finans Yorumu',
            subtitle: 'Kayıtlarınıza göre oluşturulan hızlı yönetim notu',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _commentForTransactions(transactions),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  String _commentForTransactions(List<TransactionModel> transactions) {
    final income = totalIncome(transactions);
    final expense = totalExpense(transactions);
    final pending = transactions.any((transaction) => transaction.paymentStatus != 'paid');

    if (income == 0) {
      return 'İlk gelir kaydınızı ekleyerek kârlılık analizini başlatabilirsiniz.';
    }
    if (income > 0 && expense > income * 0.7) {
      return 'Gider oranınız yüksek görünüyor. Kategori bazlı giderleri incelemeniz önerilir.';
    }
    if (pending) {
      return 'Bekleyen ödemeler nakit akışı tahminini etkileyebilir.';
    }
    return 'Finansal kayıtlarınız düzenli görünüyor.';
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activeFilter,
    required this.onChanged,
  });

  final TransactionFilter activeFilter;
  final ValueChanged<TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <(TransactionFilter, String)>[
      (TransactionFilter.all, 'Tümü'),
      (TransactionFilter.income, 'Gelirler'),
      (TransactionFilter.expense, 'Giderler'),
      (TransactionFilter.thisMonth, 'Bu Ay'),
      (TransactionFilter.pending, 'Bekleyenler'),
    ];

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Filtreler',
            subtitle: 'İşlem görünümünü ihtiyacınıza göre daraltın',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: filters
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter.$2),
                    selected: activeFilter == filter.$1,
                    onSelected: (_) => onChanged(filter.$1),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? AppColors.success : AppColors.danger;
    final dateLabel = DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.transactionDate);

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.isIncome ? 'Gelir' : 'Gider',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Sil'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(transaction.category, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                transaction.formattedAmount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(icon: Icons.calendar_today_outlined, label: dateLabel),
              _MetaChip(icon: Icons.credit_score_outlined, label: _paymentStatusText(transaction.paymentStatus)),
            ],
          ),
          if ((transaction.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              transaction.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _paymentStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'overdue':
        return 'Gecikti';
      default:
        return 'Ödendi';
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold500),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _EmptyFinanceState extends StatelessWidget {
  const _EmptyFinanceState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 42, color: AppColors.gold500),
          const SizedBox(height: 12),
          Text(
            'Henüz gelir-gider kaydı yok.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk işleminizi ekleyerek finansal takibi ve SmartKOBİ analizlerini başlatın.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('İlk İşlemi Ekle'),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'income';
  String _paymentStatus = 'paid';
  DateTime _transactionDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.navy900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Yeni İşlem', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Gelir veya gider kaydı oluşturarak finans görünümünü güncelleyin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'income',
                        icon: Icon(Icons.trending_up),
                        label: Text('Gelir'),
                      ),
                      ButtonSegment<String>(
                        value: 'expense',
                        icon: Icon(Icons.trending_down),
                        label: Text('Gider'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() => _type = value.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Başlık gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kategori gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tutar',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tutar gerekli';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined, color: AppColors.gold500),
                    title: const Text('Tarih'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_transactionDate)),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme Durumu',
                      prefixIcon: Icon(Icons.credit_score_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Ödendi')),
                      DropdownMenuItem(value: 'pending', child: Text('Bekliyor')),
                      DropdownMenuItem(value: 'overdue', child: Text('Gecikti')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim().replaceAll(',', '.'));
    final now = DateTime.now();

    Navigator.pop(
      context,
      TransactionModel(
        id: '',
        userId: '',
        businessId: null,
        type: _type,
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        amount: amount,
        transactionDate: _transactionDate,
        paymentStatus: _paymentStatus,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;
}
