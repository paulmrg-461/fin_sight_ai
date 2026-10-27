import 'package:equatable/equatable.dart';

import '../../domain/entities/debt_entity.dart';
import '../../domain/services/debt_payment_plan.dart';

/// Projected payoff for a specific debt.
class PayoffEstimate extends Equatable {
  const PayoffEstimate({
    required this.debtId,
    required this.monthlyPayment,
    required this.expectedDate,
    this.plan,
    this.interestSaved = 0,
    this.monthsSaved = 0,
  });

  final String debtId;
  final double monthlyPayment;

  /// `null` when the payment does not cover the interest.
  final DateTime? expectedDate;

  /// Full amortization schedule for [monthlyPayment], when available.
  final DebtPaymentPlan? plan;

  /// Interest avoided versus paying only the minimum.
  final double interestSaved;

  /// Months avoided versus paying only the minimum.
  final int monthsSaved;

  @override
  List<Object?> get props => [
    debtId,
    monthlyPayment,
    expectedDate,
    plan,
    interestSaved,
    monthsSaved,
  ];
}

/// Base state for the debts feature.
sealed class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => const [];
}

final class DebtInitial extends DebtState {
  const DebtInitial();
}

final class DebtLoading extends DebtState {
  const DebtLoading();
}

final class DebtLoaded extends DebtState {
  const DebtLoaded({required this.debts, this.payoff});

  final List<DebtEntity> debts;
  final PayoffEstimate? payoff;

  @override
  List<Object?> get props => [debts, payoff];
}

final class DebtEmpty extends DebtState {
  const DebtEmpty();
}

final class DebtFailure extends DebtState {
  const DebtFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
