import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_entity.dart';

/// Base event for the transactions feature.
sealed class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads every transaction and clears any active date filter.
final class LoadTransactions extends TransactionEvent {
  const LoadTransactions();
}

/// Adds a new transaction and reloads the current view.
final class AddTransaction extends TransactionEvent {
  const AddTransaction({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImagePath,
    this.walletId,
    this.id,
  });

  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final String? receiptImagePath;
  final String? walletId;

  /// Optional explicit id, used to restore an undone deletion.
  final String? id;

  @override
  List<Object?> get props => [
    amount,
    type,
    category,
    description,
    date,
    receiptImagePath,
    walletId,
    id,
  ];
}

/// Updates an existing transaction and reloads the current view.
final class UpdateTransaction extends TransactionEvent {
  const UpdateTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImagePath,
    this.walletId,
  });

  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final String? receiptImagePath;
  final String? walletId;

  @override
  List<Object?> get props => [
    id,
    amount,
    type,
    category,
    description,
    date,
    receiptImagePath,
    walletId,
  ];
}

/// Deletes a transaction and reloads the current view.
final class DeleteTransaction extends TransactionEvent {
  const DeleteTransaction(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Filters the list by an inclusive date range.
final class FilterByDateRange extends TransactionEvent {
  const FilterByDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}
