/// Schedules local notifications for upcoming scheduled payments.
abstract interface class ReminderScheduler {
  Future<void> initialize();

  /// Replaces any reminder for [payment] with one for its next due date.
  Future<void> scheduleFor(ScheduledPaymentReminder payment);

  Future<void> cancelFor(String paymentId);

  Future<void> cancelAll();
}

/// Minimal reminder payload; keeps the scheduler free of domain models.
class ScheduledPaymentReminder {
  const ScheduledPaymentReminder({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.nextDueDate,
    required this.isActive,
  });

  final String id;
  final String name;
  final String category;
  final double amount;
  final DateTime nextDueDate;
  final bool isActive;
}
