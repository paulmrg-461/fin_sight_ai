import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

const summary = DashboardSummaryEntity(
  totalIncome: 1000,
  totalExpenses: 400,
  balance: 600,
  savingsRate: 60,
  monthOverMonthChange: 10,
);

const breakdown = CategoryBreakdown(
  category: 'Food',
  amount: 400,
  percentage: 100,
);

const comparison = MonthlyComparisonEntity(
  currentIncome: 1000,
  currentExpenses: 400,
  previousIncome: 900,
  previousExpenses: 300,
  expenseChangePercentage: 33.33,
);

final start = DateTime.utc(2026, 10);
final end = DateTime.utc(2026, 10, 31);
final recent = TransactionEntity(
  id: 'tx-1',
  amount: 400,
  type: TransactionType.expense,
  category: 'Food',
  description: 'Groceries',
  date: DateTime.utc(2026, 10, 20),
);

DashboardData buildData({
  List<CategoryBreakdown>? breakdownList,
  List<TransactionEntity>? recentList,
  DateTime? rangeStart,
}) {
  return DashboardData(
    summary: summary,
    breakdown: breakdownList ?? const [breakdown],
    comparison: comparison,
    recentTransactions: recentList ?? [recent],
    start: rangeStart ?? start,
    end: end,
  );
}

void main() {
  group('DashboardData', () {
    test('uses value equality across all sections', () {
      final data = buildData();

      expect(data, buildData());
      expect(data.hashCode, buildData().hashCode);
      expect(data, isNot(buildData(breakdownList: const [])));
      expect(data, isNot(buildData(recentList: const [])));
      expect(data, isNot(buildData(rangeStart: DateTime.utc(2026, 9))));
      expect(data, isNot(Object()));
    });

    test('compares list contents, not only their length', () {
      final data = buildData();

      expect(
        data,
        isNot(
          buildData(
            recentList: [
              TransactionEntity(
                id: 'tx-2',
                amount: 1,
                type: TransactionType.expense,
                category: 'Food',
                description: '',
                date: DateTime.utc(2026, 10, 21),
              ),
            ],
          ),
        ),
      );
    });

    test('accepts the same list instance', () {
      final recentList = [recent];
      final data = DashboardData(
        summary: summary,
        breakdown: const [breakdown],
        comparison: comparison,
        recentTransactions: recentList,
        start: start,
        end: end,
      );

      final sameInstance = DashboardData(
        summary: summary,
        breakdown: const [breakdown],
        comparison: comparison,
        recentTransactions: recentList,
        start: start,
        end: end,
      );

      expect(data, sameInstance);
    });

    test('toString exposes totals and recent count', () {
      final text = buildData().toString();

      expect(text, contains('1000.0'));
      expect(text, contains('400.0'));
      expect(text, contains('1 recent'));
    });
  });
  group('DashboardSummaryEntity', () {
    test('uses value equality', () {
      expect(
        summary,
        const DashboardSummaryEntity(
          totalIncome: 1000,
          totalExpenses: 400,
          balance: 600,
          savingsRate: 60,
          monthOverMonthChange: 10,
        ),
      );
      expect(summary.hashCode, isNonZero);
      expect(
        summary,
        isNot(
          const DashboardSummaryEntity(
            totalIncome: 0,
            totalExpenses: 0,
            balance: 0,
            savingsRate: 0,
            monthOverMonthChange: 0,
          ),
        ),
      );
    });

    test('toString exposes totals', () {
      expect(summary.toString(), contains('1000.0'));
      expect(summary.toString(), contains('400.0'));
    });
  });

  group('CategoryBreakdown', () {
    test('uses value equality and exposes values in toString', () {
      expect(
        breakdown,
        const CategoryBreakdown(category: 'Food', amount: 400, percentage: 100),
      );
      expect(breakdown.hashCode, isNonZero);
      expect(
        breakdown,
        isNot(
          const CategoryBreakdown(category: 'Food', amount: 1, percentage: 1),
        ),
      );
      expect(breakdown.toString(), contains('Food'));
      expect(breakdown.toString(), contains('100'));
    });
  });

  group('MonthlyComparisonEntity', () {
    test('uses value equality', () {
      expect(
        comparison,
        const MonthlyComparisonEntity(
          currentIncome: 1000,
          currentExpenses: 400,
          previousIncome: 900,
          previousExpenses: 300,
          expenseChangePercentage: 33.33,
        ),
      );
      expect(comparison.hashCode, isNonZero);
      expect(
        comparison,
        isNot(
          const MonthlyComparisonEntity(
            currentIncome: 0,
            currentExpenses: 0,
            previousIncome: 0,
            previousExpenses: 0,
            expenseChangePercentage: 0,
          ),
        ),
      );
    });

    test('toString exposes current and previous expenses', () {
      expect(comparison.toString(), contains('400.0'));
      expect(comparison.toString(), contains('300.0'));
    });
  });
}
