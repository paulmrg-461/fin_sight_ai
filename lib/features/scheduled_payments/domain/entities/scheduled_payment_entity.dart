import '../../../../core/domain/entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// How often a scheduled payment repeats.
enum PaymentFrequency { monthly, yearly }

/// A recurring expense or income created once and materialized as transactions.
class ScheduledPaymentEntity extends Entity {
  const ScheduledPaymentEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextDueDate,
    required this.dayOfMonth,
    required this.createdAt,
    this.type = TransactionType.expense,
    this.walletId,
    this.notes = '',
    this.isActive = true,
    this.updatedAt,
    this.lastPaidAt,
  });

  @override
  final String id;

  final String name;
  final double amount;

  /// Direction of the generated transaction.
  final TransactionType type;

  final String category;
  final PaymentFrequency frequency;

  /// Next charge date, normalized to midnight.
  final DateTime nextDueDate;

  /// Original day of the month, preserved so month-end schedules do not drift.
  final int dayOfMonth;

  final String? walletId;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastPaidAt;

  bool get isIncome => type == TransactionType.income;

  bool isDue(DateTime now) {
    if (!isActive) {
      return false;
    }
    return !_dateOnly(nextDueDate).isAfter(_dateOnly(now));
  }

  ScheduledPaymentEntity copyWith({
    String? id,
    String? name,
    double? amount,
    TransactionType? type,
    String? category,
    PaymentFrequency? frequency,
    DateTime? nextDueDate,
    int? dayOfMonth,
    String? walletId,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPaidAt,
  }) {
    return ScheduledPaymentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      walletId: walletId ?? this.walletId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledPaymentEntity &&
          other.id == id &&
          other.name == name &&
          other.amount == amount &&
          other.type == type &&
          other.category == category &&
          other.frequency == frequency &&
          other.nextDueDate == nextDueDate &&
          other.dayOfMonth == dayOfMonth &&
          other.walletId == walletId &&
          other.notes == notes &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.lastPaidAt == lastPaidAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    type,
    category,
    frequency,
    nextDueDate,
    dayOfMonth,
    walletId,
    notes,
    isActive,
    createdAt,
    updatedAt,
    lastPaidAt,
  );

  @override
  String toString() =>
      'ScheduledPaymentEntity($name, $amount, $frequency, next: $nextDueDate)';

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

/// Outcome of processing one or more scheduled payments.
class ScheduledPaymentRun {
  const ScheduledPaymentRun({this.created = const [], this.processed = 0});

  final List<TransactionEntity> created;

  /// Number of periods materialized, including catch-up periods.
  final int processed;

  int get createdCount => created.length;

  bool get hasCreated => created.isNotEmpty;
}
