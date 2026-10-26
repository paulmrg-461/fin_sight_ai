import '../models/scheduled_payment_model.dart';

/// Local persistence contract for scheduled payments.
abstract interface class ScheduledPaymentLocalDataSource {
  /// Visible schedules, excluding tombstones.
  Future<List<ScheduledPaymentModel>> getPayments();

  /// Every stored schedule, including tombstones, for sync merges.
  Future<List<ScheduledPaymentModel>> getAllPayments();

  Future<void> savePayment(ScheduledPaymentModel payment);

  Future<void> deletePayment(String id);

  /// Removes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
