import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/services/dashboard_calculator.dart';

/// Aggregates dashboard analytics from the transactions repository.
@LazySingleton(as: DashboardRepository)
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._transactions);

  /// Recent activity cards shown under the charts.
  static const int recentActivityLimit = 5;

  final TransactionRepository _transactions;

  @override
  ResultFuture<DashboardData> getDashboardData({
    required DateTime start,
    required DateTime end,
  }) async {
    final currentResult = await _fetch(start, end);
    final failure = currentResult.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }
    final current = currentResult.getOrElse((_) => const <TransactionEntity>[]);

    final previousRange = _previousMonth(start);
    final previousResult = await _fetch(previousRange.start, previousRange.end);
    final previousFailure = previousResult.getLeft().toNullable();
    if (previousFailure != null) {
      return Left(previousFailure);
    }
    final previous = previousResult.getOrElse(
      (_) => const <TransactionEntity>[],
    );

    return Right(
      DashboardData(
        summary: DashboardCalculator.summary(
          current: current,
          previous: previous,
        ),
        breakdown: DashboardCalculator.categoryBreakdown(current),
        comparison: DashboardCalculator.monthlyComparison(
          current: current,
          previous: previous,
        ),
        recentTransactions: List<TransactionEntity>.unmodifiable(
          current.take(recentActivityLimit),
        ),
        start: start,
        end: end,
      ),
    );
  }

  Future<Result<List<TransactionEntity>>> _fetch(DateTime start, DateTime end) {
    return _transactions.getTransactionsByDateRange(start: start, end: end);
  }

  ({DateTime start, DateTime end}) _previousMonth(DateTime currentStart) {
    final year = currentStart.year;
    final month = currentStart.month;
    if (currentStart.isUtc) {
      return (
        start: DateTime.utc(year, month - 1, 1),
        end: DateTime.utc(year, month, 0, 23, 59, 59, 999),
      );
    }
    return (
      start: DateTime(year, month - 1, 1),
      end: DateTime(year, month, 0, 23, 59, 59, 999),
    );
  }
}
