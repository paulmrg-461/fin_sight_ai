import '../../../debts/domain/entities/debt_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// Builds the financial context shared by insights, analysis, and chat.
abstract final class CoachContextBuilder {
  static String build({
    required List<TransactionEntity> transactions,
    required List<DebtEntity> debts,
    required String languageCode,
  }) {
    final language = languageCode.toLowerCase().startsWith('es')
        ? 'Spanish'
        : 'English';
    final debtSummary = _debtSummary(debts);
    if (transactions.isEmpty) {
      return 'No transactions recorded yet.${debtSummary.isEmpty ? '' : ' $debtSummary'} '
          'Write the response in $language.';
    }

    var income = 0.0;
    var expenses = 0.0;
    final expensesByCategory = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
        expensesByCategory.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    final topCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categorySummary = topCategories
        .take(3)
        .map((entry) => '${entry.key}: \$${entry.value.toStringAsFixed(2)}')
        .join(', ');

    return 'Transactions: ${transactions.length}. '
        'Income: \$${income.toStringAsFixed(2)}. '
        'Expenses: \$${expenses.toStringAsFixed(2)}. '
        'Balance: \$${(income - expenses).toStringAsFixed(2)}. '
        'Top expense categories: '
        '${categorySummary.isEmpty ? 'none' : categorySummary}. '
        '${debtSummary.isEmpty ? '' : '$debtSummary '}'
        'Write the response in $language.';
  }

  static String _debtSummary(List<DebtEntity> debts) {
    final active = debts.where((debt) => !debt.isPaid).toList(growable: false);
    if (active.isEmpty) {
      return '';
    }
    final total = active.fold<double>(
      0,
      (sum, debt) => sum + debt.remainingAmount,
    );
    final minimum = active.fold<double>(
      0,
      (sum, debt) => sum + debt.minimumPayment,
    );
    final highestRate = active
        .map((debt) => debt.interestRate)
        .reduce((a, b) => a > b ? a : b);
    return 'Debts: ${active.length}. Total remaining: '
        '\$${total.toStringAsFixed(2)}. Minimum payments: '
        '\$${minimum.toStringAsFixed(2)}. Highest rate: '
        '${highestRate.toStringAsFixed(2)}%.';
  }
}
