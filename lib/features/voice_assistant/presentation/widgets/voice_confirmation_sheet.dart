import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/inventory_item_model.dart';
import '../../../../data/models/stock_movement_model.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/repositories/inventory_repository.dart';
import '../../../../data/repositories/transactions_repository.dart';
import '../../data/models/draft_transaction_model.dart';
import '../../data/services/voice_assistant_service.dart';

Future<bool?> showVoiceConfirmationSheet({
  required BuildContext context,
  required DraftTransactionModel draft,
  required VoiceAssistantService service,
  TransactionsRepository? repository,
  InventoryRepository? inventoryRepository,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _VoiceConfirmationSheet(
      draft: draft,
      service: service,
      repository: repository ?? TransactionsRepository(),
      inventoryRepository: inventoryRepository ?? InventoryRepository(),
    ),
  );
}

class _VoiceConfirmationSheet extends StatefulWidget {
  const _VoiceConfirmationSheet({
    required this.draft,
    required this.service,
    required this.repository,
    required this.inventoryRepository,
  });

  final DraftTransactionModel draft;
  final VoiceAssistantService service;
  final TransactionsRepository repository;
  final InventoryRepository inventoryRepository;

  @override
  State<_VoiceConfirmationSheet> createState() => _VoiceConfirmationSheetState();
}

