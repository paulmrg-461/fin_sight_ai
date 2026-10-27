import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// Transactions and aggregates for one calendar month.
class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.transactions,
    required this.summary,
    required this.breakdown,
    required this.comparison,
  });

  final DateTime month;
  final List<TransactionEntity> transactions;
  final DashboardSummaryEntity summary;
  final List<CategoryBreakdown> breakdown;
  final MonthlyComparisonEntity comparison;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyReport &&
          other.month == month &&
          other.summary == summary &&
          other.comparison == comparison &&
          _sameTransactions(other.transactions, transactions) &&
          _sameBreakdown(other.breakdown, breakdown);

  @override
  int get hashCode => Object.hash(
    month,
    summary,
    comparison,
    Object.hashAll(transactions),
    Object.hashAll(breakdown),
  );

  static bool _sameTransactions(
    List<TransactionEntity> a,
    List<TransactionEntity> b,
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
