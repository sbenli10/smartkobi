import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/page_scaffold.dart';
import '../../common/widgets/smart_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/receipt_scan_model.dart';
import '../../data/repositories/receipt_scanner_repository.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({super.key});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  final _repository = ReceiptScannerRepository();
  final _imagePicker = ImagePicker();

  ReceiptScanModel? _currentScan;
  bool _isLoading = false;
  String _statusText = '';

  // Form Controllers
  final _vendorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  String _selectedCategory = 'Genel Gider';

  final List<String> _categories = [
    'Yemek', 'Yakıt', 'Ofis', 'Tedarik', 'Kira', 'Personel', 'Pazarlama', 'Ulaşım', 'Genel Gider', 'Diğer'
  ];

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;

      setState(() {
        _isLoading = true;
        _statusText = 'Belge yükleniyor...';
      });

      final bytes = await image.readAsBytes();
      
      // 1. Upload
      final uploadedScan = await _repository.uploadAndCreateScan(
        fileBytes: bytes,
        fileName: image.name,
        mimeType: 'image/jpeg',
      );

      setState(() {
        _statusText = 'Fiş/Fatura okunuyor (Yapay Zeka)...';
      });

      // 2. OCR AI
      final processedScan = await _repository.processScanWithAI(uploadedScan.id);
      
      _fillFormWithAIResult(processedScan);

      setState(() {
        _currentScan = processedScan;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _fillFormWithAIResult(ReceiptScanModel scan) {
    _vendorCtrl.text = scan.extractedVendorName ?? '';
    _amountCtrl.text = scan.extractedTotalAmount?.toString() ?? '';
    _taxCtrl.text = scan.extractedTaxAmount?.toString() ?? '';
    if (scan.extractedDocumentDate != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(scan.extractedDocumentDate!);
    }
    if (scan.suggestedCategory != null && _categories.contains(scan.suggestedCategory)) {
      _selectedCategory = scan.suggestedCategory!;
    }
  }

  Future<void> _saveAsExpense() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError('Geçerli bir tutar girmelisiniz.');
      return;
    }

    DateTime? txDate;
    try {
      txDate = DateFormat('yyyy-MM-dd').parse(_dateCtrl.text);
    } catch (_) {
      _showError('Geçerli bir tarih girin (YYYY-MM-DD).');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repository.saveAsExpenseTransaction(
        scan: _currentScan!,
        amount: amount,
        transactionDate: txDate,
        category: _selectedCategory,
        title: _vendorCtrl.text.isNotEmpty ? '${_vendorCtrl.text} - Fiş/Fatura' : 'Fiş/Fatura Gideri',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gider başarıyla kaydedildi!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context); // Gider eklendi, geri dön
    } catch (e) {
      _showError('Kaydedilirken hata oluştu: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Fiş / Fatura Tarayıcı',
      subtitle: 'Manuel veri girmeden yapay zeka ile otomatik doldurun.',
      child: _isLoading 
        ? _buildLoadingState() 
        : _currentScan == null 
            ? _buildUploadState() 
            : _buildResultForm(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryNavy),
          const SizedBox(height: 24),
          Text(_statusText, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildUploadState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SmartCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.document_scanner_outlined, size: 64, color: AppColors.primaryNavy),
              const SizedBox(height: 24),
              Text('Belgenizi Yükleyin', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'SmartKOBİ tutar, tarih, KDV ve satıcı bilgisini okuyarak sizin yerinize formu doldurur.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera ile Çek'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeriden Seç'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultForm() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tarama sonucu otomatik oluşturuldu. Resmî kayıt öncesinde lütfen tutar ve tarih bilgilerini kontrol edin.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SmartCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Okunan Bilgiler', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _vendorCtrl,
                      decoration: const InputDecoration(labelText: 'Satıcı / İşletme Adı', prefixIcon: Icon(Icons.storefront)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Toplam Tutar (TL)', prefixIcon: Icon(Icons.account_balance_wallet)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _taxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'KDV Tutarı', prefixIcon: Icon(Icons.receipt_long)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(labelText: 'Belge Tarihi (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category)),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentScan = null),
                      child: const Text('İptal / Tekrar Tara'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAsExpense,
                      child: const Text('Gider Olarak Kaydet'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
