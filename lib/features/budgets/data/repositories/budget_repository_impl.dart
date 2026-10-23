import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_data_source.dart';
import '../models/budget_model.dart';

/// Persists budgets and aggregates spending from transactions.
@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(
    this._localDataSource,
    this._transactionRepository, {
    this.syncQueue,
    this.clock = const Clock(),
  });

  final BudgetLocalDataSource _localDataSource;
  final TransactionRepository _transactionRepository;
  final SyncQueue? syncQueue;
  final Clock clock;

  @override
  ResultFuture<BudgetEntity> addBudget(BudgetEntity budget) async {
    try {
      final now = clock.now();
      final pending = budget.copyWith(updatedAt: now, isSynced: false);
      final model = BudgetModel.fromEntity(pending);
      await _localDataSource.saveBudget(model);
      await _enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.budget,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: now,
        ),
      );
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the budget locally.',
          code: 'cache_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<void> deleteBudget(String id) async {
    try {
      final budgets = await _localDataSource.getAllBudgets();
      BudgetModel? existing;
      for (final budget in budgets) {
        if (budget.id == id) {
          existing = budget;
          break;
        }
      }
      if (existing == null) {
        return const Right(null);
      }

      final now = clock.now();
      final tombstone = BudgetModel.fromEntity(
        existing.copyWith(updatedAt: now, isSynced: false, deletedAt: now),
      );
      await _localDataSource.saveBudget(tombstone);
      await _enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.budget,
          entityId: tombstone.id,
          payload: tombstone.toJson(),
          queuedAt: now,
        ),
      );
      return const Right(null);
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to delete the budget locally.',
          code: 'cache_delete_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<BudgetProgress>> getBudgetProgress(DateTime month) async {
    try {
      final budgets = await _localDataSource.getBudgets(month);
      if (budgets.isEmpty) {
        return const Right([]);
      }

      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
      final transactionsResult = await _transactionRepository
          .getTransactionsByDateRange(start: start, end: end);
      final failure = transactionsResult.getLeft().toNullable();
      if (failure != null) {
        return Left(failure);
      }

      final transactions = transactionsResult.getOrElse(
        (_) => const <TransactionEntity>[],
      );
      final spentByCategory = <String, double>{};
      for (final transaction in transactions) {
        if (!transaction.isExpense) {
          continue;
        }
        spentByCategory.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }

      return Right(
        List<BudgetProgress>.unmodifiable(
          budgets.map(
            (budget) => BudgetProgress(
              budget: budget.toEntity(),
              spent: _round(spentByCategory[budget.category] ?? 0),
            ),
          ),
        ),
      );
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to calculate budget progress.',
          code: 'budget_progress_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<String>> getCategories() async {
    try {
      final budgets = await _localDataSource.getAllBudgets();
      final transactionsResult = await _transactionRepository.getTransactions();
      final failure = transactionsResult.getLeft().toNullable();
      if (failure != null) {
        return Left(failure);
      }

      final categories = <String>{
        for (final budget in budgets) budget.category,
        for (final transaction in transactionsResult.getOrElse(
          (_) => const <TransactionEntity>[],
        ))
          transaction.category,
      }.toList()..sort();

      return Right(List<String>.unmodifiable(categories));
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure('Unable to load categories.', code: 'categories_failed'),
      );
    }
  }

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

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  CacheFailure _cacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);
}
