import '../../data/models/customer_model.dart';
import '../../data/models/customer_transaction_model.dart';

double totalReceivables(List<CustomerTransactionModel> transactions) {
  return transactions
      .where((transaction) =>
          transaction.type == 'receivable' || transaction.type == 'adjustment')
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double totalPayments(List<CustomerTransactionModel> transactions) {
  return transactions
      .where((transaction) =>
          transaction.type == 'payment' || transaction.type == 'debt')
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double pendingAmount(List<CustomerTransactionModel> transactions) {
  return transactions
      .where((transaction) =>
          transaction.type == 'receivable' &&
          transaction.paymentStatus == 'pending')
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double overdueAmount(List<CustomerTransactionModel> transactions) {
  return transactions
      .where((transaction) => transaction.isOverdue && transaction.isReceivable)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double averageDelayDays(List<CustomerTransactionModel> transactions) {
  final overdueTransactions = transactions
      .where((transaction) => transaction.isOverdue && transaction.dueDate != null)
      .toList();
  if (overdueTransactions.isEmpty) {
    return 0;
  }

  final totalDays = overdueTransactions.fold<int>(0, (sum, transaction) {
    return sum + DateTime.now().difference(transaction.dueDate!).inDays;
  });
  return totalDays / overdueTransactions.length;
}

String detectRiskLevel(CustomerModel customer, List<CustomerTransactionModel> transactions) {
  if (transactions.any((transaction) => transaction.isOverdue)) {
    return 'high';
  }

  final nextCollection = transactions
      .where((transaction) =>
          transaction.isReceivable &&
          !transaction.isPaid &&
          transaction.dueDate != null)
      .map((transaction) => transaction.dueDate!)
      .toList()
    ..sort();

  if (customer.currentBalance > 100000 &&
      nextCollection.isNotEmpty &&
      nextCollection.first.isBefore(DateTime.now())) {
    return 'high';
  }

  if (transactions.any((transaction) =>
      transaction.isReceivable && transaction.paymentStatus == 'pending')) {
    return 'medium';
  }

  return 'low';
}

String generateCustomerAiInsight(
  CustomerModel? customer,
  List<CustomerTransactionModel> transactions,
) {
  if (customer == null) {
    return 'Müşterilerinizi eklediğinizde SmartKOBİ tahsilat risklerini ve cari bakiyeleri analiz eder.';
  }
  if (transactions.any((transaction) => transaction.isOverdue)) {
    return 'Bu müşteri son işlemlerde gecikme eğiliminde. Yeni satışta peşinat önerilir.';
  }
  if (customer.currentBalance > 0 && customer.currentBalance >= customer.openingBalance + 50000) {
    return 'Cari bakiye yüksek. Tahsilat hatırlatması gönderilebilir.';
  }
  return 'Ödeme geçmişi düzenli görünüyor.';
}

String generateWhatsAppReminder(CustomerModel customer, double amount) {
  final contact = (customer.contactName ?? customer.name).trim();
  return 'Merhaba $contact, ${customer.name} hesabınızda ${amount.toStringAsFixed(2)} TL tutarında bekleyen ödeme görünmektedir. Uygun olduğunuzda ödeme planı hakkında dönüş rica ederiz.';
}

String generateEmailReminder(CustomerModel customer, double amount) {
  final contact = (customer.contactName ?? customer.name).trim();
  return 'Konu: Cari Hesap / Ödeme Hatırlatması\n\nSayın $contact,\n\n${customer.name} cari hesabınızda ${amount.toStringAsFixed(2)} TL tutarında bekleyen ödeme görünmektedir. Uygun olduğunuzda ödeme planı hakkında bilgilendirme rica ederiz.\n\nİyi çalışmalar.';
}
