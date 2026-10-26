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

class MockUpdateBudget extends Mock implements UpdateBudgetUseCase {}

class MockGetProgress extends Mock implements GetBudgetProgressUseCase {}

class MockGetCategories extends Mock implements GetCategoriesUseCase {}

void main() {
  late MockAddBudget addBudget;
  late MockUpdateBudget updateBudget;
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
    registerFallbackValue(
      UpdateBudgetParams(
        id: 'fallback',
        category: 'fallback',
        monthlyLimit: 1,
        month: DateTime(2026, 10),
      ),
    );
  });

  setUp(() {
    addBudget = MockAddBudget();
    updateBudget = MockUpdateBudget();
    deleteBudget = MockDeleteBudget();
    getProgress = MockGetProgress();
    getCategories = MockGetCategories();

    when(() => getProgress(any())).thenAnswer((_) async => Right([progress]));
    when(() => getCategories(any()))
        .thenAnswer((_) async => const Right(['Food']));
  });

  DateTime monthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  BudgetBloc buildBloc() => BudgetBloc(
    addBudget,
    updateBudget,
    deleteBudget,
    getProgress,
    getCategories,
  );

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
        BudgetLoaded(
          progress: [progress],
          categories: const ['Food'],
          month: monthStart(),
        ),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'changes month and reloads its progress',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeBudgetMonth(DateTime(2026, 1, 17))),
      expect: () => [
        const BudgetLoading(),
        BudgetLoaded(
          progress: [progress],
          categories: const ['Food'],
          month: DateTime(2026),
        ),
      ],
      verify: (_) {
        verify(() => getProgress(DateTime(2026))).called(1);
        verifyNever(() => getProgress(monthStart()));
      },
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
        BudgetEmpty(categories: const ['Food'], month: monthStart()),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'copies the previous month into the selected month',
      setUp: () {
        final previous = DateTime(monthStart().year, monthStart().month - 1);
        var copied = false;
        when(() => getProgress(any())).thenAnswer((invocation) async {
          final month = invocation.positionalArguments.first as DateTime;
          if (month == previous) {
            return Right([progress]);
          }
          return Right(copied ? [progress] : const <BudgetProgress>[]);
        });
        when(() => addBudget(any())).thenAnswer((_) async {
          copied = true;
          return Right(budget);
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const LoadBudgets());
        await pumpEventQueue();
        bloc.add(const CopyPreviousBudgets());
      },
      expect: () => [
        const BudgetLoading(),
        BudgetEmpty(
          categories: const ['Food'],
          month: monthStart(),
          previousBudgetCount: 1,
        ),
        const BudgetLoading(),
        BudgetLoaded(
          progress: [progress],
          categories: const ['Food'],
          month: monthStart(),
        ),
      ],
      verify: (_) {
        final params =
            verify(() => addBudget(captureAny())).captured.single
                as AddBudgetParams;
        expect(params.category, 'Food');
        expect(params.monthlyLimit, 100);
        expect(params.month, monthStart());
      },
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
        BudgetLoaded(
          progress: [progress],
          categories: const ['Food'],
          month: monthStart(),
        ),
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
      'updates a budget and reloads',
      setUp: () {
        when(() => updateBudget(any())).thenAnswer((_) async => Right(budget));
        when(() => getProgress(any()))
            .thenAnswer((_) async => Right([progress]));
        when(() => getCategories(any()))
            .thenAnswer((_) async => const Right(['Food']));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdateBudget(
          id: 'budget-1',
          category: 'Food',
          monthlyLimit: 200,
          month: DateTime(2026, 10),
        ),
      ),
      expect: () => [
        const BudgetLoading(),
        BudgetLoaded(
          progress: [progress],
          categories: const ['Food'],
          month: monthStart(),
        ),
      ],
      verify: (_) {
        verify(() => updateBudget(any())).called(1);
      },
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
        BudgetEmpty(categories: const ['Food'], month: monthStart()),
      ],
      verify: (_) {
        verify(() => deleteBudget('budget-1')).called(1);
      },
    );
  });
}
