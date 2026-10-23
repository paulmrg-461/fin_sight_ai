import '../models/scheduled_payment_model.dart';

/// Local persistence contract for scheduled payments.
abstract interface class ScheduledPaymentLocalDataSource {
  Future<List<ScheduledPaymentModel>> getPayments();

  Future<void> savePayment(ScheduledPaymentModel payment);

  Future<void> deletePayment(String id);
}
