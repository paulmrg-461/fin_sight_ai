import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dashboard_entities.dart';
import '../repositories/dashboard_repository.dart';

/// Inclusive period used by every dashboard query.
class DashboardRangeParams {
  const DashboardRangeParams({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardRangeParams && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

@lazySingleton
class GetDashboardSummaryUseCase
    implements UseCase<DashboardSummaryEntity, DashboardRangeParams> {
  const GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Result<DashboardSummaryEntity>> call(DashboardRangeParams params) {
    if (params.start.isAfter(params.end)) {
      return Future.value(_invalidRange());
    }
    return _repository.getDashboardSummary(
      start: params.start,
      end: params.end,
    );
  }
}

@lazySingleton
class GetCategoryBreakdownUseCase
    implements UseCase<List<CategoryBreakdown>, DashboardRangeParams> {
  const GetCategoryBreakdownUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Result<List<CategoryBreakdown>>> call(DashboardRangeParams params) {
    if (params.start.isAfter(params.end)) {
      return Future.value(_invalidRange());
    }
    return _repository.getCategoryBreakdown(
      start: params.start,
      end: params.end,
    );
  }
}

@lazySingleton
class GetMonthlyComparisonUseCase
    implements UseCase<MonthlyComparisonEntity, DashboardRangeParams> {
  const GetMonthlyComparisonUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Result<MonthlyComparisonEntity>> call(DashboardRangeParams params) {
    if (params.start.isAfter(params.end)) {
      return Future.value(_invalidRange());
    }
    return _repository.getMonthlyComparison(
      start: params.start,
      end: params.end,
    );
  }
}

Left<Failure, T> _invalidRange<T>() => const Left(
  ValidationFailure(
    'The start date must be before the end date.',
    code: 'invalid_date_range',
  ),
);
