import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:fin_sight_ai/features/categories/domain/repositories/category_repository.dart';
import 'package:fin_sight_ai/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockScheduledPaymentRepository extends Mock
    implements ScheduledPaymentRepository {}

void main() {
  late MockCategoryRepository repository;
  late MockTransactionRepository transactions;
  late MockBudgetRepository budgets;
  late MockScheduledPaymentRepository schedules;
  final now = DateTime.utc(2026, 10, 20);

  final category = CategoryEntity(id: 'cat-1', name: 'Rent', createdAt: now);

  setUp(() {
    repository = MockCategoryRepository();
    transactions = MockTransactionRepository();
    budgets = MockBudgetRepository();
    schedules = MockScheduledPaymentRepository();
  });

  RenameCategoryUseCase buildRename() =>
      RenameCategoryUseCase(repository, transactions, budgets, schedules);

  group('GetCategoryCatalogUseCase', () {
    test('passes the archive flag to the repository', () async {
      when(() => repository.getCategories(includeArchived: true))
          .thenAnswer((_) async => Right([category]));

      final result = await GetCategoryCatalogUseCase(repository)(
        const GetCategoriesParams(includeArchived: true),
      );

      expect(result.fold((_) => null, (value) => value), [category]);
    });
  });

  group('AddCategoryUseCase', () {
    test('rejects empty names', () async {
      final result = await AddCategoryUseCase(repository)('   ');

      expect(result.fold((failure) => failure.code, (_) => null), 'empty_name');
      verifyNever(() => repository.addCategory(any()));
    });

    test('rejects overlong names', () async {
      final result = await AddCategoryUseCase(repository)('x' * 61);

      expect(
        result.fold((failure) => failure.code, (_) => null),
        'name_too_long',
      );
    });

    test('trims and delegates to the repository', () async {
      when(() => repository.addCategory('Pets'))
          .thenAnswer((_) async => Right(category));

      final result = await AddCategoryUseCase(repository)('  Pets  ');

      expect(result.isRight(), isTrue);
      verify(() => repository.addCategory('Pets')).called(1);
    });
  });

  group('RenameCategoryUseCase', () {
    test('requires an id', () async {
      final result = await buildRename()(
        const RenameCategoryParams(id: ' ', name: 'Pets'),
      );

      expect(result.fold((failure) => failure.code, (_) => null), 'missing_id');
    });

    test('rejects empty names', () async {
      final result = await buildRename()(
        const RenameCategoryParams(id: 'cat-1', name: '  '),
      );

      expect(result.fold((failure) => failure.code, (_) => null), 'empty_name');
    });

    test('trims, renames, and cascades to every usage', () async {
      final renamed = category.copyWith(name: 'Housing');
      when(() => repository.getCategories(includeArchived: true))
          .thenAnswer((_) async => Right([category]));
      when(() => repository.renameCategory('cat-1', 'Housing'))
          .thenAnswer((_) async => Right(renamed));
      when(() => transactions.renameCategory(from: 'Rent', to: 'Housing'))
          .thenAnswer((_) async => const Right(1));
      when(() => budgets.renameCategory(from: 'Rent', to: 'Housing'))
          .thenAnswer((_) async => const Right(1));
      when(() => schedules.renameCategory(from: 'Rent', to: 'Housing'))
          .thenAnswer((_) async => const Right(1));

      final result = await buildRename()(
        const RenameCategoryParams(id: ' cat-1 ', name: ' Housing '),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.renameCategory('cat-1', 'Housing')).called(1);
      verify(() => transactions.renameCategory(from: 'Rent', to: 'Housing'))
          .called(1);
      verify(() => budgets.renameCategory(from: 'Rent', to: 'Housing'))
          .called(1);
      verify(() => schedules.renameCategory(from: 'Rent', to: 'Housing'))
          .called(1);
    });

    test('propagates cascade failures', () async {
      when(() => repository.getCategories(includeArchived: true))
          .thenAnswer((_) async => Right([category]));
      when(() => repository.renameCategory('cat-1', 'Housing'))
          .thenAnswer((_) async => Right(category.copyWith(name: 'Housing')));
      when(() => transactions.renameCategory(from: 'Rent', to: 'Housing'))
          .thenAnswer(
            (_) async => const Left(
              CacheFailure('Cascade failed.', code: 'category_cascade_failed'),
            ),
          );

      final result = await buildRename()(
        const RenameCategoryParams(id: 'cat-1', name: 'Housing'),
      );

      expect(
        result.fold((failure) => failure.code, (_) => null),
        'category_cascade_failed',
      );
    });
  });

  group('SetCategoryArchivedUseCase', () {
    test('requires an id', () async {
      final result = await SetCategoryArchivedUseCase(repository)(
        const SetCategoryArchivedParams(id: '', archived: true),
      );

      expect(result.fold((failure) => failure.code, (_) => null), 'missing_id');
    });

    test('delegates archive changes', () async {
      when(() => repository.setArchived('cat-1', true))
          .thenAnswer((_) async => Right(category.copyWith(isArchived: true)));

      final result = await SetCategoryArchivedUseCase(repository)(
        const SetCategoryArchivedParams(id: ' cat-1 ', archived: true),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.setArchived('cat-1', true)).called(1);
    });

    test('propagates validation failures', () async {
      when(() => repository.setArchived(any(), any())).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Category not found.', code: 'category_not_found'),
        ),
      );

      final result = await SetCategoryArchivedUseCase(repository)(
        const SetCategoryArchivedParams(id: 'missing', archived: false),
      );

      expect(
        result.fold((failure) => failure.code, (_) => null),
        'category_not_found',
      );
    });
  });
}
