import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../models/transaction_model.dart';

/// Local-first implementation of [TransactionRepository].
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._localDataSource);

  final TransactionLocalDataSource _localDataSource;

  @override
  ResultFuture<TransactionEntity> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await _localDataSource.saveTransaction(model);
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
      await _localDataSource.deleteTransaction(id);
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
}
