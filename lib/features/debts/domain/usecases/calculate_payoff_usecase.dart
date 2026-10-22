import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

/// Input for [CalculatePayoffUseCase].
class CalculatePayoffParams {
  const CalculatePayoffParams({required this.debt, this.monthlyPayment});

  final DebtEntity debt;

  /// Overrides the debt's minimum payment when provided.
  final double? monthlyPayment;
}

/// Projects when a debt will be fully paid.
@lazySingleton
class CalculatePayoffUseCase
    implements UseCase<DateTime?, CalculatePayoffParams> {
  const CalculatePayoffUseCase(this._repository);

  final DebtRepository _repository;

  @override
  Future<Result<DateTime?>> call(CalculatePayoffParams params) async {
    final monthlyPayment = params.monthlyPayment;
    if (monthlyPayment != null &&
        (!monthlyPayment.isFinite || monthlyPayment <= 0)) {
      return const Left(
        ValidationFailure(
          'Monthly payment must be greater than zero.',
          code: 'invalid_payment',
        ),
      );
    }

    return _repository.calculatePayoffDate(
      params.debt,
      monthlyPayment: monthlyPayment,
    );
  }
}
