import '../../../../core/usecase/usecase.dart';
import '../entities/scheduled_payment_entity.dart';

/// Domain contract for recurring payments and their generated expenses.
abstract interface class ScheduledPaymentRepository {
  /// Every schedule ordered by next due date.
  ResultFuture<List<ScheduledPaymentEntity>> getPayments();

  /// Persists a new schedule.
  ResultFuture<ScheduledPaymentEntity> addPayment(
    ScheduledPaymentEntity payment,
  );

  /// Pauses or resumes the schedule with [id].
  ResultFuture<ScheduledPaymentEntity> setActive(String id, bool isActive);

  /// Removes the schedule. Generated expenses are preserved.
  ResultFuture<void> deletePayment(String id);

  /// Materializes every due period up to [now] and advances the schedules.
  ResultFuture<ScheduledPaymentRun> processDue(DateTime now);

  /// Records one expense now and advances the schedule past [now].
  ResultFuture<ScheduledPaymentRun> payNow(String id, DateTime now);
}
