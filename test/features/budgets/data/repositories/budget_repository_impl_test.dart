import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/models/budget_model.dart';
import 'package:fin_sight_ai/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockSyncQueue extends Mock implements SyncQueue {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

BudgetModel buildBudgetModel({
  String id = 'budget-1',
  String category = 'Food',
  double limit = 100,
}) => BudgetModel(
  id: id,
  category: category,
  monthlyLimit: limit,
  month: DateTime(2026, 10),
);

TransactionEntity tx({
  required double amount,
  required TransactionType type,
  String category = 'Food',
}) => TransactionEntity(
  id: 'tx-${amount}_${type.name}_$category',
  amount: amount,
  type: type,
  category: category,
  description: '',
  date: DateTime.utc(2026, 10, 1),
);

void main() {
  final month = DateTime(2026, 10);
  final start = DateTime(2026, 10);
  final end = DateTime(2026, 10, 31, 23, 59, 59, 999);

  late MockBudgetLocalDataSource local;
  late MockTransactionRepository transactions;
  late BudgetRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(buildBudgetModel());
    registerFallbackValue(
      SyncOperation.delete(
        entityType: SyncEntityType.budget,
        entityId: 'fallback',
        queuedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    local = MockBudgetLocalDataSource();
    transactions = MockTransactionRepository();
    repository = BudgetRepositoryImpl(local, transactions);
  });

  group('BudgetRepositoryImpl.getBudgetProgress', () {
    test('aggregates expenses by category for the month', () async {
      when(() => local.getBudgets(month))
          .thenAnswer((_) async => [buildBudgetModel()]);
      when(
        () => transactions.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer(
        (_) async => Right([
          tx(amount: 40, type: TransactionType.expense),
          tx(amount: 20, type: TransactionType.expense, category: 'Travel'),
          tx(amount: 100, type: TransactionType.income, category: 'Salary'),
        ]),
      );

      final result = await repository.getBudgetProgress(month);

      final progress = result.getOrElse((_) => fail('Expected progress'));
      expect(progress, hasLength(1));
      expect(progress.single.spent, 40);
      expect(progress.single.percentage, 0.4);
    });

    test('returns an empty list without budgets', () async {
      when(() => local.getBudgets(any())).thenAnswer((_) async => []);

      final result = await repository.getBudgetProgress(month);

      expect(result.getOrElse((_) => fail('Expected progress')), isEmpty);
      verifyNever(
        () => transactions.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      );
    });

    test('propagates transaction failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => local.getBudgets(month))
          .thenAnswer((_) async => [buildBudgetModel()]);
      when(
        () => transactions.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer((_) async => const Left(failure));

      final result = await repository.getBudgetProgress(month);

      expect(result.getLeft().toNullable(), failure);
    });

    test('maps local failures', () async {
      when(
        () => local.getBudgets(any()),
      ).thenThrow(const CacheException('Corrupt.', code: 'cache_read_failed'));

      final result = await repository.getBudgetProgress(month);

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
    });
  });

  group('BudgetRepositoryImpl.getCategories', () {
    test('merges budget and transaction categories', () async {
      when(() => local.getAllBudgets())
          .thenAnswer((_) async => [buildBudgetModel()]);
      when(() => transactions.getTransactions()).thenAnswer(
        (_) async => Right([
          tx(amount: 10, type: TransactionType.expense, category: 'Travel'),
          tx(amount: 100, type: TransactionType.income, category: 'Salary'),
        ]),
      );

      final result = await repository.getCategories();

      expect(result.getOrElse((_) => const <String>[]), [
        'Food',
        'Salary',
        'Travel',
      ]);
    });

    test('propagates transaction failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => local.getAllBudgets()).thenAnswer((_) async => []);
      when(() => transactions.getTransactions())
          .thenAnswer((_) async => const Left(failure));

      final result = await repository.getCategories();

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('BudgetRepositoryImpl.addBudget', () {
    test('persists the budget', () async {
      when(() => local.saveBudget(any())).thenAnswer((_) async {});

      final result = await repository.addBudget(
        BudgetEntity(
          id: 'budget-1',
          category: 'Food',
          monthlyLimit: 100,
          month: month,
        ),
      );

      expect(result.getOrElse((_) => fail('Expected budget')).id, 'budget-1');
    });

    test('maps write failures', () async {
      when(() => local.saveBudget(any())).thenThrow(
        const CacheException('Disk full.', code: 'cache_write_failed'),
      );

      final result = await repository.addBudget(
        BudgetEntity(
          id: 'budget-1',
          category: 'Food',
          monthlyLimit: 100,
          month: month,
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });
  });

  test('deletes a budget with a tombstone', () async {
    when(() => local.getAllBudgets())
        .thenAnswer((_) async => [buildBudgetModel()]);
    when(() => local.saveBudget(any())).thenAnswer((_) async {});

    final result = await repository.deleteBudget('budget-1');

    expect(result.isRight(), isTrue);
    final saved =
        verify(() => local.saveBudget(captureAny())).captured.single
            as BudgetModel;
    expect(saved.isDeleted, isTrue);
    expect(saved.isSynced, isFalse);
    verifyNever(() => local.deleteBudget(any()));
  });

  test('ignores missing budgets on delete', () async {
    when(() => local.getAllBudgets()).thenAnswer((_) async => []);

    final result = await repository.deleteBudget('missing');

    expect(result.isRight(), isTrue);
    verifyNever(() => local.saveBudget(any()));
  });

  group('BudgetRepositoryImpl.updateBudget', () {
    test('persists the updated budget with the same id', () async {
      when(() => local.saveBudget(any())).thenAnswer((_) async {});

      final result = await repository.updateBudget(
        BudgetEntity(
          id: 'budget-1',
          category: 'Housing',
          monthlyLimit: 250,
          month: DateTime(2026, 10),
        ),
      );

      expect(result.fold((_) => null, (value) => value.id), 'budget-1');
      final saved =
          verify(() => local.saveBudget(captureAny())).captured.single
              as BudgetModel;
      expect(saved.category, 'Housing');
      expect(saved.monthlyLimit, 250);
    });
  });

  group('sync queue integration', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    late MockSyncQueue queue;

    setUp(() {
      queue = MockSyncQueue();
      when(() => queue.enqueue(any())).thenAnswer((_) async {});
    });

    test('enqueues an upsert when adding a budget', () async {
      when(() => local.saveBudget(any())).thenAnswer((_) async {});
      final repository = BudgetRepositoryImpl(
        local,
        transactions,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      await repository.addBudget(
        BudgetEntity(
          id: 'budget-1',
          category: 'Food',
          monthlyLimit: 100,
          month: DateTime(2026, 10),
        ),
      );

      final operation =
          verify(() => queue.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(operation.entityType, SyncEntityType.budget);
      expect(operation.operationType, SyncOperationType.upsert);
      expect(operation.payload['isSynced'], isFalse);
      expect(operation.payload['updatedAt'], now.toUtc().toIso8601String());
    });

    test('enqueues a tombstone when deleting a budget', () async {
      when(() => local.getAllBudgets())
          .thenAnswer((_) async => [buildBudgetModel()]);
      when(() => local.saveBudget(any())).thenAnswer((_) async {});
      final repository = BudgetRepositoryImpl(
        local,
        transactions,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      await repository.deleteBudget('budget-1');

      final operation =
          verify(() => queue.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(operation.operationType, SyncOperationType.upsert);
      expect(operation.payload['deletedAt'], isNotNull);
    });

    test('renames matching budget categories and enqueues upserts', () async {
      when(() => local.getAllBudgetsIncludingDeleted()).thenAnswer(
        (_) async => [
          buildBudgetModel(category: 'Food'),
          buildBudgetModel(id: 'budget-2', category: 'Rent'),
        ],
      );
      when(() => local.saveBudget(any())).thenAnswer((_) async {});
      final repository = BudgetRepositoryImpl(
        local,
        transactions,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      final result = await repository.renameCategory(
        from: 'Food',
        to: 'Groceries',
      );

      expect(result.fold((_) => -1, (count) => count), 1);
      final operation =
          verify(() => queue.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(operation.payload['category'], 'Groceries');
    });

    test('a queue failure does not fail the local write', () async {
      when(() => local.saveBudget(any())).thenAnswer((_) async {});
      when(() => queue.enqueue(any())).thenThrow(Exception('queue down'));
      final repository = BudgetRepositoryImpl(
        local,
        transactions,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      final result = await repository.addBudget(
        BudgetEntity(
          id: 'budget-1',
          category: 'Food',
          monthlyLimit: 100,
          month: DateTime(2026, 10),
        ),
      );

      expect(result.isRight(), isTrue);
    });
  });
}
