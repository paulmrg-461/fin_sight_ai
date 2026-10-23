import 'dart:io';

import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/services/calendar_migration.dart';
import 'package:fin_sight_ai/core/utils/app_constants.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/hive_budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/models/budget_model.dart';
import 'package:fin_sight_ai/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:fin_sight_ai/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

Map<String, dynamic> transactionJson({
  required String id,
  required DateTime localDate,
  DateTime? deletedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'amount': 10.0,
    'type': 'expense',
    'category': 'Food',
    'description': 'Dinner',
    'date': localDate.toUtc().toIso8601String(),
    'receiptImagePath': null,
    'walletId': null,
    'updatedAt': null,
    'isSynced': true,
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> budgetJson({
  required String id,
  required DateTime localMonth,
  DateTime? deletedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'category': 'Food',
    'monthlyLimit': 100.0,
    'month': localMonth.toUtc().toIso8601String(),
    'updatedAt': null,
    'isSynced': true,
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
  };
}

void main() {
  late Directory directory;
  late Box<dynamic> transactionsBox;
  late Box<dynamic> budgetsBox;
  late Box<dynamic> settingsBox;
  late HiveTransactionLocalDataSource transactionDataSource;
  late HiveBudgetLocalDataSource budgetDataSource;
  late TransactionRepositoryImpl transactionRepository;
  late BudgetRepositoryImpl budgetRepository;
  late CalendarMigrationService service;
  var counter = 0;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_migration_');
    Hive.init(directory.path);
    registerFallbackValue(
      TransactionEntity(
        id: 'fallback',
        amount: 1,
        type: TransactionType.expense,
        category: 'Food',
        description: '',
        date: DateTime.utc(2026, 10, 1, 12),
      ),
    );
    registerFallbackValue(
      BudgetEntity(
        id: 'fallback',
        category: 'Food',
        monthlyLimit: 1,
        month: DateTime.utc(2026, 10, 1, 12),
      ),
    );
  });

  setUp(() async {
    counter++;
    transactionsBox = await Hive.openBox<dynamic>('transactions_$counter');
    budgetsBox = await Hive.openBox<dynamic>('budgets_$counter');
    settingsBox = await Hive.openBox<dynamic>('settings_$counter');
    transactionDataSource = HiveTransactionLocalDataSource(transactionsBox);
    budgetDataSource = HiveBudgetLocalDataSource(budgetsBox);
    transactionRepository = TransactionRepositoryImpl(transactionDataSource);
    budgetRepository = BudgetRepositoryImpl(
      budgetDataSource,
      transactionRepository,
    );
    service = CalendarMigrationService(
      settings: settingsBox,
      transactionDataSource: transactionDataSource,
      budgetDataSource: budgetDataSource,
      transactionRepository: transactionRepository,
      budgetRepository: budgetRepository,
    );
  });

  tearDown(() async {
    await transactionsBox.close();
    await budgetsBox.close();
    await settingsBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  group('CalendarMigrationService', () {
    test(
      'rewrites legacy transaction and budget dates and sets the flag',
      () async {
        await transactionsBox.put(
          'tx-1',
          transactionJson(
            id: 'tx-1',
            localDate: DateTime(2026, 10, 31, 20, 30),
          ),
        );
        await budgetsBox.put(
          'budget-1',
          budgetJson(id: 'budget-1', localMonth: DateTime(2026, 10)),
        );

        final result = await service.migrate();

        expect(
          result.getOrElse(
            (failure) => fail('Expected migration, got $failure'),
          ),
          2,
        );
        final transaction = TransactionModel.fromJson(
          Map<String, dynamic>.from(transactionsBox.get('tx-1')! as Map),
        );
        expect(transaction.date, DateTime.utc(2026, 10, 31, 12));
        expect(transaction.date.isUtc, isTrue);
        final budget = BudgetModel.fromJson(
          Map<String, dynamic>.from(budgetsBox.get('budget-1')! as Map),
        );
        expect(budget.month, DateTime.utc(2026, 10, 1, 12));
        expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isTrue);
      },
    );

    test('migrates soft-deleted rows without losing tombstones', () async {
      await transactionsBox.put(
        'tx-deleted',
        transactionJson(
          id: 'tx-deleted',
          localDate: DateTime(2026, 10, 31, 20, 30),
          deletedAt: DateTime.utc(2026, 11, 2),
        ),
      );
      await budgetsBox.put(
        'budget-deleted',
        budgetJson(
          id: 'budget-deleted',
          localMonth: DateTime(2026, 10),
          deletedAt: DateTime.utc(2026, 11, 2),
        ),
      );

      final result = await service.migrate();

      expect(result.getOrElse((_) => fail('Expected migration')), 2);
      final transaction = TransactionModel.fromJson(
        Map<String, dynamic>.from(transactionsBox.get('tx-deleted')! as Map),
      );
      expect(transaction.date, DateTime.utc(2026, 10, 31, 12));
      expect(transaction.deletedAt, DateTime.utc(2026, 11, 2));
      final budget = BudgetModel.fromJson(
        Map<String, dynamic>.from(budgetsBox.get('budget-deleted')! as Map),
      );
      expect(budget.month, DateTime.utc(2026, 10, 1, 12));
      expect(budget.deletedAt, DateTime.utc(2026, 11, 2));
    });

    test('is idempotent once the flag is set', () async {
      await transactionsBox.put(
        'tx-1',
        transactionJson(id: 'tx-1', localDate: DateTime(2026, 10, 31, 20, 30)),
      );
      await service.migrate();

      final transactionSource = MockTransactionLocalDataSource();
      final budgetSource = MockBudgetLocalDataSource();
      final transactionRepo = MockTransactionRepository();
      final budgetRepo = MockBudgetRepository();
      final secondRun = CalendarMigrationService(
        settings: settingsBox,
        transactionDataSource: transactionSource,
        budgetDataSource: budgetSource,
        transactionRepository: transactionRepo,
        budgetRepository: budgetRepo,
      );

      final result = await secondRun.migrate();

      expect(result.getOrElse((_) => fail('Expected migration')), 0);
      verifyNever(() => transactionSource.getAllTransactions());
      verifyNever(() => budgetSource.getLegacyCalendarBudgets());
      verifyNever(() => transactionRepo.addTransaction(any()));
      verifyNever(() => budgetRepo.addBudget(any()));
    });

    test('does not set the flag when a write fails', () async {
      await transactionsBox.put(
        'tx-1',
        transactionJson(id: 'tx-1', localDate: DateTime(2026, 10, 31, 20, 30)),
      );
      final transactionRepo = MockTransactionRepository();
      final budgetRepo = MockBudgetRepository();
      when(() => transactionRepo.addTransaction(any())).thenAnswer(
        (_) async =>
            const Left(CacheFailure('Disk full.', code: 'cache_write_failed')),
      );
      final failing = CalendarMigrationService(
        settings: settingsBox,
        transactionDataSource: transactionDataSource,
        budgetDataSource: budgetDataSource,
        transactionRepository: transactionRepo,
        budgetRepository: budgetRepo,
      );

      final result = await failing.migrate();

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
      expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isNull);
      verifyNever(() => budgetRepo.addBudget(any()));
    });

    test('maps cache read failures', () async {
      final transactionSource = MockTransactionLocalDataSource();
      final budgetSource = MockBudgetLocalDataSource();
      when(
        () => transactionSource.getAllTransactions(),
      ).thenThrow(const CacheException('Corrupt.', code: 'cache_read_failed'));
      final failing = CalendarMigrationService(
        settings: settingsBox,
        transactionDataSource: transactionSource,
        budgetDataSource: budgetSource,
        transactionRepository: MockTransactionRepository(),
        budgetRepository: MockBudgetRepository(),
      );

      final result = await failing.migrate();

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
      expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isNull);
    });

    test('maps unexpected failures to a generic CacheFailure', () async {
      final transactionSource = MockTransactionLocalDataSource();
      final budgetSource = MockBudgetLocalDataSource();
      final transactionRepo = MockTransactionRepository();
      when(() => transactionSource.getAllTransactions()).thenAnswer(
        (_) async => [
          TransactionModel(
            id: 'tx-1',
            amount: 10,
            type: TransactionType.expense,
            category: 'Food',
            description: 'Dinner',
            date: DateTime.utc(2026, 10, 31),
          ),
        ],
      );
      when(() => budgetSource.getLegacyCalendarBudgets())
          .thenAnswer((_) async => []);
      when(() => transactionRepo.addTransaction(any()))
          .thenThrow(StateError('boom'));
      final failing = CalendarMigrationService(
        settings: settingsBox,
        transactionDataSource: transactionSource,
        budgetDataSource: budgetSource,
        transactionRepository: transactionRepo,
        budgetRepository: MockBudgetRepository(),
      );

      final result = await failing.migrate();

      expect(result.getLeft().toNullable()?.code, 'calendar_migration_failed');
      expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isNull);
    });

    test('stops at the per-run cap and resumes on the next run', () async {
      await transactionsBox.put(
        'tx-1',
        transactionJson(id: 'tx-1', localDate: DateTime(2026, 10, 31, 20, 30)),
      );
      await transactionsBox.put(
        'tx-2',
        transactionJson(id: 'tx-2', localDate: DateTime(2026, 10, 30, 20, 30)),
      );
      final capped = CalendarMigrationService(
        settings: settingsBox,
        transactionDataSource: transactionDataSource,
        budgetDataSource: budgetDataSource,
        transactionRepository: transactionRepository,
        budgetRepository: budgetRepository,
        maxWritesPerRun: 1,
      );

      final first = await capped.migrate();

      expect(first.getOrElse((_) => fail('Expected migration')), 1);
      expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isNull);

      final second = await service.migrate();

      expect(second.getOrElse((_) => fail('Expected migration')), 1);
      expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isTrue);
    });

    test('sets the flag without writes when every row is normalized', () async {
      await transactionsBox.put('tx-1', <String, dynamic>{
        ...transactionJson(
          id: 'tx-1',
          localDate: DateTime(2026, 10, 31, 20, 30),
        ),
        'date': DateTime.utc(2026, 10, 31, 12).toIso8601String(),
      });

      final result = await service.migrate();

      expect(result.getOrElse((_) => fail('Expected migration')), 0);
      expect(settingsBox.get(AppConstants.calendarMigrationFlagKey), isTrue);
    });
  });
}
