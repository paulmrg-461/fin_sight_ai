import 'package:fin_sight_ai/features/scheduled_payments/data/models/scheduled_payment_model.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> legacyJson({Object? type}) => {
    'id': 'pay-1',
    'name': 'Rent',
    'amount': 800.0,
    'category': 'Rent',
    'frequency': 'monthly',
    'nextDueDate': '2026-10-23T00:00:00.000',
    'dayOfMonth': 23,
    'walletId': 'wallet-bank',
    'notes': 'Monthly',
    'isActive': true,
    'createdAt': '2026-10-01T00:00:00.000Z',
    'type': ?type,
  };

  ScheduledPaymentModel model({
    TransactionType type = TransactionType.expense,
  }) => ScheduledPaymentModel(
    id: 'pay-2',
    name: 'Salary',
    amount: 3000,
    type: type,
    category: 'Salary',
    frequency: PaymentFrequency.monthly,
    nextDueDate: DateTime(2026, 10, 25),
    dayOfMonth: 25,
    walletId: 'wallet-bank',
    createdAt: DateTime.utc(2026, 10, 1),
  );

  test('round-trips sync metadata and tombstones', () {
    final deletedAt = DateTime.utc(2026, 10, 20);
    final source = model().copyWith(
      updatedAt: DateTime.utc(2026, 10, 19),
      isSynced: true,
      deletedAt: deletedAt,
    );

    final parsed = ScheduledPaymentModel.fromJson(source.toJson());

    expect(parsed.isSynced, isTrue);
    expect(parsed.deletedAt, deletedAt);
    expect(parsed.isDeleted, isTrue);
    expect(parsed.lastModified, DateTime.utc(2026, 10, 19));
  });

  test('reads legacy JSON without a type as expense', () {
    final parsed = ScheduledPaymentModel.fromJson(legacyJson());

    expect(parsed.type, TransactionType.expense);
    expect(parsed.isIncome, isFalse);
  });

  test('reads an unknown persisted type as expense', () {
    final parsed = ScheduledPaymentModel.fromJson(legacyJson(type: 'transfer'));

    expect(parsed.type, TransactionType.expense);
  });

  test('round-trips income schedules through JSON', () {
    final json = model(type: TransactionType.income).toJson();

    expect(json['type'], 'income');

    final parsed = ScheduledPaymentModel.fromJson(json);
    expect(parsed.type, TransactionType.income);
    expect(parsed.isIncome, isTrue);
    expect(parsed.name, 'Salary');
    expect(parsed.amount, 3000);
  });

  test('copies and converts to the domain entity with the type', () {
    final copied = model().copyWith(type: TransactionType.income);

    expect(copied.type, TransactionType.income);
    expect(copied.toEntity().type, TransactionType.income);
    expect(
      ScheduledPaymentModel.fromEntity(copied).type,
      TransactionType.income,
    );
  });
}
