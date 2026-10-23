import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_event.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAddBudget extends Mock implements AddBudgetUseCase {}

class MockDeleteBudget extends Mock implements DeleteBudgetUseCase {}

class MockGetProgress extends Mock implements GetBudgetProgressUseCase {}

class MockGetCategories extends Mock implements GetCategoriesUseCase {}

void main() {
  late MockAddBudget addBudget;
  late MockDeleteBudget deleteBudget;
  late MockGetProgress getProgress;
  late MockGetCategories getCategories;

  final budget = BudgetEntity(
    id: 'budget-1',
    category: 'Food',
    monthlyLimit: 100,
    month: DateTime(2026, 10),
  );
  final progress = BudgetProgress(budget: budget, spent: 40);

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(DateTime(2026, 10));
    registerFallbackValue(
      AddBudgetParams(
        category: 'fallback',
        monthlyLimit: 1,
        month: DateTime(2026, 10),
      ),
    );
  });

  setUp(() {
    addBudget = MockAddBudget();
    deleteBudget = MockDeleteBudget();
    getProgress = MockGetProgress();
    getCategories = MockGetCategories();

    when(() => getProgress(any())).thenAnswer((_) async => Right([progress]));
    when(() => getCategories(any()))
        .thenAnswer((_) async => const Right(['Food']));
  });

  BudgetBloc buildBloc() =>
      BudgetBloc(addBudget, deleteBudget, getProgress, getCategories);

  group('BudgetBloc', () {
    test('initial state is BudgetInitial', () {
      expect(buildBloc().state, const BudgetInitial());
    });

    blocTest<BudgetBloc, BudgetState>(
      'loads budgets and categories',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        const BudgetLoading(),
        BudgetLoaded(progress: [progress], categories: const ['Food']),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits empty when there are no budgets',
      setUp: () {
        when(() => getProgress(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [
        const BudgetLoading(),
        const BudgetEmpty(categories: ['Food']),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits failure when progress fails',
      setUp: () {
        when(() => getProgress(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadBudgets()),
      expect: () => [const BudgetLoading(), const BudgetFailure('Store down.')],
    );

    blocTest<BudgetBloc, BudgetState>(
      'adds a budget and reloads',
      setUp: () {
        when(() => addBudget(any())).thenAnswer((_) async => Right(budget));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const AddBudget(category: 'Food', monthlyLimit: 100)),
      expect: () => [
        const BudgetLoading(),
        BudgetLoaded(progress: [progress], categories: const ['Food']),
      ],
      verify: (_) {
        final params =
            verify(() => addBudget(captureAny())).captured.single
                as AddBudgetParams;
        expect(params.category, 'Food');
        expect(params.monthlyLimit, 100);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits failure when adding is rejected',
      setUp: () {
        when(
          () => addBudget(any()),
        ).thenAnswer((_) async => const Left(ValidationFailure('Bad limit.')));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const AddBudget(category: 'Food', monthlyLimit: 0)),
      expect: () => [const BudgetLoading(), const BudgetFailure('Bad limit.')],
    );

    blocTest<BudgetBloc, BudgetState>(
      'deletes a budget and reloads',
      setUp: () {
        when(() => deleteBudget(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getProgress(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteBudget('budget-1')),
      expect: () => [
        const BudgetLoading(),
        const BudgetEmpty(categories: ['Food']),
      ],
      verify: (_) {
        verify(() => deleteBudget('budget-1')).called(1);
      },
    );
  });
}
