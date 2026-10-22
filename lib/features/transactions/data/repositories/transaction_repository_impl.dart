import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../datasources/transaction_remote_data_source.dart';
import '../models/transaction_model.dart';

/// Offline-first implementation: local writes are authoritative, remote sync
/// is best effort.
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  final TransactionLocalDataSource _localDataSource;
  final TransactionRemoteDataSource _remoteDataSource;

  @override
  ResultFuture<List<Transaction>> getTransactions() async {
    try {
      final models = await _localDataSource.getTransactions();
      final transactions =
          models.map((model) => model.toEntity()).toList(growable: true)
            ..sort((a, b) => b.date.compareTo(a.date));
      return Right(transactions);
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
  ResultFuture<Transaction> addTransaction(Transaction transaction) async {
    final pending = TransactionModel.fromEntity(transaction);

    try {
      await _localDataSource.saveTransaction(pending);
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

    final uploaded = await _upload(pending);
    if (!uploaded) {
      return Right(pending.toEntity());
    }

    final synced = pending.copyWith(isSynced: true);
    try {
      await _localDataSource.saveTransaction(synced);
      return Right(synced.toEntity());
    } on CacheException {
      // The backend already accepted the record. Keep it pending locally so the
      // next sync pass retries idempotently instead of losing the local state.
      return Right(pending.toEntity());
    }
  }

  Future<bool> _upload(TransactionModel transaction) async {
    try {
      return await _remoteDataSource.uploadTransaction(transaction);
    } catch (_) {
      return false;
    }
  }

  CacheFailure _toCacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);
}
