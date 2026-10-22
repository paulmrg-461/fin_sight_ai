import 'package:fin_sight_ai/core/domain/entity.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dueDate = DateTime.utc(2026, 12, 1);
  final payment = PaymentRecord(
    id: 'p-1',
    amount: 100,
    paidAt: DateTime.utc(2026, 10, 1),
  );

  DebtEntity buildDebt({List<PaymentRecord>? history}) {
    return DebtEntity(
      id: 'debt-1',
      creditorName: 'Bank',
      totalAmount: 1000,
      remainingAmount: 600,
      interestRate: 12,
      minimumPayment: 100,
      dueDate: dueDate,
      paymentHistory: history ?? [payment],
    );
  }

  group('DebtEntity', () {
    test('is a domain Entity', () {
      expect(buildDebt(), isA<Entity>());
    });

    test('computes paid amount and progress', () {
      final debt = buildDebt();

      expect(debt.paidAmount, 400);
      expect(debt.progress, 0.4);
      expect(debt.isPaid, isFalse);
    });

    test('clamps progress for a settled debt', () {
      final debt = buildDebt().copyWith(
        remainingAmount: 0,
        status: DebtStatus.paid,
      );

      expect(debt.progress, 1);
      expect(debt.isPaid, isTrue);
      expect(debt.paidAmount, 1000);
    });

    test('returns full progress when total is zero', () {
      final debt = buildDebt().copyWith(totalAmount: 0, remainingAmount: 0);

      expect(debt.progress, 1);
    });

    test('copyWith replaces only provided fields', () {
      final original = buildDebt();

      final updated = original.copyWith(
        remainingAmount: 500,
        status: DebtStatus.active,
      );

      expect(updated.remainingAmount, 500);
      expect(updated.creditorName, original.creditorName);
      expect(original.remainingAmount, 600);
    });

    test('uses value equality including payment history', () {
      final first = buildDebt();
      final second = buildDebt();
      final different = buildDebt(history: []);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    test('PaymentRecord uses value equality', () {
      const amount = 100.0;
      final other = PaymentRecord(
        id: 'p-1',
        amount: amount,
        paidAt: DateTime.utc(2026, 10, 1),
      );

      expect(payment, other);
      expect(payment.hashCode, other.hashCode);
    });

    test('toString exposes the creditor and balances', () {
      final description = buildDebt().toString();

      expect(description, contains('Bank'));
      expect(description, contains('600'));
      expect(description, contains('1000'));
    });
  });
}
