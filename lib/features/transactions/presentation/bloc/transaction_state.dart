import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_entity.dart';

/// Base state for the transactions feature.
sealed class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => const [];
}

/// No load has been requested yet.
final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

/// A request is in flight.
final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

/// Transactions are available.
final class TransactionLoaded extends TransactionState {
  const TransactionLoaded({
    required this.transactions,
    this.start,
    this.end,
    this.query = '',
  });

  final List<TransactionEntity> transactions;

  /// Active free-text filter.
  final String query;

  /// Active inclusive range, or `null` when showing all transactions.
  final DateTime? start;
  final DateTime? end;

  bool get hasDateFilter => start != null && end != null;

  bool get hasQuery => query.trim().isNotEmpty;

  @override
  List<Object?> get props => [transactions, start, end, query];
}

/// The query succeeded but there is nothing to show.
final class TransactionEmpty extends TransactionState {
  const TransactionEmpty({this.start, this.end, this.query = ''});

  final DateTime? start;
  final DateTime? end;

  /// Active free-text filter.
  final String query;

  bool get hasDateFilter => start != null && end != null;

  bool get hasQuery => query.trim().isNotEmpty;

  @override
  List<Object?> get props => [start, end, query];
}

/// The query failed with a safe, user-presentable message.
final class TransactionFailure extends TransactionState {
  const TransactionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
