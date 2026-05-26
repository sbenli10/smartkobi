import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customer_transaction_model.dart';
import '../../data/repositories/customers_repository.dart';
import 'customer_calculations.dart';
import 'widgets/collection_reminder_sheet.dart';

class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final CustomersRepository _repository = CustomersRepository();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  CustomerModel? _customer;
  List<CustomerTransactionModel> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final customer = await _repository.getCustomerById(widget.customerId);
      final transactions = await _repository.fetchCustomerTransactions(widget.customerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _customer = customer;
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openAddTransactionSheet() async {
    if (_customer == null) {
      return;
    }

    final transaction = await showModalBottomSheet<CustomerTransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCustomerTransactionSheet(customer: _customer!),
    );

    if (transaction == null) {
      return;
    }

    try {
      await _repository.addCustomerTransaction(transaction);
      await _loadData();
      if (!mounted) {
        return;
      }
      _showSnackBar('Cari hareket kaydedildi.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _copyText(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(message);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    final overdueExists = _transactions.any((transaction) => transaction.isOverdue);
    final toplamBekleyenTutar = pendingAmount(_transactions);

    return PageScaffold(
      title: customer?.name ?? 'Cari Detayı',
      subtitle: 'Müşteri detayları, tahsilatlar ve risk görünümü.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadData,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customerTransactionFab',
        onPressed: _openAddTransactionSheet,
        icon: const Icon(Icons.add),
        label: const Text('Cari Hareket Ekle'),
      ),
      child: _loading
          ? const Center(child: Text('Cari kayıtlar yükleniyor...'))
          : customer == null
              ? const Center(
                  child: Text('Cari kayıtlar alınamadı. Lütfen bağlantınızı kontrol edin.'),
                )
              : ListView(
                  children: [
                    _CustomerHeroCard(customer: customer),
                    if (overdueExists) ...[
                      const SizedBox(height: 16),
                      const _OverdueWarningCard(),
                    ],
                    const SizedBox(height: 16),
                    _CustomerSummaryCards(
                      transactions: _transactions,
                      currency: _currency,
                    ),
                    const SizedBox(height: 16),
                    _CustomerAiInsightCard(
                      customer: customer,
                      transactions: _transactions,
                    ),
                    const SizedBox(height: 16),
                    _ReminderCard(
                      customer: customer,
                      pendingAmountValue: toplamBekleyenTutar,
                      onCopy: () => _copyText(
                        'Tahsilat mesajı hazırlamak için asistana dokunun.',
                        'Tahsilat asistanı kartı hazır.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SmartCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Cari Hareketler',
                            subtitle: 'Tarih, vade ve ödeme durumuna göre hareket geçmişi',
                          ),
                          const SizedBox(height: 16),
                          if (_transactions.isEmpty)
                            const Text('Bu müşteri için henüz cari hareket kaydı yok.')
                          else
                            ..._transactions.map(
                              (transaction) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CustomerTransactionTile(
                                  transaction: transaction,
                                  currency: _currency,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CustomerHeroCard extends StatelessWidget {
  const _CustomerHeroCard({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                    if ((customer.contactName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(customer.contactName!, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ],
                ),
              ),
              _RiskPill(level: customer.riskLevel),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if ((customer.phone ?? '').trim().isNotEmpty)
                _MetaPill(icon: Icons.phone_outlined, text: customer.phone!),
              if ((customer.email ?? '').trim().isNotEmpty)
                _MetaPill(icon: Icons.email_outlined, text: customer.email!),
              if ((customer.city ?? '').trim().isNotEmpty)
                _MetaPill(icon: Icons.location_city_outlined, text: customer.city!),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.gold500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Cari Bakiye', style: Theme.of(context).textTheme.bodyMedium),
                ),
                Text(
                  customer.displayBalance,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.gold500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSummaryCards extends StatelessWidget {
  const _CustomerSummaryCards({
    required this.transactions,
    required this.currency,
  });

  final List<CustomerTransactionModel> transactions;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final lastTransaction = transactions.isEmpty
        ? null
        : transactions.map((item) => item.transactionDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final cards = [
      _DetailMetric(
        title: 'Toplam Alacak',
        value: currency.format(totalReceivables(transactions)),
        color: AppColors.gold500,
        icon: Icons.request_quote_outlined,
      ),
      _DetailMetric(
        title: 'Toplam Tahsilat',
        value: currency.format(totalPayments(transactions)),
        color: AppColors.success,
        icon: Icons.payments_outlined,
      ),
      _DetailMetric(
        title: 'Bekleyen Tutar',
        value: currency.format(pendingAmount(transactions)),
        color: AppColors.warning,
        icon: Icons.timelapse_outlined,
      ),
      _DetailMetric(
        title: 'Geciken Tutar',
        value: currency.format(overdueAmount(transactions)),
        color: AppColors.danger,
        icon: Icons.warning_amber_outlined,
      ),
      _DetailMetric(
        title: 'Ort. Tahsilat Gecikmesi',
        value: '${averageDelayDays(transactions).toStringAsFixed(0)} gün',
        color: AppColors.info,
        icon: Icons.schedule_outlined,
      ),
      _DetailMetric(
        title: 'Son İşlem Tarihi',
        value: lastTransaction == null ? '-' : DateFormat('dd.MM.yyyy').format(lastTransaction),
        color: AppColors.gold400,
        icon: Icons.history,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 1100) {
          columns = 3;
        } else if (constraints.maxWidth >= 720) {
          columns = 2;
        }
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: SmartCard(
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: card.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(card.icon, color: card.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.title, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                card.value,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: card.color),
                              ),
                            ],
                          ),
                        ),
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

class _CustomerAiInsightCard extends StatelessWidget {
  const _CustomerAiInsightCard({
    required this.customer,
    required this.transactions,
  });

  final CustomerModel customer;
  final List<CustomerTransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ AI Cari Analizi',
            subtitle: 'Tahsilat geçmişi ve bakiye görünümüne göre yorum',
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
              generateCustomerAiInsight(customer, transactions),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

// _ReminderCard TANIMLAMASI VE İÇİNDEKİ MODAL ÇAĞRISI (Eğer ayrı bir widget olarak yazıldıysa):
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.customer,
    required this.pendingAmountValue,
    required this.onCopy,
  });

  final CustomerModel customer;
  final double pendingAmountValue;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CollectionReminderSheet(
            customer: customer,
            totalAmount: pendingAmountValue,
          ),
        );
      },
      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.success),
      label: const Text(
        'Tahsilat Mesajı',
        style: TextStyle(color: AppColors.success),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.success),
      ),
    );
  }
}

class _OverdueWarningCard extends StatelessWidget {
  const _OverdueWarningCard();

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu müşteride geciken tahsilat bulunuyor.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTransactionTile extends StatelessWidget {
  const _CustomerTransactionTile({
    required this.transaction,
    required this.currency,
  });

  final CustomerTransactionModel transaction;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final dueLabel = transaction.dueDate == null
        ? '-'
        : DateFormat('dd.MM.yyyy').format(transaction.dueDate!);
    final color = transaction.isReceivable ? AppColors.gold500 : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypePill(type: transaction.type),
              const Spacer(),
              Text(
                currency.format(transaction.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(transaction.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                text: DateFormat('dd.MM.yyyy').format(transaction.transactionDate),
              ),
              _MetaPill(icon: Icons.event_outlined, text: 'Vade: $dueLabel'),
              _MetaPill(
                icon: Icons.credit_score_outlined,
                text: _paymentStatusLabel(transaction.paymentStatus),
              ),
            ],
          ),
          if ((transaction.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(transaction.description!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Ödendi';
      case 'overdue':
        return 'Gecikti';
      default:
        return 'Bekliyor';
    }
  }
}

class _AddCustomerTransactionSheet extends StatefulWidget {
  const _AddCustomerTransactionSheet({required this.customer});

  final CustomerModel customer;

  @override
  State<_AddCustomerTransactionSheet> createState() => _AddCustomerTransactionSheetState();
}

class _AddCustomerTransactionSheetState extends State<_AddCustomerTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'receivable';
  String _paymentStatus = 'pending';
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
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
                  Text('Cari Hareket Ekle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(widget.customer.name, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tür',
                      prefixIcon: Icon(Icons.swap_horiz_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'receivable', child: Text('Alacak')),
                      DropdownMenuItem(value: 'payment', child: Text('Tahsilat')),
                      DropdownMenuItem(value: 'debt', child: Text('Borç')),
                      DropdownMenuItem(value: 'adjustment', child: Text('Düzeltme')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Başlık gerekli';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) {
                        return 'Negatif olmayan tutar girin';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tutar',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined, color: AppColors.gold500),
                    title: const Text('İşlem tarihi'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_transactionDate)),
                    onTap: _pickTransactionDate,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined, color: AppColors.gold500),
                    title: const Text('Vade tarihi'),
                    subtitle: Text(
                      _dueDate == null ? 'Belirtilmedi' : DateFormat('dd.MM.yyyy').format(_dueDate!),
                    ),
                    onTap: _pickDueDate,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme durumu',
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

  Future<void> _pickTransactionDate() async {
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final amount = double.parse(_amountController.text.trim().replaceAll(',', '.'));

    Navigator.pop(
      context,
      CustomerTransactionModel(
        id: '',
        userId: '',
        customerId: widget.customer.id,
        businessId: widget.customer.businessId,
        type: _type,
        title: _titleController.text.trim(),
        amount: amount,
        transactionDate: _transactionDate,
        dueDate: _dueDate,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (level) {
      case 'high':
        color = AppColors.danger;
        label = 'Yüksek Risk';
        break;
      case 'medium':
        color = AppColors.warning;
        label = 'Orta Risk';
        break;
      default:
        color = AppColors.success;
        label = 'Düşük Risk';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (type) {
      case 'payment':
        label = 'Tahsilat';
        color = AppColors.success;
        break;
      case 'debt':
        label = 'Borç';
        color = AppColors.warning;
        break;
      case 'adjustment':
        label = 'Düzeltme';
        color = AppColors.info;
        break;
      default:
        label = 'Alacak';
        color = AppColors.gold500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _DetailMetric {
  const _DetailMetric({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
}
