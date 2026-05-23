import '../../data/models/transaction_model.dart';

double totalIncome(List<TransactionModel> transactions) {
  return transactions
      .where((transaction) => transaction.isIncome)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double totalExpense(List<TransactionModel> transactions) {
  return transactions
      .where((transaction) => transaction.isExpense)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double netProfit(List<TransactionModel> transactions) {
  return totalIncome(transactions) - totalExpense(transactions);
}

double expenseIncomeRatio(List<TransactionModel> transactions) {
  final income = totalIncome(transactions);
  if (income == 0) {
    return 0;
  }
  return totalExpense(transactions) / income;
}

double pendingPaymentsTotal(List<TransactionModel> transactions) {
  return transactions
      .where((transaction) =>
          transaction.isExpense && transaction.paymentStatus != 'paid')
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double receivablesTotal(List<TransactionModel> transactions) {
  return transactions
      .where((transaction) =>
          transaction.isIncome && transaction.paymentStatus != 'paid')
      .fold(0, (sum, transaction) => sum + transaction.amount);
}
