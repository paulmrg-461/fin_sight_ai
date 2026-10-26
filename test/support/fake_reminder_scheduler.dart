import 'package:fin_sight_ai/core/services/reminder_scheduler.dart';

/// Records reminder scheduler calls for tests.
class FakeReminderScheduler implements ReminderScheduler {
  final List<ScheduledPaymentReminder> scheduled = [];
  final List<String> cancelled = [];
  int cancelAllCalls = 0;
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> scheduleFor(ScheduledPaymentReminder payment) async {
    scheduled.add(payment);
  }

  @override
  Future<void> cancelFor(String paymentId) async {
    cancelled.add(paymentId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }
}
