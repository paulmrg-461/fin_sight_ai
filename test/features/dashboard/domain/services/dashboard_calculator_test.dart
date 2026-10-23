import 'package:fin_sight_ai/features/dashboard/domain/services/dashboard_calculator.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity tx({
  required double amount,
  required TransactionType type,
  String category = 'General',
  DateTime? date,
}) {
  return TransactionEntity(
    id: 'tx-${amount}_${category}_${type.name}',
    amount: amount,
    type: type,
    category: category,
    description: '',
    date: date ?? DateTime.utc(2026, 10, 1),
  );
}

void main() {
  group('DashboardCalculator.summary', () {
    test('computes income, expenses, balance, and savings rate', () {
      final summary = DashboardCalculator.summary(
        current: [
          tx(amount: 1000, type: TransactionType.income),
          tx(amount: 400, type: TransactionType.expense),
        ],
      );

      expect(summary.totalIncome, 1000);
      expect(summary.totalExpenses, 400);
      expect(summary.balance, 600);
      expect(summary.savingsRate, 60);
    });

    test('supports a negative balance when expenses exceed income', () {
      final summary = DashboardCalculator.summary(
        current: [tx(amount: 100, type: TransactionType.expense)],
      );

      expect(summary.balance, -100);
      expect(summary.savingsRate, 0);
    });

    test('computes month-over-month expense change', () {
      final summary = DashboardCalculator.summary(
        current: [tx(amount: 300, type: TransactionType.expense)],
        previous: [tx(amount: 200, type: TransactionType.expense)],
      );

      expect(summary.monthOverMonthChange, 50);
    });

    test('returns 100% change when the previous month had no expenses', () {
      final summary = DashboardCalculator.summary(
        current: [tx(amount: 300, type: TransactionType.expense)],
      );

      expect(summary.monthOverMonthChange, 100);
    });

    test('handles an empty period', () {
      final summary = DashboardCalculator.summary(current: const []);

      expect(summary.totalIncome, 0);
      expect(summary.totalExpenses, 0);
      expect(summary.balance, 0);
      expect(summary.savingsRate, 0);
      expect(summary.monthOverMonthChange, 0);
    });

    test('rounds monetary values to two decimals', () {
      final summary = DashboardCalculator.summary(
        current: [tx(amount: 10.005, type: TransactionType.income)],
      );

      expect(summary.totalIncome, 10.01);
    });
  });

  group('DashboardCalculator.categoryBreakdown', () {
    test('groups expenses and sorts by amount', () {
      final breakdown = DashboardCalculator.categoryBreakdown([
        tx(amount: 100, type: TransactionType.expense, category: 'Food'),
        tx(amount: 50, type: TransactionType.expense, category: 'Food'),
        tx(amount: 50, type: TransactionType.expense, category: 'Travel'),
        tx(amount: 500, type: TransactionType.income, category: 'Salary'),
      ]);

      expect(breakdown, hasLength(2));
      expect(breakdown.first.category, 'Food');
      expect(breakdown.first.amount, 150);
      expect(breakdown.first.percentage, 75);
      expect(breakdown.last.category, 'Travel');
      expect(breakdown.last.percentage, 25);
    });

    test('returns an empty list without expenses', () {
      final breakdown = DashboardCalculator.categoryBreakdown([
        tx(amount: 500, type: TransactionType.income),
      ]);

      expect(breakdown, isEmpty);
    });

    test('handles a single transaction', () {
      final breakdown = DashboardCalculator.categoryBreakdown([
        tx(amount: 25, type: TransactionType.expense, category: 'Coffee'),
      ]);

      expect(breakdown.single.percentage, 100);
    });
  });

  group('DashboardCalculator.monthlyComparison', () {
    test('compares incomes and expenses across months', () {
      final comparison = DashboardCalculator.monthlyComparison(
        current: [
          tx(amount: 1000, type: TransactionType.income),
          tx(amount: 400, type: TransactionType.expense),
        ],
        previous: [
          tx(amount: 900, type: TransactionType.income),
          tx(amount: 500, type: TransactionType.expense),
        ],
      );

      expect(comparison.currentIncome, 1000);
      expect(comparison.currentExpenses, 400);
      expect(comparison.previousIncome, 900);
      expect(comparison.previousExpenses, 500);
      expect(comparison.expenseChangePercentage, -20);
    });

    test('handles two empty months', () {
      final comparison = DashboardCalculator.monthlyComparison(
        current: const [],
        previous: const [],
      );

      expect(comparison.expenseChangePercentage, 0);
    });
  });
}
