import 'package:equatable/equatable.dart';

import '../../domain/entities/scheduled_payment_entity.dart';

sealed class ScheduledPaymentState extends Equatable {
  const ScheduledPaymentState();

  @override
  List<Object?> get props => const [];
}

final class ScheduledPaymentInitial extends ScheduledPaymentState {
  const ScheduledPaymentInitial();
}

final class ScheduledPaymentLoading extends ScheduledPaymentState {
  const ScheduledPaymentLoading();
}

final class ScheduledPaymentLoaded extends ScheduledPaymentState {
  const ScheduledPaymentLoaded(
    this.payments, {
    this.autoCreated = 0,
    this.error,
  });

  final List<ScheduledPaymentEntity> payments;

  /// Expenses auto-generated during the last load/action, shown as a banner.
  final int autoCreated;

  /// Non-fatal action error shown above the list.
  final String? error;

  @override
  List<Object?> get props => [payments, autoCreated, error];
}

final class ScheduledPaymentEmpty extends ScheduledPaymentState {
  const ScheduledPaymentEmpty({this.autoCreated = 0, this.error});

  final int autoCreated;
  final String? error;

  @override
  List<Object?> get props => [autoCreated, error];
}

final class ScheduledPaymentFailure extends ScheduledPaymentState {
  const ScheduledPaymentFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
