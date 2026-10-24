import 'package:equatable/equatable.dart';

import '../../domain/entities/receivable_entity.dart';

/// Base state for the receivables feature.
sealed class ReceivableState extends Equatable {
  const ReceivableState();

  @override
  List<Object?> get props => const [];
}

final class ReceivableInitial extends ReceivableState {
  const ReceivableInitial();
}

final class ReceivableLoading extends ReceivableState {
  const ReceivableLoading();
}

final class ReceivableLoaded extends ReceivableState {
  const ReceivableLoaded({required this.receivables});

  final List<ReceivableEntity> receivables;

  double get totalOutstanding => receivables
      .where((receivable) => !receivable.isPaid)
      .fold<double>(0, (sum, receivable) => sum + receivable.remainingAmount);

  int get activeCount =>
      receivables.where((receivable) => !receivable.isPaid).length;

  @override
  List<Object?> get props => [receivables];
}

final class ReceivableEmpty extends ReceivableState {
  const ReceivableEmpty();
}

final class ReceivableFailure extends ReceivableState {
  const ReceivableFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
