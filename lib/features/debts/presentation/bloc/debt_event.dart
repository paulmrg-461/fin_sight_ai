import 'package:equatable/equatable.dart';

/// Base event for the debts feature.
sealed class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads every debt.
final class LoadDebts extends DebtEvent {
  const LoadDebts();
}

/// Adds a debt and reloads the list.
final class AddDebt extends DebtEvent {
  const AddDebt({
    required this.creditorName,
    required this.totalAmount,
    required this.interestRate,
    required this.minimumPayment,
    required this.dueDate,
    this.remainingAmount,
  });

  final String creditorName;
  final double totalAmount;
  final double interestRate;
  final double minimumPayment;
  final DateTime dueDate;
  final double? remainingAmount;

  @override
  List<Object?> get props => [
    creditorName,
    totalAmount,
    interestRate,
    minimumPayment,
    dueDate,
    remainingAmount,
  ];
}

/// Applies a payment and reloads the list.
final class MakePayment extends DebtEvent {
  const MakePayment({required this.debtId, required this.amount});

  final String debtId;
  final double amount;

  @override
  List<Object?> get props => [debtId, amount];
}

/// Deletes a debt and reloads the list.
final class DeleteDebt extends DebtEvent {
  const DeleteDebt(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Projects the payoff date for a debt.
final class CalculatePayoff extends DebtEvent {
  const CalculatePayoff({required this.debtId, required this.monthlyPayment});

  final String debtId;
  final double monthlyPayment;

  @override
  List<Object?> get props => [debtId, monthlyPayment];
}
