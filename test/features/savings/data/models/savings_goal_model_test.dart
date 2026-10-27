import 'dart:convert';

import 'package:fin_sight_ai/features/savings/data/models/savings_goal_model.dart';
import 'package:fin_sight_ai/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips goals and contributions', () {
    final goal = SavingsGoalModel(
      id: 'g-1',
      name: 'Trip',
      targetAmount: 1000,
      createdAt: DateTime.utc(2026, 10, 1),
      targetDate: DateTime.utc(2027, 1, 1),
      contributions: [
        SavingsContribution(
          id: 'c-1',
          amount: 400,
          date: DateTime.utc(2026, 10, 2),
        ),
      ],
    );

    final decoded = jsonDecode(jsonEncode(goal.toJson()));
    final restored = SavingsGoalModel.fromJson(decoded as Map<String, dynamic>);

    expect(restored.toEntity(), goal.toEntity());
    expect(restored.savedAmount, 400);
  });

  test('skips corrupt contributions and rejects invalid goals', () {
    final restored = SavingsGoalModel.fromJson({
      'id': 'g-1',
      'name': 'Trip',
      'targetAmount': 100,
      'createdAt': '2026-10-01T00:00:00.000Z',
      'contributions': [
        'bad',
        {'id': 'c', 'amount': 'nope', 'date': 'x'},
      ],
    });
    expect(restored.contributions, isEmpty);

    expect(
      () => SavingsGoalModel.fromJson(const {'id': ''}),
      throwsFormatException,
    );
    expect(
      () => SavingsGoalModel.fromJson(const {
        'id': 'g',
        'name': '',
        'targetAmount': 1,
        'createdAt': '2026-10-01T00:00:00.000Z',
      }),
      throwsFormatException,
    );
  });
}
