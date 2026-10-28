import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../../../dashboard/domain/services/dashboard_calculator.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// Income and expenses for one month of an annual report.
class AnnualMonthSummary {
  const AnnualMonthSummary({
    required this.month,
    required this.income,
    required this.expenses,
  });

  final DateTime month;
  final double income;
  final double expenses;

  double get balance => income - expenses;

  bool get isEmpty => income == 0 && expenses == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnualMonthSummary &&
          other.month == month &&
          other.income == income &&
          other.expenses == expenses;

  @override
  int get hashCode => Object.hash(month, income, expenses);
}

/// Transactions and aggregates for a calendar year.
class AnnualReport {
  const AnnualReport({
    required this.year,
    required this.months,
    required this.summary,
    required this.breakdown,
    required this.transactionCount,
  });

  factory AnnualReport.fromTransactions({
    required int year,
    required List<TransactionEntity> transactions,
  }) {
    final inYear = transactions
        .where((transaction) => transaction.date.year == year)
        .toList(growable: false);
    final months = <AnnualMonthSummary>[];
    for (var month = 1; month <= 12; month++) {
      var income = 0.0;
      var expenses = 0.0;
      for (final transaction in transactions) {
        if (transaction.date.year != year || transaction.date.month != month) {
          continue;
        }
        if (transaction.isIncome) {
          income += transaction.amount;
        } else {
          expenses += transaction.amount;
        }
      }
      months.add(
        AnnualMonthSummary(
          month: DateTime(year, month),
          income: income,
          expenses: expenses,
        ),
      );
    }

    return AnnualReport(
      year: year,
      months: List<AnnualMonthSummary>.unmodifiable(months),
      summary: DashboardCalculator.summary(current: inYear),
      breakdown: DashboardCalculator.categoryBreakdown(inYear),
      transactionCount: inYear.length,
    );
  }

  final int year;

  /// Always twelve entries, one per month, zero-filled when empty.
  final List<AnnualMonthSummary> months;
  final DashboardSummaryEntity summary;
  final List<CategoryBreakdown> breakdown;
  final int transactionCount;

  bool get isEmpty => transactionCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnualReport &&
          other.year == year &&
          other.summary == summary &&
          other.transactionCount == transactionCount &&
          _sameMonths(other.months, months) &&
          _sameBreakdown(other.breakdown, breakdown);

  @override
  int get hashCode => Object.hash(
    year,
    summary,
    transactionCount,
    Object.hashAll(months),
    Object.hashAll(breakdown),
  );

  static bool _sameMonths(
    List<AnnualMonthSummary> a,
    List<AnnualMonthSummary> b,
  ) {
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

  static bool _sameBreakdown(
    List<CategoryBreakdown> a,
    List<CategoryBreakdown> b,
  ) {
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
}
