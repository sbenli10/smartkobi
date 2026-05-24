import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/collection_reminder_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/customer_transaction_model.dart';
import '../../../data/repositories/collection_reminders_repository.dart';
import '../collection_message_generator.dart'; // import the file created above

class CollectionReminderSheet extends StatefulWidget {
  const CollectionReminderSheet({
    super.key,
    required this.customer,
    this.transaction,
    this.totalAmount,
    this.dueDate,
  });

  final CustomerModel customer;
  final CustomerTransactionModel? transaction;
  final double? totalAmount;
  final DateTime? dueDate;

  @override
  State<CollectionReminderSheet> createState() => _CollectionReminderSheetState();
}

class _CollectionReminderSheetState extends State<CollectionReminderSheet> {
  final _repository = CollectionRemindersRepository();
  final _messageController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedTone = 'polite';
  bool _isLoading = false;
  CollectionReminderModel? _savedReminder;

  @override
  void initState() {
    super.initState();
    _generateMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _generateMessage() {
    final msg = CollectionMessageGenerator.generateMessage(
      customerName: widget.customer.name,
      amount: widget.totalAmount ?? widget.customer.balance,
      dueDate: widget.dueDate,
      tone: _selectedTone,
      paymentLink: _linkController.text.trim(),
    );
    _messageController.text = msg;
  }

  Future<void> _saveDraft({String status = 'draft'}) async {
    setState(() => _isLoading = true);
    try {
      final reminder = CollectionReminderModel(
        id: _savedReminder?.id ?? '',
        userId: '',
        customerId: widget.customer.id,
        customerTransactionId: widget.transaction?.id,
        reminderType: 'whatsapp',
        tone: _selectedTone,
        title: '${widget.customer.name} - Tahsilat Hatırlatması',
        message: _messageController.text,
        amount: widget.totalAmount,
        dueDate: widget.dueDate,
        status: status,
        phoneNumber: widget.customer.phone,
        metadata: {'payment_link': _linkController.text.trim()},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _savedReminder = await _repository.saveReminder(reminder);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Not kaydedilirken bir hata oluştu: $e', isError: true);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_messageController.text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _messageController.text));
    await _saveDraft(status: 'copied');
    _showSnackBar('Tahsilat mesajı kopyalandı.');
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.customer.phone;
    if (phone == null || phone.trim().isEmpty) {
      _showSnackBar('Müşterinin telefon numarası bulunamadı. Lütfen kopyalayarak gönderin.', isError: true);
      return;
    }

    final urlStr = CollectionMessageGenerator.buildWhatsappUrl(phone, _messageController.text);
    final uri = Uri.parse(urlStr);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _saveDraft(status: 'opened_whatsapp');
    } else {
      _showSnackBar('WhatsApp açılamadı. Cihazınızda WhatsApp yüklü olduğundan emin olun.', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48, height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.chat_outlined, color: AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tahsilat Mesajı Oluştur', style: Theme.of(context).textTheme.titleLarge),
                          Text('Profesyonel tahsilat hatırlatması hazırlayın', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Müşteri Özeti
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          if (widget.customer.phone != null) Text(widget.customer.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Bekleyen Tutar', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(
                            AppFormatters.formatCurrency(widget.totalAmount ?? widget.customer.balance),
                            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ton Seçimi
                Text('Mesaj Tonu', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _ToneChip('polite', 'Kibar', Icons.handshake_outlined),
                    _ToneChip('clear', 'Net', Icons.done_all),
                    _ToneChip('formal', 'Resmi', Icons.business_center_outlined),
                    _ToneChip('reminder', 'Hatırlatma', Icons.notifications_none),
                  ],
                ),
                const SizedBox(height: 16),

                // Link
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme bağlantısı (Opsiyonel)',
                    hintText: 'Müşteriye göndereceğiniz ödeme linki varsa ekleyin',
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: (_) => _generateMessage(),
                ),
                const SizedBox(height: 20),

                // Mesaj Kutusu
                Text('Önizleme & Düzenleme', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.primaryNavySoft.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: AppColors.primaryNavy, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mesaj WhatsApp’ta açılır. Gönderim sizin onayınızla yapılır. Müşteriye otomatik SMS gönderilmez.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                // Aksiyonlar
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Kopyala'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openWhatsApp,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ToneChip(String value, String label, IconData icon) {
    final isSelected = _selectedTone == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryNavy,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTone = value;
            _generateMessage();
          });
        }
      },
    );
  }
}