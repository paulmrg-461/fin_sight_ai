import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Inclusive date range for transaction queries.
class DateRangeParams {
  const DateRangeParams({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// Returns transactions inside an inclusive date range.
@lazySingleton
class GetTransactionsByDateRangeUseCase
    implements UseCase<List<TransactionEntity>, DateRangeParams> {
  const GetTransactionsByDateRangeUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<List<TransactionEntity>>> call(DateRangeParams params) async {
    if (params.start.isAfter(params.end)) {
      return const Left(
        ValidationFailure(
          'The start date must be before the end date.',
          code: 'invalid_date_range',
        ),
      );
    }

    return _repository.getTransactionsByDateRange(
      start: params.start,
      end: params.end,
    );
  }
}
