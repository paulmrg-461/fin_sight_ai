import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/committed_cashflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  final end = DateTime(2026, 10, 31);

  CommittedPayment payment({
    String name = 'Rent',
    double amount = 800,
    CommittedSource source = CommittedSource.scheduledPayment,
  }) {
    return CommittedPayment(
      date: DateTime(2026, 10, 15),
      name: name,
      amount: amount,
      category: 'Rent',
      source: source,
    );
  }

  test('CommittedPayment uses value equality', () {
    expect(payment(), payment());
    expect(payment().hashCode, payment().hashCode);
    expect(payment(), isNot(payment(name: 'Phone')));
    expect(payment(), isNot(payment(source: CommittedSource.debtMinimum)));
    expect(payment().toString(), contains('Rent'));
  });

  test('CommittedCashflow totals, previews, and compares by value', () {
    final flow = CommittedCashflow(
      start: start,
      end: end,
      payments: [
        payment(),
        payment(name: 'Phone', amount: 50),
      ],
    );

    expect(flow.total, 850);
    expect(flow.isEmpty, isFalse);
    expect(flow.take(1).single.name, 'Rent');
    expect(flow.take(5), hasLength(2));
    expect(
      flow,
      CommittedCashflow(
        start: start,
        end: end,
        payments: [
          payment(),
          payment(name: 'Phone', amount: 50),
        ],
      ),
    );
    expect(flow.hashCode, isNonZero);
    expect(flow.toString(), contains('850.0'));
    expect(
      flow,
      isNot(CommittedCashflow(start: start, end: end, payments: const [])),
    );
    expect(flow, isNot(Object()));
  });

  test('an empty projection reports zero', () {
    final flow = CommittedCashflow(start: start, end: end, payments: const []);

    expect(flow.isEmpty, isTrue);
    expect(flow.total, 0);
    expect(flow.take(3), isEmpty);
  });
}
