import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customers_repository.dart';
import 'customer_detail_page.dart';

enum CustomerFilter { all, receivable, overdue, highRisk, lowRisk }

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomersRepository _repository = CustomersRepository();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  List<CustomerModel> _customers = [];
  bool _loading = true;
  String _searchQuery = '';
  CustomerFilter _filter = CustomerFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final customers = await _repository.fetchCustomers();
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = customers;
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

  List<CustomerModel> get _filteredCustomers {
    final query = _searchQuery.toLowerCase();
    return _customers.where((customer) {
      final matchesQuery = query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          (customer.phone ?? '').toLowerCase().contains(query) ||
          (customer.email ?? '').toLowerCase().contains(query);

      if (!matchesQuery) {
        return false;
      }

      switch (_filter) {
        case CustomerFilter.receivable:
          return customer.currentBalance > 0;
        case CustomerFilter.overdue:
          return customer.hasOverdueCollection;
        case CustomerFilter.highRisk:
          return customer.isHighRisk;
        case CustomerFilter.lowRisk:
          return customer.riskLevel == 'low';
        case CustomerFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _openAddCustomerSheet() async {
    final customer = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );

    if (customer == null) {
      return;
    }

    try {
      await _repository.addCustomer(customer);
      await _loadCustomers();
      if (!mounted) {
        return;
      }
      _showSnackBar('Cari hesap başarıyla oluşturuldu.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
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

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return PageScaffold(
      title: 'Cari',
      subtitle: 'Cari hesap, alacak ve tahsilat durumunu takip edin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadCustomers,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customersFab',
        onPressed: _openAddCustomerSheet,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Yeni cari ekle'),
      ),
      child: _loading
          ? const Center(child: Text('Cari kayıtlar yükleniyor...'))
          : ListView(
              children: [
                _CustomerSummaryGrid(customers: _customers, currency: _currency),
                const SizedBox(height: 16),
                _CustomersInsightCard(customers: _customers),
                const SizedBox(height: 16),
                SmartCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Arama ve filtre',
                        subtitle: 'Cari adı, telefon veya e-posta ile filtreleyin',
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          labelText: 'Cari ara',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildFilterChip('Tümü', CustomerFilter.all),
                          _buildFilterChip('Alacaklı', CustomerFilter.receivable),
                          _buildFilterChip('Geciken', CustomerFilter.overdue),
                          _buildFilterChip('Yüksek Risk', CustomerFilter.highRisk),
                          _buildFilterChip('Düşük Risk', CustomerFilter.lowRisk),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (customers.isEmpty)
                  _EmptyCustomersState(onCreate: _openAddCustomerSheet)
                else
                  ...customers.map(
                    (customer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CustomerCard(customer: customer),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, CustomerFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }
}

class _CustomerSummaryGrid extends StatelessWidget {
  const _CustomerSummaryGrid({
    required this.customers,
    required this.currency,
  });

  final List<CustomerModel> customers;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final totalReceivable = customers.fold<double>(
      0,
      (sum, customer) => sum + (customer.currentBalance > 0 ? customer.currentBalance : 0),
    );
    final overdueTotal = customers.fold<double>(
      0,
      (sum, customer) => sum + (customer.hasOverdueCollection ? customer.currentBalance : 0),
    );
    final highRiskCount = customers.where((customer) => customer.isHighRisk).length;

    final items = [
      _SummaryItem(
        title: 'Toplam cari',
        value: customers.length.toString(),
        subtitle: 'Aktif cari hesap adedi',
        icon: Icons.people_alt_outlined,
        color: AppColors.gold500,
      ),
      _SummaryItem(
        title: 'Toplam Alacak',
        value: currency.format(totalReceivable),
        subtitle: 'Pozitif bakiye taşıyan cari toplamı',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
      ),
      _SummaryItem(
        title: 'Geciken tahsilat',
        value: currency.format(overdueTotal),
        subtitle: 'Vadesi geçmiş açık alacaklar',
        icon: Icons.warning_amber_outlined,
        color: AppColors.warning,
      ),
      _SummaryItem(
        title: 'Yüksek riskli cari',
        value: highRiskCount.toString(),
        subtitle: 'Öncelikli takip gerektiren hesaplar',
        icon: Icons.priority_high_outlined,
        color: AppColors.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 720) {
          columns = 2;
        }

        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
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
                                color: item.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.value,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: item.color),
                        ),
                        const SizedBox(height: 6),
                        Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
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

class _CustomersInsightCard extends StatelessWidget {
  const _CustomersInsightCard({required this.customers});

  final List<CustomerModel> customers;

  @override
  Widget build(BuildContext context) {
    String message;
    if (customers.isEmpty) {
      message =
          'Cari hesaplarınızı eklediğinizde SmartKOBİ tahsilat risklerini ve cari bakiyeleri analiz eder.';
    } else if (customers.any((customer) => customer.hasOverdueCollection)) {
      message =
          'Bazı cari hesaplarda geciken tahsilatlar görünüyor. Öncelikli bir tahsilat planı oluşturmanız önerilir.';
    } else if (customers.any((customer) => customer.isHighRisk)) {
      message =
          'Yüksek riskli cari hesaplar için yeni satışlarda peşinat veya kısa vade önerilir.';
    } else {
      message = 'Cari hesaplarınız düzenli görünüyor.';
    }

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ yapay zekâ cari yorumu',
            subtitle: 'Cari görünümünüze göre oluşturulan kısa yorum',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return SmartCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailPage(customerId: customer.id),
          ),
        );
      },
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
                    Text(customer.name, style: Theme.of(context).textTheme.titleMedium),
                    if ((customer.contactName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        customer.contactName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              _RiskBadge(level: customer.riskLevel),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if ((customer.phone ?? '').trim().isNotEmpty)
                _InfoChip(icon: Icons.phone_outlined, text: customer.phone!),
              if ((customer.email ?? '').trim().isNotEmpty)
                _InfoChip(icon: Icons.mail_outline, text: customer.email!),
              if (customer.lastTransactionDate != null)
                _InfoChip(
                  icon: Icons.history,
                  text: 'Son işlem: ${dateFormat.format(customer.lastTransactionDate!)}',
                ),
              if (customer.nextCollectionDate != null)
                _InfoChip(
                  icon: Icons.event_available_outlined,
                  text: 'Tahsilat: ${dateFormat.format(customer.nextCollectionDate!)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BalanceBox(
                  title: 'Cari bakiye',
                  value: customer.displayBalance,
                  color: customer.currentBalance >= 0 ? AppColors.gold500 : AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceBox(
                  title: 'Şehir',
                  value: (customer.city ?? '').isEmpty ? '-' : customer.city!,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if ((customer.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              customer.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');
  final _paymentTermController = TextEditingController(text: '30');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    _paymentTermController.dispose();
    _notesController.dispose();
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
                  Text('Yeni cari ekle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Cari takibini başlatmak için temel bilgileri girin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildField(_nameController, 'Cari adı', Icons.business_outlined,
                      validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Cari adını girin';
                    }
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _buildField(_contactController, 'Yetkili kişi', Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildField(_phoneController, 'Telefon', Icons.phone_outlined),
                  const SizedBox(height: 12),
                  _buildField(
                    _emailController,
                    'E-posta',
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(_taxController, 'Vergi no', Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _buildField(_cityController, 'Şehir', Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  _buildField(_addressController, 'Adres', Icons.location_on_outlined, maxLines: 2),
                  const SizedBox(height: 12),
                  _buildField(
                    _openingBalanceController,
                    'Açılış bakiyesi',
                    Icons.account_balance_wallet_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    _paymentTermController,
                    'Ödeme vadesi (gün)',
                    Icons.schedule_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Negatif olmayan bir gün girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(_notesController, 'Notlar', Icons.notes_outlined, maxLines: 3),
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

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return 'Negatif olmayan bir tutar girin';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final openingBalance =
        double.parse(_openingBalanceController.text.trim().replaceAll(',', '.'));

    Navigator.pop(
      context,
      CustomerModel(
        id: '',
        userId: '',
        businessId: null,
        name: _nameController.text.trim(),
        contactName: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        taxNumber: _taxController.text.trim().isEmpty ? null : _taxController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        openingBalance: openingBalance,
        currentBalance: openingBalance,
        riskLevel: 'low',
        paymentTermDays: int.parse(_paymentTermController.text.trim()),
        lastTransactionDate: null,
        nextCollectionDate: null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _EmptyCustomersState extends StatelessWidget {
  const _EmptyCustomersState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        children: [
          const Icon(Icons.groups_outlined, size: 44, color: AppColors.gold500),
          const SizedBox(height: 12),
          Text('Henüz cari hesap bulunmuyor.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'İlk cari hesabınızı ekleyerek cari bakiye, tahsilat ve risk takibini başlatabilirsiniz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('İlk cariyi ekle'),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (level) {
      case 'high':
        color = AppColors.danger;
        label = 'Yüksek';
        break;
      case 'medium':
        color = AppColors.warning;
        label = 'Orta';
        break;
      default:
        color = AppColors.success;
        label = 'Düşük';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

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

class _BalanceBox extends StatelessWidget {
  const _BalanceBox({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}
