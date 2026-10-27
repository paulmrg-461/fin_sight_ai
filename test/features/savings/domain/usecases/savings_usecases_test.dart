import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:fin_sight_ai/features/savings/domain/repositories/savings_repository.dart';
import 'package:fin_sight_ai/features/savings/domain/usecases/savings_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

class FixedClock extends Clock {
  const FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  late MockSavingsRepository repository;
  final now = DateTime.utc(2026, 10, 27, 12);

  final goal = SavingsGoalEntity(
    id: 'g-1',
    name: 'Trip',
    targetAmount: 1000,
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(goal);
    registerFallbackValue(SavingsContribution(id: 'c', amount: 1, date: now));
  });

  setUp(() {
    repository = MockSavingsRepository();
  });

  test('creates a normalized goal', () async {
    when(() => repository.addGoal(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as SavingsGoalEntity),
    );

    final result = await CreateSavingsGoalUseCase(
      repository,
      clock: FixedClock(now),
    )(const CreateSavingsGoalParams(name: '  Trip  ', targetAmount: 1000.126));

    final created = result.getOrElse((_) => fail('Expected goal'));
    expect(created.name, 'Trip');
    expect(created.targetAmount, 1000.13);
    expect(created.createdAt, now);
  });

  test('validates goal input', () async {
    final cases = <CreateSavingsGoalParams, String>{
      const CreateSavingsGoalParams(name: ' ', targetAmount: 10):
          'missing_goal_name',
      CreateSavingsGoalParams(name: 'x' * 121, targetAmount: 10):
          'goal_name_too_long',
      const CreateSavingsGoalParams(name: 'Trip', targetAmount: 0):
          'invalid_target',
    };
    for (final entry in cases.entries) {
      final result = await CreateSavingsGoalUseCase(repository)(entry.key);
      expect(result.fold((f) => f.code, (_) => null), entry.value);
    }
    verifyNever(() => repository.addGoal(any()));
  });

  test('updates a goal and validates its fields', () async {
    when(() => repository.updateGoal(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as SavingsGoalEntity),
    );

    final result = await UpdateSavingsGoalUseCase(repository)(
      UpdateSavingsGoalParams(
        id: ' g-1 ',
        name: '  Trip  ',
        targetAmount: 1200.126,
        targetDate: DateTime.utc(2027, 1, 1),
      ),
    );

    final updated = result.getOrElse((_) => fail('Expected update'));
    expect(updated.id, 'g-1');
    expect(updated.name, 'Trip');
    expect(updated.targetAmount, 1200.13);

    for (final entry in <UpdateSavingsGoalParams, String>{
      const UpdateSavingsGoalParams(id: ' ', name: 'Trip', targetAmount: 1):
          'missing_goal_id',
      const UpdateSavingsGoalParams(id: 'g', name: ' ', targetAmount: 1):
          'missing_goal_name',
      const UpdateSavingsGoalParams(id: 'g', name: 'Trip', targetAmount: 0):
          'invalid_target',
    }.entries) {
      final invalid = await UpdateSavingsGoalUseCase(repository)(entry.key);
      expect(invalid.fold((f) => f.code, (_) => null), entry.value);
    }
  });

  test('adds a contribution with a generated id and date', () async {
    when(() => repository.addContribution(any(), any()))
        .thenAnswer((_) async => Right(goal));

    final result = await AddSavingsContributionUseCase(
      repository,
      clock: FixedClock(now),
    )(const AddSavingsContributionParams(goalId: 'g-1', amount: 400));

    expect(result.isRight(), isTrue);
    final captured = verify(
      () => repository.addContribution(captureAny(), captureAny()),
    ).captured;
    expect(captured[0], 'g-1');
    final contribution = captured[1] as SavingsContribution;
    expect(contribution.amount, 400);
    expect(contribution.date, now);
  });

  test('validates contributions', () async {
    final missing = await AddSavingsContributionUseCase(repository)(
      const AddSavingsContributionParams(goalId: ' ', amount: 10),
    );
    final amount = await AddSavingsContributionUseCase(repository)(
      const AddSavingsContributionParams(goalId: 'g-1', amount: 0),
    );

    expect(missing.fold((f) => f.code, (_) => null), 'missing_goal_id');
    expect(amount.fold((f) => f.code, (_) => null), 'invalid_contribution');
  });

  test('deletes goals and rejects blank ids', () async {
    when(() => repository.deleteGoal(any()))
        .thenAnswer((_) async => const Right(null));

    expect(
      (await DeleteSavingsGoalUseCase(repository)('g-1')).isRight(),
      isTrue,
    );
    expect(
      (await DeleteSavingsGoalUseCase(repository)(' '))
          .fold((f) => f.code, (_) => null),
      'missing_goal_id',
    );
  });

  test('propagates repository failures', () async {
    when(() => repository.getGoals())
        .thenAnswer((_) async => const Left(CacheFailure('Store down.')));

    final result = await GetSavingsGoalsUseCase(repository)(const NoParams());

    expect(result.fold((f) => f.message, (_) => null), 'Store down.');
  });
}
