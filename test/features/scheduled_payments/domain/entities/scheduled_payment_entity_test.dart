import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 1);
  final due = DateTime(2026, 10, 23);

  ScheduledPaymentEntity payment({
    bool active = true,
    DateTime? nextDueDate,
    double amount = 800,
    TransactionType type = TransactionType.expense,
  }) {
    return ScheduledPaymentEntity(
      id: 'pay-1',
      name: 'Rent',
      amount: amount,
      type: type,
      category: 'Rent',
      frequency: PaymentFrequency.monthly,
      nextDueDate: nextDueDate ?? due,
      dayOfMonth: 23,
      walletId: 'wallet-bank',
      notes: 'Monthly',
      isActive: active,
      createdAt: createdAt,
    );
  }

  test('is due on or after the due date while active', () {
    expect(payment().isDue(DateTime(2026, 10, 23, 8)), isTrue);
    expect(payment().isDue(DateTime(2026, 10, 22, 23)), isFalse);
    expect(payment().isDue(DateTime(2026, 11, 1)), isTrue);
  });

  test('paused payments are never due', () {
    expect(payment(active: false).isDue(DateTime(2026, 11, 1)), isFalse);
  });

  test('defaults to expense with isIncome false', () {
    expect(payment().type, TransactionType.expense);
    expect(payment().isIncome, isFalse);
  });

  test('reports income schedules', () {
    expect(payment(type: TransactionType.income).isIncome, isTrue);
  });

  test('compares by value', () {
    expect(payment(), payment());
    expect(payment(amount: 900), isNot(payment()));
    expect(payment(active: false), isNot(payment()));
    expect(payment(type: TransactionType.income), isNot(payment()));
  });

  test('hashes equal instances consistently', () {
    expect(payment().hashCode, payment().hashCode);
  });

  test('copies with overrides', () {
    final updated = payment().copyWith(
      type: TransactionType.income,
      nextDueDate: DateTime(2026, 11, 23),
      isActive: false,
      lastPaidAt: DateTime(2026, 10, 24),
    );

    expect(updated.id, 'pay-1');
    expect(updated.type, TransactionType.income);
    expect(updated.isIncome, isTrue);
    expect(updated.nextDueDate, DateTime(2026, 11, 23));
    expect(updated.isActive, isFalse);
    expect(updated.lastPaidAt, DateTime(2026, 10, 24));
    expect(updated.createdAt, createdAt);
  });

  test('run reports created counts', () {
    const empty = ScheduledPaymentRun();
    expect(empty.hasCreated, isFalse);
    expect(empty.createdCount, 0);

    final run = ScheduledPaymentRun(created: const [], processed: 2);
    expect(run.processed, 2);
  });

  test('renders a readable string', () {
    expect(payment().toString(), contains('Rent'));
  });
}
