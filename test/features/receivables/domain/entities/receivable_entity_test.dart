import 'package:fin_sight_ai/core/domain/entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dateLent = DateTime.utc(2026, 10, 1);
  final createdAt = DateTime.utc(2026, 10, 1, 9);
  final updatedAt = DateTime.utc(2026, 10, 2, 9);
  final payment = ReceivablePayment(
    id: 'p-1',
    amount: 400,
    paidAt: DateTime.utc(2026, 10, 15),
    note: 'Cash',
  );

  ReceivableEntity buildReceivable({
    List<ReceivablePayment>? history,
    double remaining = 600,
    ReceivableStatus status = ReceivableStatus.active,
  }) {
    return ReceivableEntity(
      id: 'receivable-1',
      debtorName: 'Ana',
      totalAmount: 1000,
      remainingAmount: remaining,
      dateLent: dateLent,
      dueDate: DateTime.utc(2026, 12, 1),
      notes: 'Lunch loan',
      status: status,
      paymentHistory: history ?? [payment],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  group('ReceivableEntity', () {
    test('is a domain Entity', () {
      expect(buildReceivable(), isA<Entity>());
    });

    test('computes paid amount and progress', () {
      final receivable = buildReceivable();

      expect(receivable.paidAmount, 400);
      expect(receivable.progress, 0.4);
      expect(receivable.isPaid, isFalse);
    });

    test('clamps progress for a settled receivable', () {
      final receivable = buildReceivable(
        remaining: 0,
        status: ReceivableStatus.paid,
      );

      expect(receivable.progress, 1);
      expect(receivable.isPaid, isTrue);
      expect(receivable.paidAmount, 1000);
    });

    test('treats a zero remaining amount as paid', () {
      final receivable = buildReceivable(remaining: 0);

      expect(receivable.isPaid, isTrue);
    });

    test('returns full progress when the total is zero', () {
      final receivable = buildReceivable(remaining: 0).copyWith(totalAmount: 0);

      expect(receivable.progress, 1);
    });

    test('copyWith replaces only provided fields', () {
      final original = buildReceivable();

      final updated = original.copyWith(remainingAmount: 500, notes: 'Updated');

      expect(updated.remainingAmount, 500);
      expect(updated.notes, 'Updated');
      expect(updated.debtorName, original.debtorName);
      expect(original.remainingAmount, 600);
    });

    test('uses value equality including payment history', () {
      final first = buildReceivable();
      final second = buildReceivable();
      final different = buildReceivable(history: const []);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    test('toString exposes the debtor and balances', () {
      final description = buildReceivable().toString();

      expect(description, contains('Ana'));
      expect(description, contains('600'));
      expect(description, contains('1000'));
    });
  });

  group('ReceivablePayment', () {
    test('uses value equality including the optional note', () {
      final same = ReceivablePayment(
        id: 'p-1',
        amount: 400,
        paidAt: DateTime.utc(2026, 10, 15),
        note: 'Cash',
      );
      final withoutNote = ReceivablePayment(
        id: 'p-1',
        amount: 400,
        paidAt: DateTime.utc(2026, 10, 15),
      );

      expect(payment, same);
      expect(payment.hashCode, same.hashCode);
      expect(payment, isNot(withoutNote));
    });

    test('copyWith replaces selected fields', () {
      final updated = payment.copyWith(amount: 300, note: 'Transfer');

      expect(updated.amount, 300);
      expect(updated.note, 'Transfer');
      expect(updated.id, payment.id);
      expect(updated.paidAt, payment.paidAt);
    });

    test('toString exposes the amount and date', () {
      expect(payment.toString(), contains('400'));
      expect(payment.toString(), contains('2026-10-15'));
    });
  });
}
