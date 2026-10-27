import 'package:fin_sight_ai/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 1);

  SavingsContribution contribution({String id = 'c-1', double amount = 400}) {
    return SavingsContribution(
      id: id,
      amount: amount,
      date: DateTime.utc(2026, 10, 2),
    );
  }

  SavingsGoalEntity goal({
    double target = 1000,
    List<SavingsContribution>? contributions,
  }) {
    return SavingsGoalEntity(
      id: 'g-1',
      name: 'Trip',
      targetAmount: target,
      createdAt: createdAt,
      targetDate: DateTime.utc(2027, 1, 1),
      contributions: contributions ?? [contribution()],
    );
  }

  test('computes saved, remaining, progress, and completion', () {
    final item = goal();

    expect(item.savedAmount, 400);
    expect(item.remainingAmount, 600);
    expect(item.progress, 0.4);
    expect(item.isComplete, isFalse);

    final complete = goal(contributions: [contribution(amount: 1200)]);
    expect(complete.remainingAmount, 0);
    expect(complete.progress, 1);
    expect(complete.isComplete, isTrue);
  });

  test('copyWith and equality cover contributions', () {
    expect(goal(), goal());
    expect(goal().hashCode, goal().hashCode);
    expect(goal(), isNot(goal(target: 2000)));
    expect(goal(), isNot(goal(contributions: [contribution(id: 'c-2')])));
    expect(goal().copyWith(name: 'House').name, 'House');
    expect(goal().toString(), contains('Trip'));
    expect(goal(), isNot(Object()));
  });

  test('contributions compare by value', () {
    expect(contribution(), contribution());
    expect(contribution().hashCode, contribution().hashCode);
    expect(contribution(), isNot(contribution(amount: 1)));
    expect(contribution().toString(), contains('400.0'));
  });
}
