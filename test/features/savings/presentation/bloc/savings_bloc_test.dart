import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:fin_sight_ai/features/savings/domain/usecases/savings_usecases.dart';
import 'package:fin_sight_ai/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:fin_sight_ai/features/savings/presentation/bloc/savings_event.dart';
import 'package:fin_sight_ai/features/savings/presentation/bloc/savings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGoals extends Mock implements GetSavingsGoalsUseCase {}

class MockCreateGoal extends Mock implements CreateSavingsGoalUseCase {}

class MockAddContribution extends Mock
    implements AddSavingsContributionUseCase {}

class MockDeleteGoal extends Mock implements DeleteSavingsGoalUseCase {}

void main() {
  late MockGetGoals getGoals;
  late MockCreateGoal createGoal;
  late MockAddContribution addContribution;
  late MockDeleteGoal deleteGoal;

  final goal = SavingsGoalEntity(
    id: 'g-1',
    name: 'Trip',
    targetAmount: 1000,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CreateSavingsGoalParams(name: 'Trip', targetAmount: 1000),
    );
    registerFallbackValue(
      const AddSavingsContributionParams(goalId: 'g-1', amount: 1),
    );
  });

  setUp(() {
    getGoals = MockGetGoals();
    createGoal = MockCreateGoal();
    addContribution = MockAddContribution();
    deleteGoal = MockDeleteGoal();
    when(() => getGoals(any())).thenAnswer((_) async => Right([goal]));
  });

  SavingsBloc buildBloc() =>
      SavingsBloc(getGoals, createGoal, addContribution, deleteGoal);

  group('SavingsBloc', () {
    test('initial state is SavingsInitial', () {
      expect(buildBloc().state, const SavingsInitial());
    });

    blocTest<SavingsBloc, SavingsState>(
      'loads goals',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadSavingsGoals()),
      expect: () => [
        const SavingsLoading(),
        SavingsLoaded([goal]),
      ],
    );

    blocTest<SavingsBloc, SavingsState>(
      'emits empty when there are no goals',
      setUp: () {
        when(() => getGoals(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadSavingsGoals()),
      expect: () => [const SavingsLoading(), const SavingsEmpty()],
    );

    blocTest<SavingsBloc, SavingsState>(
      'creates a goal and reloads',
      setUp: () {
        when(() => createGoal(any())).thenAnswer((_) async => Right(goal));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CreateSavingsGoalEvent(
          CreateSavingsGoalParams(name: 'Trip', targetAmount: 1000),
        ),
      ),
      expect: () => [
        const SavingsLoading(),
        SavingsLoaded([goal]),
      ],
      verify: (_) => verify(() => createGoal(any())).called(1),
    );

    blocTest<SavingsBloc, SavingsState>(
      'adds a contribution and reloads',
      setUp: () {
        when(() => addContribution(any())).thenAnswer((_) async => Right(goal));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AddSavingsContributionEvent(
          AddSavingsContributionParams(goalId: 'g-1', amount: 200),
        ),
      ),
      expect: () => [
        const SavingsLoading(),
        SavingsLoaded([goal]),
      ],
    );

    blocTest<SavingsBloc, SavingsState>(
      'deletes a goal and reloads',
      setUp: () {
        when(() => deleteGoal(any()))
            .thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteSavingsGoalEvent('g-1')),
      expect: () => [
        const SavingsLoading(),
        SavingsLoaded([goal]),
      ],
    );

    blocTest<SavingsBloc, SavingsState>(
      'emits failure when loading fails',
      setUp: () {
        when(() => getGoals(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadSavingsGoals()),
      expect: () => [
        const SavingsLoading(),
        const SavingsFailure('Store down.'),
      ],
    );
  });
}
