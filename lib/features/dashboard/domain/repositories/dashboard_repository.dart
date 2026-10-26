import '../../../../core/usecase/usecase.dart';
import '../entities/dashboard_entities.dart';

/// Domain contract for dashboard analytics.
abstract interface class DashboardRepository {
  /// Builds every dashboard output from one current and one previous read.
  ResultFuture<DashboardData> getDashboardData({
    required DateTime start,
    required DateTime end,
  });
}
