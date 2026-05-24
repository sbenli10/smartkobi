import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/repositories/inventory_repository.dart';
import 'barcode_scanner_page.dart';
import 'inventory_calculations.dart';
import 'inventory_detail_page.dart';

enum InventoryFilter {
  all,
  critical,
  inStock,
  outOfStock,
  lowMargin,
  inactive,
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryRepository _repository = InventoryRepository();

  List<InventoryItemModel> _items = [];
  bool _loading = true;
  String _searchQuery = '';
  InventoryFilter _filter = InventoryFilter.all;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final items = await _repository.fetchInventoryItems();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  List<InventoryItemModel> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final sku = item.sku?.toLowerCase() ?? '';
      final barcode = item.barcode?.toLowerCase() ?? '';
      final category = item.category?.toLowerCase() ?? '';
      final name = item.name.toLowerCase();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          sku.contains(query) ||
          barcode.contains(query) ||
          category.contains(query);

      if (!matchesQuery) return false;

      switch (_filter) {
        case InventoryFilter.critical:
          return item.isCriticalStock;
        case InventoryFilter.inStock:
          return !item.isOutOfStock;
        case InventoryFilter.outOfStock:
          return item.isOutOfStock;
        case InventoryFilter.lowMargin:
          return item.profitMarginPercent < 15;
        case InventoryFilter.inactive:
          return !item.isActive;
        case InventoryFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _openAddItemSheet({String? initialBarcode}) async {
    final item = await showModalBottomSheet<InventoryItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddInventoryItemSheet(initialBarcode: initialBarcode),
    );

    if (item == null) return;

    try {
      final created = await _repository.addInventoryItem(
        item.copyWith(stockQuantity: 0),
      );

      if (item.stockQuantity > 0) {
        await _repository.addStockMovement(
          StockMovementModel(
            id: '',
            userId: '',
            inventoryItemId: created.id,
            businessId: created.businessId,
            movementType: 'in',
            quantity: item.stockQuantity,
            unitPrice: item.purchasePrice,
            movementDate: DateTime.now(),
            referenceNo: 'Açılış',
            note: 'Başlangıç stoğu',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      await _loadItems();

      if (!mounted) return;
      _showSnackBar('Ürün başarıyla kaydedildi.');
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _scanBarcode() async {
    if (kIsWeb) {
      _showSnackBar(
        'Barkod tarama mobil cihazda kullanılabilir.',
        isError: true,
      );
      return;
    }

    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    final code = scannedCode?.trim();
    if (code == null || code.isEmpty) return;

    try {
      final existing = await _repository.getInventoryItemByBarcode(code);

      if (!mounted) return;

      if (existing != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventoryDetailPage(itemId: existing.id),
          ),
        );
        return;
      }

      await _openAddItemSheet(initialBarcode: code);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _openItemDetail(InventoryItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryDetailPage(itemId: item.id),
      ),
    );
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
    final items = _filteredItems;

    return PageScaffold(
      title: 'Stok',
      subtitle: 'Ürün, stok, fiyat ve kâr marjı durumunuzu takip edin.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadItems,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: _scanBarcode,
          tooltip: 'Barkod Tara',
          icon: const Icon(Icons.qr_code_scanner),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventoryFab',
        onPressed: () => _openAddItemSheet(),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Yeni Ürün'),
      ),
      child: _loading
          ? const Center(child: Text('Stok kayıtları yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: ListView(
                children: [
                  _InventorySummaryCards(items: _items),
                  const SizedBox(height: 16),
                  _InventoryAiInsightCard(items: _items),
                  const SizedBox(height: 16),
                  SmartCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Arama ve Filtre',
                          subtitle:
                              'Ürün adı, SKU, barkod veya kategori ile arayın.',
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Ürün ara',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildFilterChip('Tümü', InventoryFilter.all),
                            _buildFilterChip(
                              'Kritik Stok',
                              InventoryFilter.critical,
                            ),
                            _buildFilterChip(
                              'Stokta Var',
                              InventoryFilter.inStock,
                            ),
                            _buildFilterChip(
                              'Stokta Yok',
                              InventoryFilter.outOfStock,
                            ),
                            _buildFilterChip(
                              'Düşük Kâr Marjı',
                              InventoryFilter.lowMargin,
                            ),
                            _buildFilterChip(
                              'Pasif Ürünler',
                              InventoryFilter.inactive,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _EmptyInventoryState(onCreate: _openAddItemSheet)
                  else
                    ...items.map(
                      (item) => Padding(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InventoryItemCard(
                          item: item,
                          onTap: () => _openItemDetail(item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, InventoryFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) {
        setState(() => _filter = filter);
      },
    );
  }
}

class _InventorySummaryCards extends StatelessWidget {
  const _InventorySummaryCards({required this.items});

  final List<InventoryItemModel> items;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        title: 'Toplam Ürün',
        value: totalProductCount(items).toString(),
        subtitle: 'Aktif ve pasif tüm ürünler',
        icon: Icons.inventory_2_outlined,
        color: AppColors.gold500,
      ),
      _SummaryCardData(
        title: 'Toplam Alış Değeri',
        value: AppFormatters.formatCurrency(totalStockValue(items)),
        subtitle: 'Alış fiyatına göre stok büyüklüğü',
        icon: Icons.savings_outlined,
        color: AppColors.info,
      ),
      _SummaryCardData(
        title: 'Kritik Stok',
        value: criticalStockCount(items).toString(),
        subtitle: 'Minimum seviyeye yaklaşan ürünler',
        icon: Icons.warning_amber_outlined,
        color: AppColors.warning,
      ),
      _SummaryCardData(
        title: 'Stokta Olmayan',
        value: outOfStockCount(items).toString(),
        subtitle: 'Satış fırsatı kaybı riski taşıyan ürünler',
        icon: Icons.remove_shopping_cart_outlined,
        color: AppColors.danger,
      ),
      _SummaryCardData(
        title: 'Ortalama Kâr Marjı',
        value: AppFormatters.formatPercent(averageProfitMargin(items)),
        subtitle: 'Ürün portföyü kârlılık ortalaması',
        icon: Icons.percent_outlined,
        color: AppColors.gold400,
      ),
      _SummaryCardData(
        title: 'Toplam Satış Değeri',
        value: AppFormatters.formatCurrency(totalSaleValue(items)),
        subtitle: 'Satış fiyatı üzerinden potansiyel değer',
        icon: Icons.sell_outlined,
        color: AppColors.success,
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
          children: cards.map((card) {
            return SizedBox(
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
                            color: card.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(card.icon, color: card.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            card.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      card.value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: card.color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InventoryAiInsightCard extends StatelessWidget {
  const _InventoryAiInsightCard({required this.items});

  final List<InventoryItemModel> items;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ AI Stok Yorumu',
            subtitle: 'Stok ve kârlılık görünümüne göre hızlı yorum',
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
              generateInventoryAiInsight(items),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.onTap,
  });

  final InventoryItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final codeParts = <String>[
      if ((item.sku ?? '').trim().isNotEmpty) 'SKU: ${item.sku}',
      if ((item.barcode ?? '').trim().isNotEmpty) 'Barkod: ${item.barcode}',
    ];

    return SmartCard(
      onTap: onTap,
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
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      codeParts.isEmpty
                          ? 'Tanımsız ürün kodu'
                          : codeParts.join('  |  '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _StatusBadge(item: item),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if ((item.category ?? '').trim().isNotEmpty)
                _MetaChip(
                  icon: Icons.category_outlined,
                  text: item.category!,
                ),
              _MetaChip(
                icon: Icons.inventory_2_outlined,
                text: AppFormatters.formatQuantity(
                  item.stockQuantity,
                  unit: item.unit,
                ),
              ),
              _MetaChip(
                icon: Icons.warning_outlined,
                text:
                    'Min: ${AppFormatters.formatQuantity(item.minStockLevel, unit: item.unit)}',
              ),
              if (item.lastMovementDate != null)
                _MetaChip(
                  icon: Icons.history,
                  text:
                      'Son hareket: ${AppFormatters.formatDateTr(item.lastMovementDate!)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;

              if (isNarrow) {
                return Column(
                  children: [
                    _ValueBox(
                      title: 'Alış',
                      value: AppFormatters.formatCurrency(item.purchasePrice),
                      color: AppColors.info,
                    ),
                    const SizedBox(height: 10),
                    _ValueBox(
                      title: 'Satış',
                      value: AppFormatters.formatCurrency(item.salePrice),
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 10),
                    _ValueBox(
                      title: 'Kâr Marjı',
                      value:
                          AppFormatters.formatPercent(item.profitMarginPercent),
                      color: item.profitMarginPercent < 15
                          ? AppColors.warning
                          : AppColors.gold500,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _ValueBox(
                      title: 'Alış',
                      value: AppFormatters.formatCurrency(item.purchasePrice),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ValueBox(
                      title: 'Satış',
                      value: AppFormatters.formatCurrency(item.salePrice),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ValueBox(
                      title: 'Kâr Marjı',
                      value:
                          AppFormatters.formatPercent(item.profitMarginPercent),
                      color: item.profitMarginPercent < 15
                          ? AppColors.warning
                          : AppColors.gold500,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Toplam alış değeri: ${AppFormatters.formatCurrency(item.stockValue)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if ((item.supplierName ?? '').trim().isNotEmpty)
                Text(
                  'Tedarikçi: ${item.supplierName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddInventoryItemSheet extends StatefulWidget {
  const _AddInventoryItemSheet({this.initialBarcode});

  final String? initialBarcode;

  @override
  State<_AddInventoryItemSheet> createState() => _AddInventoryItemSheetState();
}

class _AddInventoryItemSheetState extends State<_AddInventoryItemSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  late final TextEditingController _barcodeController =
      TextEditingController(text: widget.initialBarcode ?? '');
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController(text: 'adet');
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');
  final _purchasePriceController = TextEditingController(text: '0');
  final _salePriceController = TextEditingController(text: '0');
  final _supplierNameController = TextEditingController();
  final _supplierPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
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
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Yeni Ürün',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ürünü, fiyat bilgisini ve başlangıç stok miktarını tanımlayın.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    _nameController,
                    'Ürün adı',
                    Icons.inventory_2_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ürün adı zorunlu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(_skuController, 'SKU', Icons.tag_outlined),
                  const SizedBox(height: 12),
                  _field(_barcodeController, 'Barkod', Icons.qr_code_outlined),
                  const SizedBox(height: 12),
                  _field(
                    _categoryController,
                    'Kategori',
                    Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _unitController,
                    'Birim (adet, kg vs.)',
                    Icons.straighten_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Birim zorunlu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _stockController,
                    'Başlangıç stok miktarı',
                    Icons.add_box_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _minStockController,
                    'Minimum stok seviyesi',
                    Icons.warning_amber_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _purchasePriceController,
                    'Alış fiyatı (₺)',
                    Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _salePriceController,
                    'Satış fiyatı (₺)',
                    Icons.sell_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _supplierNameController,
                    'Tedarikçi adı',
                    Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _supplierPhoneController,
                    'Tedarikçi telefonu',
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _descriptionController,
                    'Açıklama',
                    Icons.notes_outlined,
                    maxLines: 3,
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

  Widget _field(
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

  String? _validateNumber(String? value) {
    final parsed = _parseDouble(value);
    if (parsed == null || parsed < 0) {
      return 'Negatif olmayan bir değer girin';
    }
    return null;
  }

  double _parseDouble(String? value) {
    return double.parse((value ?? '0').trim().replaceAll(',', '.'));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    Navigator.pop(
      context,
      InventoryItemModel(
        id: '',
        userId: '',
        businessId: null,
        name: _nameController.text.trim(),
        sku: _emptyToNull(_skuController.text),
        barcode: _emptyToNull(_barcodeController.text),
        category: _emptyToNull(_categoryController.text),
        unit: _unitController.text.trim(),
        stockQuantity: _parseDouble(_stockController.text),
        minStockLevel: _parseDouble(_minStockController.text),
        purchasePrice: _parseDouble(_purchasePriceController.text),
        salePrice: _parseDouble(_salePriceController.text),
        supplierName: _emptyToNull(_supplierNameController.text),
        supplierPhone: _emptyToNull(_supplierPhoneController.text),
        description: _emptyToNull(_descriptionController.text),
        isActive: true,
        lastMovementDate: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.onCreate});

  final Future<void> Function({String? initialBarcode}) onCreate;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: AppColors.gold500,
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz ürün eklenmedi.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk ürününüzü ekleyerek stok, fiyat ve kâr marjı takibini başlatın.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => onCreate(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Ürünü Ekle'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final InventoryItemModel item;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    if (item.isOutOfStock) {
      color = AppColors.danger;
      label = 'Tükendi';
    } else if (item.isCriticalStock) {
      color = AppColors.warning;
      label = 'Kritik';
    } else {
      color = AppColors.success;
      label = 'Stokta';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
  });

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
          Icon(icon, size: 16, color: AppColors.primaryNavy),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({
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
      width: double.infinity,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
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