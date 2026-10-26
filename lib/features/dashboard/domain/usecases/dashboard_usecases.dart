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

/// Loads every dashboard section from a single two-range aggregation.
@lazySingleton
class GetDashboardDataUseCase
    implements UseCase<DashboardData, DashboardRangeParams> {
  const GetDashboardDataUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Result<DashboardData>> call(DashboardRangeParams params) {
    if (params.start.isAfter(params.end)) {
      return Future.value(
        const Left(
          ValidationFailure(
            'The start date must be before the end date.',
            code: 'invalid_date_range',
          ),
        ),
      );
    }
    return _repository.getDashboardData(start: params.start, end: params.end);
  }
}