class _VoiceConfirmationSheetState extends State<_VoiceConfirmationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contactController;
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _productController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _unitPriceController;

  late String _operation;
  late String _transactionType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _operation = widget.draft.operation;
    _transactionType = widget.draft.transactionType;
    _contactController = TextEditingController(text: widget.draft.contact);
    _amountController = TextEditingController(
      text: widget.draft.totalAmount != null
          ? AppFormatters.formatNumber(widget.draft.totalAmount)
          : (widget.draft.amount > 0 ? AppFormatters.formatNumber(widget.draft.amount) : ''),
    );
    _titleController = TextEditingController(text: widget.draft.title);
    _categoryController = TextEditingController(text: widget.draft.category);
    _productController = TextEditingController(text: widget.draft.productName);
    _quantityController = TextEditingController(
      text: widget.draft.quantity == null ? '' : AppFormatters.formatNumber(widget.draft.quantity),
    );
    _unitController = TextEditingController(text: widget.draft.unit);
    _unitPriceController = TextEditingController(
      text: widget.draft.unitPrice == null ? '' : AppFormatters.formatNumber(widget.draft.unitPrice),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  bool get _isProductOperation =>
      _operation == 'product_sale' || _operation == 'product_purchase';

  bool get _shouldCreateTransaction =>
      _transactionType.isNotEmpty && _parsedAmount > 0;

  double get _parsedAmount =>
      AppFormatters.parseDecimal(_amountController.text, fallback: 0);

  double get _parsedQuantity =>
      AppFormatters.parseDecimal(_quantityController.text, fallback: 0);

  double get _parsedUnitPrice =>
      AppFormatters.parseDecimal(_unitPriceController.text, fallback: 0);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sesli işlem onayı',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Algılanan bilgileri kontrol edin, gerekirse düzenleyin ve ardından kaydedin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _operation,
                    decoration: _inputDecoration(
                      label: 'İşlem türü',
                      icon: Icons.tune_outlined,
                    ),
                    dropdownColor: AppColors.primaryNavy,
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Gelir')),
                      DropdownMenuItem(value: 'expense', child: Text('Gider')),
                      DropdownMenuItem(value: 'product_sale', child: Text('Ürün satışı')),
                      DropdownMenuItem(value: 'product_purchase', child: Text('Ürün alımı')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _operation = value;
                              _transactionType = _defaultTransactionTypeForOperation(value);
                              if (_isProductOperation && _categoryController.text.trim().isEmpty) {
                                _categoryController.text = value == 'product_sale' ? 'Satış' : 'Stok';
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  if (_isProductOperation) ...[
                    _buildField(
                      controller: _productController,
                      label: 'Ürün',
                      icon: Icons.inventory_2_outlined,
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Ürün seçin' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            controller: _quantityController,
                            label: 'Miktar',
                            icon: Icons.numbers,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              final quantity = AppFormatters.parseDecimal(value, fallback: 0);
                              if (quantity <= 0) {
                                return 'Miktar girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _unitController,
                            label: 'Birim',
                            icon: Icons.straighten_outlined,
                            validator: (value) =>
                                (value ?? '').trim().isEmpty ? 'Birim girin' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _unitPriceController,
                      label: 'Birim fiyat',
                      icon: Icons.sell_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _buildField(
                      controller: _contactController,
                      label: 'Kişi / Firma',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildField(
                    controller: _amountController,
                    label: _isProductOperation ? 'Toplam tutar' : 'Tutar',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (!_shouldRequireAmount()) {
                        return null;
                      }
                      final amount = AppFormatters.parseDecimal(value, fallback: 0);
                      if (amount <= 0) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _titleController,
                    label: 'Başlık',
                    icon: Icons.title,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Başlık gerekli' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _categoryController,
                    label: 'Kategori',
                    icon: Icons.category_outlined,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Kategori seçin' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryNavy,
                                ),
                              ),
                            )
                          : const Text(
                              'Onayla ve kaydet',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: AppColors.accentGold),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.accentGold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  bool _shouldRequireAmount() {
    if (_transactionType == 'income' || _transactionType == 'expense') {
      return true;
    }
    return false;
  }

  String _defaultTransactionTypeForOperation(String operation) {
    switch (operation) {
      case 'income':
        return 'income';
      case 'expense':
        return 'expense';
      case 'product_sale':
        return 'income';
      case 'product_purchase':
        return _parsedAmount > 0 ? 'expense' : '';
      default:
        return '';
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final now = DateTime.now();

      if (_isProductOperation) {
        await _saveProductOperation(now);
      } else {
        await _saveFinanceOperation(now);
      }

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('İşlem başarıyla kaydedildi.'),
          backgroundColor: AppColors.success,
        ),
      );
      await widget.service.speak(_buildTtsMessage());
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_friendlyError(error), isError: true);
      setState(() => _saving = false);
    }
  }

  Future<void> _saveFinanceOperation(DateTime now) async {
    final amount = _parsedAmount;
    if (amount <= 0) {
      throw Exception('Tutarı anlayamadım. Lütfen kontrol edin.');
    }

    final contactName = _normalizeText(_contactController.text);
    await widget.repository.addTransaction(
      TransactionModel(
        id: '',
        userId: '',
        businessId: null,
        type: _transactionType,
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        amount: amount,
        contactName: contactName,
        transactionDate: now,
        paymentStatus: 'paid',
        description: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _saveProductOperation(DateTime now) async {
    final productName = _productController.text.trim();
    final quantity = _parsedQuantity;
    if (productName.isEmpty || quantity <= 0) {
      throw Exception('Ürün ve miktar gerekli.');
    }

    final unit = _normalizeText(_unitController.text) ?? 'adet';
    var unitPrice = _parsedUnitPrice;
    final totalAmount = _parsedAmount;
    if (unitPrice <= 0 && totalAmount > 0 && quantity > 0) {
      unitPrice = totalAmount / quantity;
    }

    var item = await widget.inventoryRepository.findInventoryItemByName(productName);
    item ??= await widget.inventoryRepository.addInventoryItem(
      InventoryItemModel(
        id: '',
        userId: '',
        businessId: null,
        name: productName,
        sku: null,
        barcode: null,
        category: _categoryController.text.trim(),
        unit: unit,
        stockQuantity: 0,
        minStockLevel: 0,
        purchasePrice: _operation == 'product_purchase' ? unitPrice : 0,
        salePrice: _operation == 'product_sale' ? unitPrice : 0,
        supplierName: null,
        supplierPhone: null,
        description: 'Sesli komut ile oluşturuldu.',
        isActive: true,
        lastMovementDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final refreshedItem = _mergeItemPrices(item, unitPrice);
    if (refreshedItem != item) {
      item = await widget.inventoryRepository.updateInventoryItem(refreshedItem);
    }

    await widget.inventoryRepository.addStockMovement(
      StockMovementModel(
        id: '',
        userId: '',
        inventoryItemId: item.id,
        businessId: item.businessId,
        movementType: _operation == 'product_sale' ? 'out' : 'in',
        quantity: quantity,
        unitPrice: unitPrice > 0 ? unitPrice : null,
        movementDate: now,
        referenceNo: null,
        note: _titleController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (_shouldCreateTransaction) {
      await widget.repository.addTransaction(
        TransactionModel(
          id: '',
          userId: '',
          businessId: item.businessId,
          type: _transactionType,
          title: _titleController.text.trim(),
          category: _categoryController.text.trim(),
          amount: totalAmount,
          contactName: null,
          transactionDate: now,
          paymentStatus: 'paid',
          description: '$productName - ${AppFormatters.formatNumber(quantity)} $unit',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  InventoryItemModel _mergeItemPrices(InventoryItemModel item, double unitPrice) {
    if (unitPrice <= 0) {
      return item;
    }

    if (_operation == 'product_sale' && unitPrice != item.salePrice) {
      return item.copyWith(salePrice: unitPrice);
    }
    if (_operation == 'product_purchase' && unitPrice != item.purchasePrice) {
      return item.copyWith(purchasePrice: unitPrice);
    }
    return item;
  }

  String _buildTtsMessage() {
    final amountText = _parsedAmount > 0
        ? '${AppFormatters.formatNumber(_parsedAmount)} lira'
        : '';
    if (_operation == 'product_sale') {
      return _parsedAmount > 0
          ? '${_productController.text.trim()} için ${AppFormatters.formatNumber(_parsedQuantity)} ${_unitController.text.trim()} satışı kaydedildi. $amountText gelir kaydı oluşturuldu.'
          : '${_productController.text.trim()} için ${AppFormatters.formatNumber(_parsedQuantity)} ${_unitController.text.trim()} satış hareketi kaydedildi.';
    }
    if (_operation == 'product_purchase') {
      return _parsedAmount > 0
          ? '${_productController.text.trim()} için ${AppFormatters.formatNumber(_parsedQuantity)} ${_unitController.text.trim()} stok girişi yapıldı ve gider kaydı oluşturuldu.'
          : '${_productController.text.trim()} için ${AppFormatters.formatNumber(_parsedQuantity)} ${_unitController.text.trim()} stok girişi kaydedildi.';
    }
    if (_transactionType == 'income') {
      return '$amountText gelir kaydı oluşturuldu.';
    }
    if (_categoryController.text.trim().toLowerCase() == 'cari' &&
        _contactController.text.trim().isNotEmpty) {
      return '$amountText ${_contactController.text.trim()} hesabına borç olarak kaydedildi.';
    }
    return '$amountText gider kaydı oluşturuldu.';
  }

  String? _normalizeText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Bu işlem kaydedilemedi. Lütfen tekrar deneyin.' : message;
  }
}
