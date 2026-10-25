import 'dart:io';

import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/datasources/hive_scheduled_payment_local_data_source.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/datasources/scheduled_payment_local_data_source.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/models/scheduled_payment_model.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledPaymentLocalDataSource extends Mock
    implements ScheduledPaymentLocalDataSource {}

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class FakeTransactionRepository implements TransactionRepository {
  final Map<String, TransactionEntity> saved = {};

  Failure? failure;

  @override
  ResultFuture<TransactionEntity> addTransaction(
    TransactionEntity transaction,
  ) async {
    final error = failure;
    if (error != null) {
      return Left(error);
    }
    saved[transaction.id] = transaction;
    return Right(transaction);
  }

  @override
  ResultFuture<void> deleteTransaction(String id) async {
    saved.remove(id);
    return const Right(null);
  }

  @override
  ResultFuture<List<TransactionEntity>> getTransactions() async =>
      Right(saved.values.toList());

  @override
  ResultFuture<TransactionEntity> updateTransaction(
    TransactionEntity transaction,
  ) async => Right(transaction);

  @override
  ResultFuture<int> renameCategory({
    required String from,
    required String to,
  }) async => const Right(0);

  @override
  ResultFuture<List<TransactionEntity>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    return Right(
      saved.values
          .where(
            (transaction) =>
                !transaction.date.isBefore(start) &&
                !transaction.date.isAfter(end),
          )
          .toList(),
    );
  }
}

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveScheduledPaymentLocalDataSource dataSource;
  late FakeTransactionRepository transactions;
  var counter = 0;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_sched_repo_');
    Hive.init(directory.path);
    registerFallbackValue(
      ScheduledPaymentModel(
        id: 'fallback',
        name: 'Fallback',
        amount: 1,
        category: 'Other',
        frequency: PaymentFrequency.monthly,
        nextDueDate: DateTime(2026),
        dayOfMonth: 1,
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('sched_repo_$counter');
    dataSource = HiveScheduledPaymentLocalDataSource(box);
    transactions = FakeTransactionRepository();
  });

  tearDown(() async {
    if (box.isOpen) {
      await box.close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  ScheduledPaymentRepositoryImpl repository({Clock? clock}) =>
      ScheduledPaymentRepositoryImpl(
        dataSource,
        transactions,
        clock: clock ?? const Clock(),
      );

  ScheduledPaymentEntity payment({
    String id = 'pay-1',
    DateTime? nextDueDate,
    bool active = true,
    double amount = 800,
    int dayOfMonth = 31,
    TransactionType type = TransactionType.expense,
    String category = 'Rent',
  }) {
    return ScheduledPaymentEntity(
      id: id,
      name: 'Rent',
      amount: amount,
      type: type,
      category: category,
      frequency: PaymentFrequency.monthly,
      nextDueDate: nextDueDate ?? DateTime(2026, 1, 31),
      dayOfMonth: dayOfMonth,
      walletId: 'wallet-bank',
      notes: 'Monthly',
      isActive: active,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('stores and sorts payments by due date', () async {
    final repo = repository();
    await repo.addPayment(payment(id: 'late', nextDueDate: DateTime(2026, 4)));
    await repo.addPayment(payment(id: 'soon', nextDueDate: DateTime(2026, 2)));

    final result = await repo.getPayments();

    final payments = result.fold((_) => <ScheduledPaymentEntity>[], (v) => v);
    expect(payments.map((item) => item.id), ['soon', 'late']);
  });

  test('pauses and resumes payments', () async {
    final repo = repository();
    await repo.addPayment(payment());

    final paused = await repo.setActive('pay-1', false);

    expect(paused.fold((_) => null, (value) => value.isActive), isFalse);
  });

  test('reports missing payments when pausing', () async {
    final result = await repository().setActive('missing', false);

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_not_found',
    );
  });

  test('deletes payments and ignores missing ids', () async {
    final repo = repository();
    await repo.addPayment(payment());

    final deleted = await repo.deletePayment('pay-1');
    final missing = await repo.deletePayment('missing');

    expect(deleted.isRight(), isTrue);
    expect(missing.isRight(), isTrue);
    expect(
      (await repo.getPayments()).fold((_) => [], (value) => value),
      isEmpty,
    );
  });

  test('processes every due period and advances the schedule', () async {
    final repo = repository();
    await repo.addPayment(payment());

    final result = await repo.processDue(DateTime(2026, 3, 15));

    final run = result.fold((_) => null, (value) => value)!;
    expect(run.createdCount, 2);
    expect(run.processed, 2);
    expect(transactions.saved.values.map((item) => item.date), [
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
    ]);
    expect(transactions.saved.values.first.walletId, 'wallet-bank');
    expect(transactions.saved.values.first.category, 'Rent');
    expect(transactions.saved.values.first.description, 'Rent');

    final stored = (await repo.getPayments()).fold(
      (_) => <ScheduledPaymentEntity>[],
      (value) => value,
    );
    expect(stored.single.nextDueDate, DateTime(2026, 3, 31));
    expect(stored.single.lastPaidAt, isNotNull);
  });

  test('records due income schedules as income transactions', () async {
    final repo = repository();
    await repo.addPayment(
      payment(type: TransactionType.income, category: 'Salary', amount: 3000),
    );

    final result = await repo.processDue(DateTime(2026, 2, 1));

    expect(result.fold((_) => null, (run) => run.createdCount), 1);
    final transaction = transactions.saved.values.single;
    expect(transaction.type, TransactionType.income);
    expect(transaction.isIncome, isTrue);
    expect(transaction.amount, 3000);
    expect(transaction.category, 'Salary');
    expect(transaction.date, DateTime(2026, 1, 31));
  });

  test('pays income schedules now with the income type', () async {
    final repo = repository();
    await repo.addPayment(
      payment(
        type: TransactionType.income,
        category: 'Salary',
        nextDueDate: DateTime(2026, 3, 1),
        dayOfMonth: 1,
      ),
    );

    final result = await repo.payNow('pay-1', DateTime(2026, 3, 15));

    expect(result.fold((_) => null, (run) => run.createdCount), 1);
    final transaction = transactions.saved.values.single;
    expect(transaction.type, TransactionType.income);
    expect(transaction.date, DateTime(2026, 3, 15));
  });

  test('keeps deterministic ids for income schedules', () async {
    final repo = repository();
    final income = payment(
      type: TransactionType.income,
      category: 'Salary',
      nextDueDate: DateTime(2026, 1, 31),
    );
    await repo.addPayment(income);
    final first = await repo.processDue(DateTime(2026, 1, 31));
    final firstId = first.fold((_) => null, (run) => run.created.single.id);

    await dataSource.savePayment(ScheduledPaymentModel.fromEntity(income));
    final second = await repo.processDue(DateTime(2026, 1, 31));
    final secondId = second.fold((_) => null, (run) => run.created.single.id);

    expect(secondId, firstId);
    expect(transactions.saved, hasLength(1));
    expect(transactions.saved.values.single.type, TransactionType.income);
  });

  test('is idempotent when reprocessing the same period', () async {
    final repo = repository();
    await repo.addPayment(payment());
    final first = await repo.processDue(DateTime(2026, 3, 15));
    final firstIds = first.fold(
      (_) => <String>[],
      (run) => run.created.map((t) => t.id).toList(),
    );

    // Simulate a crash before the schedule advanced.
    await dataSource.savePayment(ScheduledPaymentModel.fromEntity(payment()));
    final second = await repo.processDue(DateTime(2026, 3, 15));
    final secondIds = second.fold(
      (_) => <String>[],
      (run) => run.created.map((t) => t.id).toList(),
    );

    expect(secondIds, firstIds);
    expect(transactions.saved.keys, containsAll(firstIds));
    expect(transactions.saved, hasLength(2));
  });

  test('skips paused payments', () async {
    final repo = repository();
    await repo.addPayment(payment(active: false));

    final result = await repo.processDue(DateTime(2026, 3, 15));

    expect(result.fold((_) => null, (run) => run.createdCount), 0);
    expect(transactions.saved, isEmpty);
  });

  test('ignores payments due in the future', () async {
    final repo = repository();
    await repo.addPayment(payment(nextDueDate: DateTime(2026, 4, 30)));

    final result = await repo.processDue(DateTime(2026, 3, 15));

    expect(result.fold((_) => null, (run) => run.createdCount), 0);
  });

  test('pays now and advances past today', () async {
    final repo = repository();
    await repo.addPayment(
      payment(nextDueDate: DateTime(2026, 2, 1), dayOfMonth: 1),
    );

    final result = await repo.payNow('pay-1', DateTime(2026, 3, 15));

    final run = result.fold((_) => null, (value) => value)!;
    expect(run.createdCount, 1);
    expect(transactions.saved.values.single.date, DateTime(2026, 3, 15));

    final stored = (await repo.getPayments()).fold(
      (_) => <ScheduledPaymentEntity>[],
      (value) => value,
    );
    expect(stored.single.nextDueDate, DateTime(2026, 4, 1));
  });

  test('pays early and skips the next period', () async {
    final repo = repository();
    await repo.addPayment(
      payment(nextDueDate: DateTime(2026, 4, 1), dayOfMonth: 1),
    );

    await repo.payNow('pay-1', DateTime(2026, 3, 15));

    final stored = (await repo.getPayments()).fold(
      (_) => <ScheduledPaymentEntity>[],
      (value) => value,
    );
    expect(stored.single.nextDueDate, DateTime(2026, 5, 1));
  });

  test('does not advance twice when paying again the same day', () async {
    final fixed = _FixedClock(DateTime(2026, 3, 15, 10));
    final repo = repository(clock: fixed);
    await repo.addPayment(
      payment(nextDueDate: DateTime(2026, 4, 1), dayOfMonth: 1),
    );

    await repo.payNow('pay-1', fixed.now());
    final second = await repo.payNow('pay-1', fixed.now());

    expect(second.fold((_) => null, (run) => run.processed), 0);
    final stored = (await repo.getPayments()).fold(
      (_) => <ScheduledPaymentEntity>[],
      (value) => value,
    );
    expect(stored.single.nextDueDate, DateTime(2026, 5, 1));
  });

  test('reports missing payments when paying', () async {
    final result = await repository().payNow('missing', DateTime(2026, 3, 15));

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_not_found',
    );
  });

  test('propagates transaction failures while processing', () async {
    final repo = repository();
    await repo.addPayment(payment());
    transactions.failure = const CacheFailure('Disk full.');

    final result = await repo.processDue(DateTime(2026, 3, 15));

    expect(
      result.fold((failure) => failure.message, (_) => null),
      'Disk full.',
    );
  });

  test('propagates transaction failures while paying', () async {
    final repo = repository();
    await repo.addPayment(payment());
    transactions.failure = const CacheFailure('Disk full.');

    final result = await repo.payNow('pay-1', DateTime(2026, 3, 15));

    expect(
      result.fold((failure) => failure.message, (_) => null),
      'Disk full.',
    );
  });

  test('maps cache failures from the data source', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.getPayments()).thenThrow(
      const CacheException(
        'Storage down.',
        code: 'scheduled_payment_read_failed',
      ),
    );

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).getPayments();

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_read_failed',
    );
  });

  test('maps cache failures while adding', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.savePayment(any())).thenThrow(
      const CacheException(
        'Disk full.',
        code: 'scheduled_payment_write_failed',
      ),
    );

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).addPayment(payment());

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_write_failed',
    );
  });

  test('maps cache failures while pausing', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.getPayments())
        .thenAnswer((_) async => [ScheduledPaymentModel.fromEntity(payment())]);
    when(() => failing.savePayment(any())).thenThrow(
      const CacheException(
        'Disk full.',
        code: 'scheduled_payment_write_failed',
      ),
    );

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).setActive('pay-1', false);

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_write_failed',
    );
  });

  test('maps cache failures while deleting', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.getPayments())
        .thenAnswer((_) async => [ScheduledPaymentModel.fromEntity(payment())]);
    when(() => failing.deletePayment(any())).thenThrow(
      const CacheException(
        'Disk full.',
        code: 'scheduled_payment_delete_failed',
      ),
    );

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).deletePayment('pay-1');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_delete_failed',
    );
  });

  test('maps cache failures while processing', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.getPayments()).thenThrow(
      const CacheException(
        'Storage down.',
        code: 'scheduled_payment_read_failed',
      ),
    );

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).processDue(DateTime(2026, 3, 15));

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_read_failed',
    );
  });

  test('maps cache failures while paying now', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.getPayments())
        .thenAnswer((_) async => [ScheduledPaymentModel.fromEntity(payment())]);
    when(() => failing.savePayment(any())).thenThrow(
      const CacheException(
        'Disk full.',
        code: 'scheduled_payment_write_failed',
      ),
    );

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).payNow('pay-1', DateTime(2026, 3, 15));

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'scheduled_payment_write_failed',
    );
  });

  test('maps unexpected errors to a cache failure', () async {
    final failing = MockScheduledPaymentLocalDataSource();
    when(() => failing.getPayments()).thenThrow(StateError('boom'));

    final result = await ScheduledPaymentRepositoryImpl(
      failing,
      transactions,
    ).getPayments();

    expect(
      result.fold((failure) => failure.runtimeType, (_) => null),
      CacheFailure,
    );
  });
}
