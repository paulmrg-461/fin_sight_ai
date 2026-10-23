import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final month = DateTime(2026, 10);

  BudgetEntity buildBudget({double limit = 100}) => BudgetEntity(
    id: 'budget-1',
    category: 'Food',
    monthlyLimit: limit,
    month: month,
  );

  group('BudgetEntity', () {
    test('uses value equality and copyWith', () {
      final original = buildBudget();
      final updated = original.copyWith(monthlyLimit: 200);

      expect(original, buildBudget());
      expect(original.hashCode, buildBudget().hashCode);
      expect(updated.monthlyLimit, 200);
      expect(updated.id, original.id);
      expect(original, isNot(updated));
      expect(original.toString(), contains('Food'));
    });
  });

  group('BudgetProgress', () {
    test('computes remaining and percentage', () {
      final progress = BudgetProgress(budget: buildBudget(), spent: 40);

      expect(progress.remaining, 60);
      expect(progress.percentage, 0.4);
      expect(progress.isOverBudget, isFalse);
    });

    test('detects overspending and clamps the percentage', () {
      final progress = BudgetProgress(budget: buildBudget(), spent: 150);

      expect(progress.remaining, -50);
      expect(progress.isOverBudget, isTrue);
      expect(progress.percentage, 1);
    });

    test('handles a zero limit', () {
      final progress = BudgetProgress(budget: buildBudget(limit: 0), spent: 10);

      expect(progress.percentage, 0);
    });

    test('uses value equality', () {
      expect(
        BudgetProgress(budget: buildBudget(), spent: 40),
        BudgetProgress(budget: buildBudget(), spent: 40),
      );
      expect(
        BudgetProgress(budget: buildBudget(), spent: 40),
        isNot(BudgetProgress(budget: buildBudget(), spent: 41)),
      );
    });
  });
}
