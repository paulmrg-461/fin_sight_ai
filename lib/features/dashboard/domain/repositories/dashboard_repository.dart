import '../../../../core/usecase/usecase.dart';
import '../entities/dashboard_entities.dart';

/// Domain contract for dashboard analytics.
abstract interface class DashboardRepository {
  ResultFuture<DashboardSummaryEntity> getDashboardSummary({
    required DateTime start,
    required DateTime end,
  });

  ResultFuture<List<CategoryBreakdown>> getCategoryBreakdown({
    required DateTime start,
    required DateTime end,
  });

  ResultFuture<MonthlyComparisonEntity> getMonthlyComparison({
    required DateTime start,
    required DateTime end,
  });
}
