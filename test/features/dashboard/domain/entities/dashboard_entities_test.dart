import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
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

void main() {
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
