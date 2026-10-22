import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_constants.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

/// Untrusted input for [AddDebtUseCase].
class AddDebtParams {
  const AddDebtParams({
    required this.creditorName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.minimumPayment,
    required this.dueDate,
    this.id,
  });

  final String creditorName;
  final double totalAmount;
  final double remainingAmount;
  final double interestRate;
  final double minimumPayment;
  final DateTime dueDate;
  final String? id;
}

/// Validates and records a new debt.
@lazySingleton
class AddDebtUseCase implements UseCase<DebtEntity, AddDebtParams> {
  AddDebtUseCase(this._repository, {this.uuid = const Uuid()});

  final DebtRepository _repository;
  final Uuid uuid;

  @override
  Future<Result<DebtEntity>> call(AddDebtParams params) async {
    final creditorName = params.creditorName.trim();
    if (creditorName.isEmpty) {
      return const Left(
        ValidationFailure(
          'Creditor name is required.',
          code: 'invalid_creditor',
        ),
      );
    }

    if (!params.totalAmount.isFinite || params.totalAmount <= 0) {
      return const Left(
        ValidationFailure(
          'Total amount must be greater than zero.',
          code: 'invalid_total',
        ),
      );
    }

    if (!params.remainingAmount.isFinite ||
        params.remainingAmount < 0 ||
        params.remainingAmount > params.totalAmount) {
      return const Left(
        ValidationFailure(
          'Remaining amount must be between zero and the total.',
          code: 'invalid_remaining',
        ),
      );
    }

    if (!params.interestRate.isFinite ||
        params.interestRate < 0 ||
        params.interestRate > AppConstants.maxInterestRate) {
      return const Left(
        ValidationFailure(
          'Interest rate must be between 0 and 100.',
          code: 'invalid_interest_rate',
        ),
      );
    }

    if (!params.minimumPayment.isFinite || params.minimumPayment <= 0) {
      return const Left(
        ValidationFailure(
          'Minimum payment must be greater than zero.',
          code: 'invalid_minimum_payment',
        ),
      );
    }

    final remainingAmount = double.parse(
      params.remainingAmount.toStringAsFixed(2),
    );

    final debt = DebtEntity(
      id: params.id?.trim().isNotEmpty == true ? params.id!.trim() : uuid.v4(),
      creditorName: creditorName,
      totalAmount: double.parse(params.totalAmount.toStringAsFixed(2)),
      remainingAmount: remainingAmount,
      interestRate: params.interestRate,
      minimumPayment: double.parse(params.minimumPayment.toStringAsFixed(2)),
      dueDate: params.dueDate,
      status: remainingAmount <= 0 ? DebtStatus.paid : DebtStatus.active,
    );

    return _repository.addDebt(debt);
  }
}
