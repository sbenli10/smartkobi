import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/repositories/inventory_repository.dart';
import 'inventory_calculations.dart';
import '../../core/utils/formatters.dart';

class InventoryDetailPage extends StatefulWidget {
  const InventoryDetailPage({
    super.key,
    required this.itemId,
  });

  final String itemId;

  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage> {
  final InventoryRepository _repository = InventoryRepository();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  InventoryItemModel? _item;
  List<StockMovementModel> _movements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final item = await _repository.getInventoryItemById(widget.itemId);
      final movements = await _repository.fetchStockMovements(widget.itemId);
      if (!mounted) {
        return;
      }
      setState(() {
        _item = item;
        _movements = movements;
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

  Future<void> _openMovementSheet({String? presetType}) async {
    final item = _item;
    if (item == null) {
      return;
    }
    final movement = await showModalBottomSheet<StockMovementModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStockMovementSheet(item: item, presetType: presetType),
    );
    if (movement == null) {
      return;
    }
    try {
      await _repository.addStockMovement(movement);
      await _loadData();
      if (!mounted) {
        return;
      }
      _showSnackBar('Stok hareketi kaydedildi.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openPriceUpdateDialog() async {
    final item = _item;
    if (item == null) {
      return;
    }
    final purchaseController =
        TextEditingController(text: item.purchasePrice.toStringAsFixed(2));
    final saleController = TextEditingController(text: item.salePrice.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<InventoryItemModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Fiyat Güncelle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: purchaseController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Alış fiyatı'),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: saleController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Satış fiyatı'),
                  validator: _validateNumber,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.pop(
                  context,
                  item.copyWith(
                    purchasePrice:
                        double.parse(purchaseController.text.trim().replaceAll(',', '.')),
                    salePrice: double.parse(saleController.text.trim().replaceAll(',', '.')),
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (updated == null) {
      return;
    }
    try {
      await _repository.updateInventoryItem(updated);
      await _loadData();
      if (!mounted) {
        return;
      }
      _showSnackBar('Fiyat bilgileri güncellendi.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _deactivateItem() async {
    final item = _item;
    if (item == null) {
      return;
    }
    try {
      await _repository.deactivateInventoryItem(item.id);
      await _loadData();
      if (!mounted) {
        return;
      }
      _showSnackBar('Ürün pasifleştirildi.');
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

  String? _validateNumber(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return 'Negatif olmayan bir değer girin';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return PageScaffold(
      title: item?.name ?? 'Ürün Detayı',
      subtitle: 'Stok hareketleri, fiyatlar ve ürün performansı.',
      actions: [
        IconButton(
          onPressed: _loading ? null : _loadData,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventoryMovementFab',
        onPressed: () => _openMovementSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Stok Hareketi Ekle'),
      ),
      child: _loading
          ? const Center(child: Text('Stok kayıtları yükleniyor...'))
          : item == null
              ? const Center(
                  child: Text('Stok kayıtları alınamadı. Lütfen bağlantınızı kontrol edin.'),
                )
              : ListView(
                  children: [
                    _InventoryHeroCard(item: item),
                    if (item.isCriticalStock) ...[
                      const SizedBox(height: 16),
                      const _CriticalStockWarningCard(),
                    ],
                    const SizedBox(height: 16),
                    _InventorySummaryGrid(item: item, currency: _currency),
                    const SizedBox(height: 16),
                    _PriceInfoCard(item: item, currency: _currency),
                    const SizedBox(height: 16),
                    _SupplierInfoCard(item: item),
                    const SizedBox(height: 16),
                    _InventoryAiCard(item: item),
                    const SizedBox(height: 16),
                    _QuickActionsCard(
                      onStockIn: () => _openMovementSheet(presetType: 'in'),
                      onStockOut: () => _openMovementSheet(presetType: 'out'),
                      onPriceUpdate: _openPriceUpdateDialog,
                      onDeactivate: _deactivateItem,
                    ),
                    const SizedBox(height: 16),
                    SmartCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Stok Hareketleri',
                            subtitle: 'Giriş, çıkış, düzeltme ve iade kayıtları',
                          ),
                          const SizedBox(height: 16),
                          if (_movements.isEmpty)
                            const Text('Bu ürün için henüz stok hareketi yok.')
                          else
                            ..._movements.map(
                              (movement) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _StockMovementTile(
                                  movement: movement,
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

class _InventoryHeroCard extends StatelessWidget {
  const _InventoryHeroCard({required this.item});

  final InventoryItemModel item;

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
                    Text(item.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if ((item.sku ?? '').trim().isNotEmpty)
                          _TagPill(label: 'SKU: ${item.sku!}', color: AppColors.info),
                        if ((item.barcode ?? '').trim().isNotEmpty)
                          _TagPill(label: 'Barkod: ${item.barcode!}', color: AppColors.gold400),
                        if ((item.category ?? '').trim().isNotEmpty)
                          _TagPill(label: item.category!, color: AppColors.gold500),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TagPill(label: detectStockStatus(item), color: _statusColor(item)),
                  const SizedBox(height: 8),
                  _TagPill(label: item.isActive ? 'Aktif' : 'Pasif', color: item.isActive ? AppColors.success : AppColors.warning),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(InventoryItemModel item) {
    if (item.isOutOfStock) {
      return AppColors.danger;
    }
    if (item.isCriticalStock) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}

class _InventorySummaryGrid extends StatelessWidget {
  const _InventorySummaryGrid({
    required this.item,
    required this.currency,
  });

  final InventoryItemModel item;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        title: 'Mevcut Stok',
        value: AppFormatters.formatQuantity(item.stockQuantity, unit: item.unit),
        color: AppColors.gold500,
        icon: Icons.inventory_2_outlined,
      ),
      _MetricData(
        title: 'Minimum Stok',
        value: AppFormatters.formatQuantity(item.minStockLevel, unit: item.unit),
        color: AppColors.warning,
        icon: Icons.warning_amber_outlined,
      ),
      _MetricData(
        title: 'Toplam Alış Değeri',
        value: currency.format(item.stockValue),
        color: AppColors.info,
        icon: Icons.savings_outlined,
      ),
      _MetricData(
        title: 'Satış Değeri',
        value: currency.format(item.saleValue),
        color: AppColors.success,
        icon: Icons.sell_outlined,
      ),
      _MetricData(
        title: 'Kâr Marjı',
        value: '%${item.profitMarginPercent.toStringAsFixed(1)}',
        color: item.profitMarginPercent < 15 ? AppColors.warning : AppColors.gold400,
        icon: Icons.percent_outlined,
      ),
      _MetricData(
        title: 'Son Hareket',
        value: item.lastMovementDate == null
            ? '-'
            : DateFormat('dd.MM.yyyy').format(item.lastMovementDate!),
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

class _PriceInfoCard extends StatelessWidget {
  const _PriceInfoCard({
    required this.item,
    required this.currency,
  });

  final InventoryItemModel item;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Fiyat Bilgileri',
            subtitle: 'Maliyet, satış ve birim kâr görünümü',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PriceBox(title: 'Alış Fiyatı', value: currency.format(item.purchasePrice)),
              _PriceBox(title: 'Satış Fiyatı', value: currency.format(item.salePrice)),
              _PriceBox(title: 'Birim Kâr', value: currency.format(item.profitAmount)),
              _PriceBox(
                title: 'Kâr Marjı Yüzdesi',
                value: '%${item.profitMarginPercent.toStringAsFixed(1)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierInfoCard extends StatelessWidget {
  const _SupplierInfoCard({required this.item});

  final InventoryItemModel item;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Tedarikçi Bilgisi',
            subtitle: 'Tedarikçi kontağı ve ürün notları',
          ),
          const SizedBox(height: 12),
          Text(
            (item.supplierName ?? '').isEmpty ? 'Tedarikçi bilgisi girilmemiş.' : item.supplierName!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if ((item.supplierPhone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.supplierPhone!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if ((item.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(item.description!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _InventoryAiCard extends StatelessWidget {
  const _InventoryAiCard({required this.item});

  final InventoryItemModel item;

  @override
  Widget build(BuildContext context) {
    String insight;
    if (item.isCriticalStock) {
      insight = 'Bu ürün kritik stok seviyesinde. Satış kaybı yaşamamak için tedarik planı yapılmalı.';
    } else if (item.profitMarginPercent < 15) {
      insight = 'Bu ürünün kâr marjı düşük. Satış fiyatı veya alış maliyeti gözden geçirilmeli.';
    } else {
      insight = 'Stok ve kâr marjı dengeli görünüyor.';
    }

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'SmartKOBİ AI Ürün Analizi',
            subtitle: 'Stok seviyesi ve fiyat yapısına göre yorum',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(insight, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onStockIn,
    required this.onStockOut,
    required this.onPriceUpdate,
    required this.onDeactivate,
  });

  final VoidCallback onStockIn;
  final VoidCallback onStockOut;
  final VoidCallback onPriceUpdate;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Hızlı Aksiyonlar',
            subtitle: 'Stok ve fiyat yönetimini hızlandırın',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onStockIn,
                icon: const Icon(Icons.add_box_outlined, color: AppColors.gold500),
                label: const Text('Stok Girişi'),
              ),
              OutlinedButton.icon(
                onPressed: onStockOut,
                icon: const Icon(Icons.outbox_outlined, color: AppColors.gold500),
                label: const Text('Stok Çıkışı'),
              ),
              OutlinedButton.icon(
                onPressed: onPriceUpdate,
                icon: const Icon(Icons.sell_outlined, color: AppColors.gold500),
                label: const Text('Fiyat Güncelle'),
              ),
              OutlinedButton.icon(
                onPressed: onDeactivate,
                icon: const Icon(Icons.pause_circle_outline, color: AppColors.gold500),
                label: const Text('Ürünü Pasifleştir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CriticalStockWarningCard extends StatelessWidget {
  const _CriticalStockWarningCard();

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu ürün kritik stok seviyesinde. Yeniden sipariş verilmesi önerilir.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockMovementTile extends StatelessWidget {
  const _StockMovementTile({
    required this.movement,
    required this.currency,
  });

  final StockMovementModel movement;
  final NumberFormat currency;

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
          Row(
            children: [
              _TagPill(label: _typeLabel(movement.movementType), color: _typeColor(movement.movementType)),
              const Spacer(),
              Text(
                movement.quantity.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _typeColor(movement.movementType),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TagPill(
                label: DateFormat('dd.MM.yyyy').format(movement.movementDate),
                color: AppColors.info,
              ),
              _TagPill(
                label: movement.unitPrice == null ? 'Birim fiyat yok' : currency.format(movement.unitPrice),
                color: AppColors.gold400,
              ),
              if ((movement.referenceNo ?? '').trim().isNotEmpty)
                _TagPill(label: 'Ref: ${movement.referenceNo!}', color: AppColors.gold500),
            ],
          ),
          if ((movement.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(movement.note!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'in':
        return 'Giriş';
      case 'out':
        return 'Çıkış';
      case 'return':
        return 'İade';
      default:
        return 'Düzeltme';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'in':
      case 'return':
        return AppColors.success;
      case 'out':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }
}

class _AddStockMovementSheet extends StatefulWidget {
  const _AddStockMovementSheet({
    required this.item,
    this.presetType,
  });

  final InventoryItemModel item;
  final String? presetType;

  @override
  State<_AddStockMovementSheet> createState() => _AddStockMovementSheetState();
}

class _AddStockMovementSheetState extends State<_AddStockMovementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _referenceNoController = TextEditingController();
  final _noteController = TextEditingController();

  late String _movementType = widget.presetType ?? 'in';
  DateTime _movementDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _referenceNoController.dispose();
    _noteController.dispose();
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
                  Text('Stok Hareketi Ekle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(widget.item.name, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _movementType,
                    decoration: const InputDecoration(
                      labelText: 'Hareket Türü',
                      prefixIcon: Icon(Icons.swap_horiz_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'in', child: Text('Giriş')),
                      DropdownMenuItem(value: 'out', child: Text('Çıkış')),
                      DropdownMenuItem(value: 'adjustment', child: Text('Düzeltme')),
                      DropdownMenuItem(value: 'return', child: Text('İade')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _movementType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) {
                        return 'Negatif olmayan miktar girin';
                      }
                      if (_movementType == 'out' && parsed > widget.item.stockQuantity) {
                        return 'Çıkış miktarı mevcut stoktan büyük olamaz';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: _movementType == 'adjustment' ? 'Yeni stok miktarı' : 'Miktar',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return null;
                      }
                      final parsed = double.tryParse(value!.replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) {
                        return 'Negatif olmayan fiyat girin';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Birim fiyat',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined, color: AppColors.gold500),
                    title: const Text('Tarih'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_movementDate)),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referenceNoController,
                    decoration: const InputDecoration(
                      labelText: 'Referans no',
                      prefixIcon: Icon(Icons.tag_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Not',
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
      initialDate: _movementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _movementDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    Navigator.pop(
      context,
      StockMovementModel(
        id: '',
        userId: '',
        inventoryItemId: widget.item.id,
        businessId: widget.item.businessId,
        movementType: _movementType,
        quantity: double.parse(_quantityController.text.trim().replaceAll(',', '.')),
        unitPrice: (_unitPriceController.text.trim().isEmpty)
            ? null
            : double.parse(_unitPriceController.text.trim().replaceAll(',', '.')),
        movementDate: _movementDate,
        referenceNo: _referenceNoController.text.trim().isEmpty
            ? null
            : _referenceNoController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
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
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

class _MetricData {
  const _MetricData({
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
