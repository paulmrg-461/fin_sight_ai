import 'dart:convert';

import 'package:fin_sight_ai/features/budgets/data/models/budget_model.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final month = DateTime.utc(2026, 10, 1, 12);

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

    test('round-trips a local calendar month', () {
      final model = BudgetModel(
        id: 'budget-2',
        category: 'Travel',
        monthlyLimit: 250,
        month: DateTime(2026, 11),
      );

      final restored = BudgetModel.fromJson(
        jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>,
      );

      expect(restored.month.year, 2026);
      expect(restored.month.month, 11);
      expect(restored.month.day, 1);
      expect(restored.month.isUtc, isTrue);
      expect(restored.month.hour, 12);
    });

    test('normalizes a legacy local month stored as a UTC instant', () {
      final legacyMonth = DateTime(2026, 11).toUtc().toIso8601String();

      final restored = BudgetModel.fromJson({
        'id': 'budget-3',
        'category': 'Travel',
        'monthlyLimit': 250,
        'month': legacyMonth,
      });

      expect(restored.month.year, 2026);
      expect(restored.month.month, 11);
      expect(restored.month, DateTime.utc(2026, 11, 1, 12));
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
