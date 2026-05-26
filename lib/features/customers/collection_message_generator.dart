import '../../core/utils/formatters.dart';

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
    final dateStr = dueDate != null ? '${AppFormatters.formatDateTr(dueDate)} tarihli' : 'vadesi gelen';
    final linkStr = (paymentLink != null && paymentLink.trim().isNotEmpty) ? '\nÖdeme bağlantısı: $paymentLink\n' : '';
    final signStr = businessName.isNotEmpty ? '\n\n$businessName' : '\n\nİyi çalışmalar dileriz.';

    switch (tone) {
      case 'clear':
        return 'Merhaba $nameStr,\n$dateStr $amountStr tutarındaki bakiyeniz için ödeme durumunuzu rica ederiz.$linkStr$signStr';
      case 'formal':
        return 'Sayın $nameStr,\nCari hesabınızda $amountStr tutarında vadesi gelmiş bakiye bulunmaktadır.\nÖdeme durumunuzla ilgili bilgilendirme yapmanızı rica ederiz.$linkStr\nSaygılarımızla,$signStr';
      case 'reminder':
        return 'Merhaba $nameStr,\nKısa bir hatırlatma yapmak isteriz. Cari hesabınızdaki $amountStr tutarındaki bakiyenin ödeme zamanı gelmiştir.\nMüsait olduğunuzda dönüşünüzü rica ederiz.$linkStr$signStr';
      case 'polite':
      default:
        return 'Merhaba $nameStr,\nCari hesabınızda $amountStr tutarında vadesi gelen bakiyeniz görünmektedir.\nMüsait olduğunuzda ödeme planı hakkında dönüşünüzü rica ederiz.$linkStr$signStr';
    }
  }

  static String? normalizePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanPhone.startsWith('05')) {
      return '90${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('5') && cleanPhone.length == 10) {
      return '90$cleanPhone';
    } else if (!cleanPhone.startsWith('90') && cleanPhone.length == 10) {
      return '90$cleanPhone';
    }
    return cleanPhone;
  }

  static String? buildWhatsappUrl(String? phone, String? message) {
    final normalized = normalizePhoneNumber(phone);
    if (normalized == null || message == null || message.trim().isEmpty) return null;

    final encodedMsg = Uri.encodeComponent(message.trim());
    return 'https://wa.me/$normalized?text=$encodedMsg';
  }
}