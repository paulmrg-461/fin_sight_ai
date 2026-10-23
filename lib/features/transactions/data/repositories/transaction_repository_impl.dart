import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../models/transaction_model.dart';

/// Local-first implementation of [TransactionRepository].
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(
    this._localDataSource, {
    this.syncQueue,
    this.clock = const Clock(),
  });

  final TransactionLocalDataSource _localDataSource;
  final SyncQueue? syncQueue;
  final Clock clock;

  @override
  ResultFuture<TransactionEntity> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final pending = transaction.copyWith(
        updatedAt: clock.now(),
        isSynced: false,
      );
      final model = TransactionModel.fromEntity(pending);
      await _localDataSource.saveTransaction(model);
      await _enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.transaction,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: clock.now(),
        ),
      );
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the transaction locally.',
          code: 'cache_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<TransactionEntity>> getTransactions() async {
    try {
      final models = await _localDataSource.getTransactions();
      return Right(_toEntities(models));
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read local transactions.',
          code: 'cache_read_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<void> deleteTransaction(String id) async {
    try {
      final models = await _localDataSource.getTransactions();
      TransactionModel? existing;
      for (final model in models) {
        if (model.id == id) {
          existing = model;
          break;
        }
      }
      if (existing == null) {
        return const Right(null);
      }

      final now = clock.now();
      final tombstone = TransactionModel.fromEntity(
        existing.copyWith(updatedAt: now, isSynced: false, deletedAt: now),
      );
      await _localDataSource.saveTransaction(tombstone);
      await _enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.transaction,
          entityId: tombstone.id,
          payload: tombstone.toJson(),
          queuedAt: now,
        ),
      );
      return const Right(null);
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to delete the transaction locally.',
          code: 'cache_delete_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<TransactionEntity>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final models = await _localDataSource.getTransactionsByDateRange(
        start: start,
        end: end,
      );
      return Right(_toEntities(models));
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read local transactions.',
          code: 'cache_read_failed',
        ),
      );
    }
  }

  List<TransactionEntity> _toEntities(List<TransactionModel> models) =>
      List<TransactionEntity>.unmodifiable(
        models.map((model) => model.toEntity()),
      );

  CacheFailure _toCacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);

  Future<void> _enqueue(SyncOperation operation) async {
    final queue = syncQueue;
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(operation);
    } catch (_) {
      // The local write is authoritative; a queue failure must not lose it.
    }
  }
}
