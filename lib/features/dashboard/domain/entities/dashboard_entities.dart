import '../../../transactions/domain/entities/transaction_entity.dart';

/// Everything the dashboard needs for one period, built from two reads.
class DashboardData {
  const DashboardData({
    required this.summary,
    required this.breakdown,
    required this.comparison,
    required this.recentTransactions,
    required this.start,
    required this.end,
  });

  final DashboardSummaryEntity summary;
  final List<CategoryBreakdown> breakdown;
  final MonthlyComparisonEntity comparison;
  final List<TransactionEntity> recentTransactions;
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardData &&
          other.summary == summary &&
          _sameList(other.breakdown, breakdown) &&
          other.comparison == comparison &&
          _sameList(other.recentTransactions, recentTransactions) &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(
    summary,
    Object.hashAll(breakdown),
    comparison,
    Object.hashAll(recentTransactions),
    start,
    end,
  );

  @override
  String toString() =>
      'DashboardData(${summary.totalIncome}, ${summary.totalExpenses}, '
      '${recentTransactions.length} recent)';
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Aggregated financial summary for a selected period.
class DashboardSummaryEntity {
  const DashboardSummaryEntity({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.savingsRate,
    required this.monthOverMonthChange,
  });

  final double totalIncome;
  final double totalExpenses;
  final double balance;

  /// Savings as a percentage of income (`0..100`, can be negative).
  final double savingsRate;

  /// Expense change versus the previous month, as a percentage.
  final double monthOverMonthChange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSummaryEntity &&
          other.totalIncome == totalIncome &&
          other.totalExpenses == totalExpenses &&
          other.balance == balance &&
          other.savingsRate == savingsRate &&
          other.monthOverMonthChange == monthOverMonthChange;

  @override
  int get hashCode => Object.hash(
    totalIncome,
    totalExpenses,
    balance,
    savingsRate,
    monthOverMonthChange,
  );

  @override
  String toString() =>
      'DashboardSummaryEntity(income: $totalIncome, expenses: $totalExpenses, '
      'balance: $balance)';
}

/// Expense share for one category.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final String category;
  final double amount;
  final double percentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBreakdown &&
          other.category == category &&
          other.amount == amount &&
          other.percentage == percentage;

  @override
  int get hashCode => Object.hash(category, amount, percentage);

  @override
  String toString() => 'CategoryBreakdown($category: $amount, $percentage%)';
}

/// Current month compared with the previous month.
class MonthlyComparisonEntity {
  const MonthlyComparisonEntity({
    required this.currentIncome,
    required this.currentExpenses,
    required this.previousIncome,
    required this.previousExpenses,
    required this.expenseChangePercentage,
  });

  final double currentIncome;
  final double currentExpenses;
  final double previousIncome;
  final double previousExpenses;
  final double expenseChangePercentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyComparisonEntity &&
          other.currentIncome == currentIncome &&
          other.currentExpenses == currentExpenses &&
          other.previousIncome == previousIncome &&
          other.previousExpenses == previousExpenses &&
          other.expenseChangePercentage == expenseChangePercentage;

  @override
  int get hashCode => Object.hash(
    currentIncome,
    currentExpenses,
    previousIncome,
    previousExpenses,
    expenseChangePercentage,
  );

  @override
  String toString() =>
      'MonthlyComparisonEntity(current: $currentExpenses, '
      'previous: $previousExpenses)';
}
