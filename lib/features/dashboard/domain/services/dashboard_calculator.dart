import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/dashboard_entities.dart';

/// Pure aggregation rules for the dashboard.
abstract final class DashboardCalculator {
  static DashboardSummaryEntity summary({
    required List<TransactionEntity> current,
    List<TransactionEntity> previous = const [],
  }) {
    final totals = _Totals.of(current);
    final previousTotals = _Totals.of(previous);
    final savingsRate = totals.income > 0
        ? ((totals.income - totals.expenses) / totals.income) * 100
        : 0.0;

    return DashboardSummaryEntity(
      totalIncome: _round(totals.income),
      totalExpenses: _round(totals.expenses),
      balance: _round(totals.income - totals.expenses),
      savingsRate: _round(savingsRate),
      monthOverMonthChange: _change(totals.expenses, previousTotals.expenses),
    );
  }

  static List<CategoryBreakdown> categoryBreakdown(
    List<TransactionEntity> transactions,
  ) {
    final expenses = transactions.where((transaction) => transaction.isExpense);
    final total = expenses.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    if (total <= 0) {
      return const [];
    }

    final byCategory = <String, double>{};
    for (final transaction in expenses) {
      byCategory.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final breakdown =
        byCategory.entries
            .map(
              (entry) => CategoryBreakdown(
                category: entry.key,
                amount: _round(entry.value),
                percentage: _round((entry.value / total) * 100),
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return List<CategoryBreakdown>.unmodifiable(breakdown);
  }

  static MonthlyComparisonEntity monthlyComparison({
    required List<TransactionEntity> current,
    required List<TransactionEntity> previous,
  }) {
    final currentTotals = _Totals.of(current);
    final previousTotals = _Totals.of(previous);

    return MonthlyComparisonEntity(
      currentIncome: _round(currentTotals.income),
      currentExpenses: _round(currentTotals.expenses),
      previousIncome: _round(previousTotals.income),
      previousExpenses: _round(previousTotals.expenses),
      expenseChangePercentage: _change(
        currentTotals.expenses,
        previousTotals.expenses,
      ),
    );
  }

  static double _change(double current, double previous) {
    if (previous <= 0) {
      return current > 0 ? 100 : 0;
    }
    return _round(((current - previous) / previous) * 100);
  }

  static double _round(double value) => double.parse(value.toStringAsFixed(2));
}

class _Totals {
  const _Totals({required this.income, required this.expenses});

  factory _Totals.of(List<TransactionEntity> transactions) {
    var income = 0.0;
    var expenses = 0.0;
    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else if (transaction.isExpense) {
        expenses += transaction.amount;
      }
    }
    return _Totals(income: income, expenses: expenses);
  }

  final double income;
  final double expenses;
}
