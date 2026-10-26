import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/scheduled_payment_entity.dart';
import '../../domain/repositories/scheduled_payment_repository.dart';
import '../../domain/services/schedule_calculator.dart';
import '../datasources/scheduled_payment_local_data_source.dart';
import '../models/scheduled_payment_model.dart';

/// Local-first schedules that materialize ordinary transactions.
@LazySingleton(as: ScheduledPaymentRepository)
class ScheduledPaymentRepositoryImpl implements ScheduledPaymentRepository {
  ScheduledPaymentRepositoryImpl(
    this._localDataSource,
    this._transactionRepository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
    this.syncQueue,
  });

  static const int maxCatchUpPeriods = 60;

  final ScheduledPaymentLocalDataSource _localDataSource;
  final TransactionRepository _transactionRepository;
  final Uuid uuid;
  final Clock clock;
  final SyncQueue? syncQueue;

  @override
  ResultFuture<List<ScheduledPaymentEntity>> getPayments() async {
    try {
      final models = await _localDataSource.getPayments();
      final sorted = models.toList()
        ..sort((a, b) {
          final byDate = a.nextDueDate.compareTo(b.nextDueDate);
          return byDate != 0 ? byDate : a.name.compareTo(b.name);
        });
      return Right(sorted.map((model) => model.toEntity()).toList());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read scheduled payments.',
          code: 'scheduled_payment_read_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<ScheduledPaymentEntity> addPayment(
    ScheduledPaymentEntity payment,
  ) async {
    try {
      final now = clock.now();
      final model = ScheduledPaymentModel.fromEntity(
        payment.copyWith(updatedAt: now, isSynced: false),
      );
      await _localDataSource.savePayment(model);
      await _enqueue(model);
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the scheduled payment locally.',
          code: 'scheduled_payment_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<ScheduledPaymentEntity> setActive(
    String id,
    bool isActive,
  ) async {
    try {
      final model = await _findById(id);
      if (model == null) {
        return const Left(
          ValidationFailure(
            'Scheduled payment not found.',
            code: 'scheduled_payment_not_found',
          ),
        );
      }
      final updated = model.copyWith(
        isActive: isActive,
        updatedAt: clock.now(),
        isSynced: false,
      );
      await _localDataSource.savePayment(updated);
      await _enqueue(updated);
      return Right(updated.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to update the scheduled payment.',
          code: 'scheduled_payment_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<void> deletePayment(String id) async {
    try {
      final model = await _findById(id);
      if (model == null) {
        return const Right(null);
      }
      final now = clock.now();
      final tombstone = ScheduledPaymentModel.fromEntity(
        model.copyWith(updatedAt: now, isSynced: false, deletedAt: now),
      );
      await _localDataSource.savePayment(tombstone);
      await _enqueue(tombstone);
      return const Right(null);
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to delete the scheduled payment.',
          code: 'scheduled_payment_delete_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<ScheduledPaymentRun> processDue(DateTime now) async {
    try {
      final models = await _localDataSource.getPayments();
      final today = ScheduleCalculator.dateOnly(now);
      final created = <TransactionEntity>[];
      var processed = 0;

      for (final model in models) {
        if (!model.isActive) {
          continue;
        }

        var due = ScheduleCalculator.dateOnly(model.nextDueDate);
        if (due.isAfter(today)) {
          continue;
        }

        var iterations = 0;
        while (!due.isAfter(today) && iterations < maxCatchUpPeriods) {
          final transaction = await _record(model, due);
          final failure = transaction.getLeft().toNullable();
          if (failure != null) {
            return Left(failure);
          }
          created.add(transaction.getRight().toNullable()!);
          processed++;

          due = ScheduleCalculator.advanceOnce(
            current: due,
            frequency: model.frequency,
            dayOfMonth: model.dayOfMonth,
          );
          iterations++;
        }

        final paidAt = clock.now();
        final updated = ScheduledPaymentModel.fromEntity(
          model.copyWith(
            nextDueDate: due,
            lastPaidAt: paidAt,
            updatedAt: paidAt,
            isSynced: false,
          ),
        );
        await _localDataSource.savePayment(updated);
        await _enqueue(updated);
      }

      return Right(
        ScheduledPaymentRun(
          created: List<TransactionEntity>.unmodifiable(created),
          processed: processed,
        ),
      );
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to process scheduled payments.',
          code: 'scheduled_payment_process_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<ScheduledPaymentRun> payNow(String id, DateTime now) async {
    try {
      final model = await _findById(id);
      if (model == null) {
        return const Left(
          ValidationFailure(
            'Scheduled payment not found.',
            code: 'scheduled_payment_not_found',
          ),
        );
      }

      final today = ScheduleCalculator.dateOnly(now);
      if (model.lastPaidAt != null &&
          ScheduleCalculator.dateOnly(model.lastPaidAt!) == today) {
        // Already charged today; avoid advancing a second period.
        return const Right(ScheduledPaymentRun());
      }

      final transaction = await _record(model, today);
      final failure = transaction.getLeft().toNullable();
      if (failure != null) {
        return Left(failure);
      }

      var due = ScheduleCalculator.advanceOnce(
        current: ScheduleCalculator.dateOnly(model.nextDueDate),
        frequency: model.frequency,
        dayOfMonth: model.dayOfMonth,
      );
      var iterations = 0;
      while (!due.isAfter(today) && iterations < maxCatchUpPeriods) {
        due = ScheduleCalculator.advanceOnce(
          current: due,
          frequency: model.frequency,
          dayOfMonth: model.dayOfMonth,
        );
        iterations++;
      }

      final paidAt = clock.now();
      final updated = ScheduledPaymentModel.fromEntity(
        model.copyWith(
          nextDueDate: due,
          lastPaidAt: paidAt,
          updatedAt: paidAt,
          isSynced: false,
        ),
      );
      await _localDataSource.savePayment(updated);
      await _enqueue(updated);

      return Right(
        ScheduledPaymentRun(
          created: List<TransactionEntity>.unmodifiable([
            transaction.getRight().toNullable()!,
          ]),
          processed: 1,
        ),
      );
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to record the scheduled payment.',
          code: 'scheduled_payment_pay_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<int> renameCategory({
    required String from,
    required String to,
  }) async {
    if (from == to) {
      return const Right(0);
    }
    try {
      final models = await _localDataSource.getPayments();
      var updated = 0;
      for (final model in models) {
        if (model.category != from) {
          continue;
        }
        final next = ScheduledPaymentModel.fromEntity(
          model.copyWith(category: to, updatedAt: clock.now(), isSynced: false),
        );
        await _localDataSource.savePayment(next);
        await _enqueue(next);
        updated++;
      }
      return Right(updated);
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to rename the scheduled payment category.',
          code: 'category_cascade_failed',
        ),
      );
    }
  }

  Future<void> _enqueue(ScheduledPaymentModel model) async {
    final queue = syncQueue;
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.scheduledPayment,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: clock.now(),
        ),
      );
    } catch (_) {
      // The local write is authoritative; a queue failure must not lose it.
    }
  }

  Future<ScheduledPaymentModel?> _findById(String id) async {
    final models = await _localDataSource.getPayments();
    for (final model in models) {
      if (model.id == id) {
        return model;
      }
    }
    return null;
  }

  Future<Result<TransactionEntity>> _record(
    ScheduledPaymentEntity payment,
    DateTime date,
  ) {
    final due = ScheduleCalculator.dateOnly(date);
    final transaction = TransactionEntity(
      // Deterministic id keeps retries and repeated processing idempotent.
      id: uuid.v5(
        Namespace.url.value,
        'scheduled:${payment.id}:${due.toIso8601String()}',
      ),
      amount: payment.amount,
      type: payment.type,
      category: payment.category,
      description: payment.name,
      date: due,
      walletId: payment.walletId,
    );
    return _transactionRepository.addTransaction(transaction);
  }
}
