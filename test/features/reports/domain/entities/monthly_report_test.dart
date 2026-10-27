import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/reports/domain/entities/monthly_report.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final month = DateTime(2026, 10);
  final transaction = TransactionEntity(
    id: 'tx-1',
    amount: 100,
    type: TransactionType.expense,
    category: 'Food',
    description: 'Lunch',
    date: DateTime(2026, 10, 2),
  );
  const summary = DashboardSummaryEntity(
    totalIncome: 0,
    totalExpenses: 100,
    balance: -100,
    savingsRate: 0,
    monthOverMonthChange: 0,
  );
  const breakdown = [
    CategoryBreakdown(category: 'Food', amount: 100, percentage: 100),
  ];
  const comparison = MonthlyComparisonEntity(
    currentIncome: 0,
    currentExpenses: 100,
    previousIncome: 0,
    previousExpenses: 0,
    expenseChangePercentage: 100,
  );

  MonthlyReport report({List<TransactionEntity>? transactions}) {
    return MonthlyReport(
      month: month,
      transactions: transactions ?? [transaction],
      summary: summary,
      breakdown: breakdown,
      comparison: comparison,
    );
  }

  test('compares by month, transactions, and aggregates', () {
    expect(report(), report());
    expect(report().hashCode, report().hashCode);
    expect(report(), isNot(report(transactions: const [])));
    expect(
      report(),
      isNot(
        MonthlyReport(
          month: DateTime(2026, 9),
          transactions: [transaction],
          summary: summary,
          breakdown: breakdown,
          comparison: comparison,
        ),
      ),
    );
    expect(report(), isNot(Object()));
  });
}
