import 'dart:convert';

import 'package:fin_sight_ai/features/budgets/data/models/budget_model.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final month = DateTime.utc(2026, 10);

  BudgetModel buildModel() => BudgetModel(
    id: 'budget-1',
    category: 'Food',
    monthlyLimit: 100,
    month: month,
    updatedAt: DateTime.utc(2026, 10, 22),
  );

  group('BudgetModel', () {
    test('maps from and to an entity', () {
      final entity = BudgetEntity(
        id: 'budget-1',
        category: 'Food',
        monthlyLimit: 100,
        month: month,
      );

      final model = BudgetModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.category, entity.category);
      expect(model.monthlyLimit, entity.monthlyLimit);
      expect(model.month, entity.month);
    });

    test('round-trips through JSON', () {
      final model = buildModel();

      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = BudgetModel.fromJson(decoded as Map<String, dynamic>);

      expect(restored.toEntity(), model.toEntity());
    });

    test('rejects invalid fields', () {
      expect(
        () => BudgetModel.fromJson(const {'id': ''}),
        throwsFormatException,
      );
      expect(
        () => BudgetModel.fromJson(const {
          'id': 'b',
          'category': 'Food',
          'monthlyLimit': 100,
          'month': 'not-a-date',
        }),
        throwsFormatException,
      );
      expect(
        () => BudgetModel.fromJson(const {
          'id': 'b',
          'category': 'Food',
          'monthlyLimit': '100',
          'month': '2026-10-01T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });
  });
}
