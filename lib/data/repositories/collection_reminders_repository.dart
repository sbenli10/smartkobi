import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/formatters.dart';
import '../models/collection_reminder_model.dart';
import '../models/customer_model.dart';
import '../models/customer_transaction_model.dart';

class CollectionRemindersRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CollectionReminderModel> saveReminder(CollectionReminderModel reminder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');

    final data = reminder.toJson();
    data['user_id'] = user.id;

    if (reminder.id.isEmpty) {
      final res = await _supabase.from('collection_reminders').insert(data).select().single();
      return CollectionReminderModel.fromJson(res);
    } else {
      final res = await _supabase.from('collection_reminders').update(data).eq('id', reminder.id).select().single();
      return CollectionReminderModel.fromJson(res);
    }
  }

  Future<void> updateStatus(String reminderId, String status) async {
    await _supabase.from('collection_reminders').update({'status': status}).eq('id', reminderId);
  }
}

class CollectionMessageGenerator {
  static String generateMessage({
    required String customerName,
    required double? amount,
    DateTime? dueDate,
    required String tone,
    String? paymentLink,
    String businessName = '',
  }) {
    final nameStr = customerName.isNotEmpty ? customerName : 'Değerli müşterimiz';
    final amountStr = amount != null ? AppFormatters.formatCurrency(amount) : 'cari bakiyeniz';
    final dateStr = dueDate != null ? AppFormatters.formatDateTr(dueDate) : 'vadesi gelen';
    final linkStr = (paymentLink != null && paymentLink.trim().isNotEmpty) ? '\nÖdeme bağlantısı: $paymentLink\n' : '';
    final signStr = businessName.isNotEmpty ? '\n\n$businessName' : '\n\nİyi çalışmalar dileriz.';

    switch (tone) {
      case 'clear':
        return 'Merhaba $nameStr,\n$dateStr tarihli $amountStr tutarındaki bakiyeniz için ödeme durumunuzu rica ederiz.$linkStr$signStr';
      case 'formal':
        return 'Sayın $nameStr,\nCari hesabınızda $amountStr tutarında vadesi gelmiş bakiye bulunmaktadır.\nÖdeme durumunuzla ilgili bilgilendirme yapmanızı rica ederiz.$linkStr\nSaygılarımızla,$signStr';
      case 'reminder':
        return 'Merhaba $nameStr,\nKısa bir hatırlatma yapmak isteriz. Cari hesabınızdaki $amountStr tutarındaki bakiyenin ödeme zamanı gelmiştir.\nMüsait olduğunuzda dönüşünüzü rica ederiz.$linkStr$signStr';
      case 'polite':
      default:
        return 'Merhaba $nameStr,\nCari hesabınızda $amountStr tutarında vadesi gelen bakiyeniz görünmektedir.\nMüsait olduğunuzda ödeme planı hakkında dönüşünüzü rica ederiz.$linkStr$signStr';
    }
  }

  static String buildWhatsappUrl(String phone, String message) {
    // Sadece rakamları al
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanPhone.startsWith('05')) {
      cleanPhone = '90${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('5') && cleanPhone.length == 10) {
      cleanPhone = '90$cleanPhone';
    } else if (!cleanPhone.startsWith('90') && cleanPhone.length == 10) {
      cleanPhone = '90$cleanPhone';
    }

    final encodedMsg = Uri.encodeComponent(message);
    return 'https://wa.me/$cleanPhone?text=$encodedMsg';
  }
}