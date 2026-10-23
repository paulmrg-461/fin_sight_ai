import 'package:equatable/equatable.dart';

import '../../domain/usecases/scheduled_payment_usecases.dart';

sealed class ScheduledPaymentEvent extends Equatable {
  const ScheduledPaymentEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadScheduledPayments extends ScheduledPaymentEvent {
  const LoadScheduledPayments({this.previousAutoCreated = 0});

  /// Expenses created before the app blocs were built (startup processing).
  final int previousAutoCreated;

  @override
  List<Object?> get props => [previousAutoCreated];
}

final class AddScheduledPayment extends ScheduledPaymentEvent {
  const AddScheduledPayment(this.params);

  final AddScheduledPaymentParams params;

  @override
  List<Object?> get props => [params];
}

final class SetScheduledPaymentActive extends ScheduledPaymentEvent {
  const SetScheduledPaymentActive({required this.id, required this.isActive});

  final String id;
  final bool isActive;

  @override
  List<Object?> get props => [id, isActive];
}

final class DeleteScheduledPayment extends ScheduledPaymentEvent {
  const DeleteScheduledPayment(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class PayScheduledPayment extends ScheduledPaymentEvent {
  const PayScheduledPayment(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ProcessDuePayments extends ScheduledPaymentEvent {
  const ProcessDuePayments();
}
