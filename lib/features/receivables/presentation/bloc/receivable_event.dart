import 'package:equatable/equatable.dart';

/// Base event for the receivables feature.
sealed class ReceivableEvent extends Equatable {
  const ReceivableEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads every receivable.
final class LoadReceivables extends ReceivableEvent {
  const LoadReceivables();
}

/// Adds money lent and reloads the list.
final class AddReceivable extends ReceivableEvent {
  const AddReceivable({
    required this.debtorName,
    required this.totalAmount,
    required this.dateLent,
    this.dueDate,
    this.notes,
  });

  final String debtorName;
  final double totalAmount;
  final DateTime dateLent;
  final DateTime? dueDate;
  final String? notes;

  @override
  List<Object?> get props => [
    debtorName,
    totalAmount,
    dateLent,
    dueDate,
    notes,
  ];
}

/// Records a received payment and reloads the list.
final class RecordReceivablePayment extends ReceivableEvent {
  const RecordReceivablePayment({
    required this.receivableId,
    required this.amount,
    this.note,
  });

  final String receivableId;
  final double amount;
  final String? note;

  @override
  List<Object?> get props => [receivableId, amount, note];
}

/// Deletes a receivable and reloads the list.
final class DeleteReceivable extends ReceivableEvent {
  const DeleteReceivable(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
