import 'package:fpdart/fpdart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/budgets/data/datasources/budget_local_data_source.dart';
import '../../features/budgets/domain/repositories/budget_repository.dart';
import '../../features/transactions/data/datasources/transaction_local_data_source.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../domain/failure.dart';
import '../error/exceptions.dart';
import '../usecase/usecase.dart';
import '../utils/app_constants.dart';
import '../utils/calendar_date.dart';

/// One-time rewrite of locally stored calendar dates to the UTC-noon
/// convention.
///
/// Runs before the BLoCs are created so every screen reads migrated rows. The
/// `settings` flag makes the migration idempotent; it is written only after
/// every pending row has been persisted. [maxWritesPerRun] bounds the work
/// queued at launch: when a dataset is larger, the flag stays unset and the
/// next launch resumes with the remaining rows.
class CalendarMigrationService {
  const CalendarMigrationService({
    required this.settings,
    required this.transactionDataSource,
    required this.budgetDataSource,
    required this.transactionRepository,
    required this.budgetRepository,
    this.maxWritesPerRun = defaultMaxWritesPerRun,
  });

  static const int defaultMaxWritesPerRun = 500;

  final Box<dynamic> settings;
  final TransactionLocalDataSource transactionDataSource;
  final BudgetLocalDataSource budgetDataSource;
  final TransactionRepository transactionRepository;
  final BudgetRepository budgetRepository;
  final int maxWritesPerRun;

  Future<Result<int>> migrate() async {
    try {
      if (settings.get(AppConstants.calendarMigrationFlagKey) == true) {
        return const Right(0);
      }

      final transactions = await transactionDataSource.getAllTransactions();
      final budgets = await budgetDataSource.getLegacyCalendarBudgets();

      final pendingTransactions = <TransactionEntity>[];
      for (final transaction in transactions) {
        if (isCalendarDate(transaction.date)) {
          continue;
        }
        final normalized = calendarDate(transaction.date.toLocal());
        if (normalized == transaction.date) {
          continue;
        }
        pendingTransactions.add(transaction.copyWith(date: normalized));
      }

      var migrated = 0;
      for (final transaction in pendingTransactions) {
        if (migrated >= maxWritesPerRun) {
          return Right(migrated);
        }
        final result = await transactionRepository.addTransaction(transaction);
        final failure = result.getLeft().toNullable();
        if (failure != null) {
          return Left(failure);
        }
        migrated++;
      }

      for (final budget in budgets) {
        if (migrated >= maxWritesPerRun) {
          return Right(migrated);
        }
        final result = await budgetRepository.addBudget(budget);
        final failure = result.getLeft().toNullable();
        if (failure != null) {
          return Left(failure);
        }
        migrated++;
      }

      await settings.put(AppConstants.calendarMigrationFlagKey, true);
      return Right(migrated);
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to migrate calendar dates.',
          code: 'calendar_migration_failed',
        ),
      );
    }
  }
}
