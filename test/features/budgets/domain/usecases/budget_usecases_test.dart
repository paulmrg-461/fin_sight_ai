import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:fin_sight_ai/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockBudgetRepository repository;

  final month = DateTime(2026, 10, 15);
  final normalized = DateTime(2026, 10);

  final budget = BudgetEntity(
    id: 'budget-1',
    category: 'Food',
    monthlyLimit: 100,
    month: normalized,
  );

  setUpAll(() {
    registerFallbackValue(budget);
  });

  setUp(() {
    repository = MockBudgetRepository();
  });

  group('AddBudgetUseCase', () {
    test('normalizes input and delegates', () async {
      when(() => repository.addBudget(any()))
          .thenAnswer((_) async => Right(budget));

      final result = await AddBudgetUseCase(repository)(
        AddBudgetParams(
          category: '  Food  ',
          monthlyLimit: 100.004,
          month: month,
        ),
      );

      expect(result.getOrElse((_) => fail('Expected budget')), budget);
      final captured =
          verify(() => repository.addBudget(captureAny())).captured.single
              as BudgetEntity;
      expect(captured.category, 'Food');
      expect(captured.monthlyLimit, 100);
      expect(captured.month, normalized);
      expect(captured.id.trim(), isNotEmpty);
    });

    test('rejects a blank category', () async {
      final result = await AddBudgetUseCase(repository)(
        AddBudgetParams(category: '  ', monthlyLimit: 100, month: month),
      );

      expect(result.getLeft().toNullable()?.code, 'missing_category');
    });

    test('rejects a non-positive limit', () async {
      final zero = await AddBudgetUseCase(repository)(
        AddBudgetParams(category: 'Food', monthlyLimit: 0, month: month),
      );
      final negative = await AddBudgetUseCase(repository)(
        AddBudgetParams(category: 'Food', monthlyLimit: -10, month: month),
      );

      expect(zero.getLeft().toNullable()?.code, 'invalid_limit');
      expect(negative.getLeft().toNullable()?.code, 'invalid_limit');
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Disk full.');
      when(() => repository.addBudget(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await AddBudgetUseCase(repository)(
        AddBudgetParams(category: 'Food', monthlyLimit: 100, month: month),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('other budget use cases', () {
    test('DeleteBudgetUseCase rejects a blank id', () async {
      final result = await DeleteBudgetUseCase(repository)('  ');

      expect(result.getLeft().toNullable()?.code, 'missing_id');
    });

    test('GetBudgetProgressUseCase normalizes the month', () async {
      when(() => repository.getBudgetProgress(normalized)).thenAnswer(
        (_) async => Right([BudgetProgress(budget: budget, spent: 10)]),
      );

      final result = await GetBudgetProgressUseCase(repository)(month);

      expect(result.getOrElse((_) => fail('Expected progress')), hasLength(1));
      verify(() => repository.getBudgetProgress(normalized)).called(1);
    });

    test('GetCategoriesUseCase delegates', () async {
      when(() => repository.getCategories())
          .thenAnswer((_) async => const Right(['Food']));

      final result = await GetCategoriesUseCase(repository)(const NoParams());

      expect(result.getOrElse((_) => const <String>[]), ['Food']);
    });
  });
}
