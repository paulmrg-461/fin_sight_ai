import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

/// Input for [MakePaymentUseCase].
class MakePaymentParams {
  const MakePaymentParams({required this.debtId, required this.amount});

  final String debtId;
  final double amount;
}

/// Applies a payment, updates the balance, and records the payment history.
@lazySingleton
class MakePaymentUseCase implements UseCase<DebtEntity, MakePaymentParams> {
  MakePaymentUseCase(
    this._repository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  final DebtRepository _repository;
  final Uuid uuid;
  final Clock clock;

  @override
  Future<Result<DebtEntity>> call(MakePaymentParams params) async {
    if (!params.amount.isFinite || params.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Payment amount must be greater than zero.',
          code: 'invalid_payment',
        ),
      );
    }

    final debtsResult = await _repository.getDebts();
    final failure = debtsResult.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    final debts = debtsResult.getOrElse((_) => const <DebtEntity>[]);
    DebtEntity? selected;
    for (final debt in debts) {
      if (debt.id == params.debtId) {
        selected = debt;
        break;
      }
    }

    if (selected == null) {
      return const Left(
        ValidationFailure('Debt not found.', code: 'debt_not_found'),
      );
    }
    if (selected.isPaid) {
      return const Left(
        ValidationFailure(
          'This debt is already paid off.',
          code: 'debt_already_paid',
        ),
      );
    }

    final applied = params.amount > selected.remainingAmount
        ? selected.remainingAmount
        : params.amount;
    final newRemaining = (selected.remainingAmount - applied)
        .clamp(0, selected.totalAmount)
        .toDouble();

    final updated = selected.copyWith(
      remainingAmount: newRemaining <= 0.004 ? 0 : newRemaining,
      status: newRemaining <= 0.004 ? DebtStatus.paid : DebtStatus.active,
      paymentHistory: [
        ...selected.paymentHistory,
        PaymentRecord(
          id: uuid.v4(),
          amount: double.parse(applied.toStringAsFixed(2)),
          paidAt: clock.now(),
        ),
      ],
    );

    return _repository.updateDebt(updated);
  }
}
