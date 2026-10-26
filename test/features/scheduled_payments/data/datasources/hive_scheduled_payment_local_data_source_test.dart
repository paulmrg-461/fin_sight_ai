import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/datasources/hive_scheduled_payment_local_data_source.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/models/scheduled_payment_model.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveScheduledPaymentLocalDataSource dataSource;
  var counter = 0;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_scheduled_');
    Hive.init(directory.path);
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('scheduled_$counter');
    dataSource = HiveScheduledPaymentLocalDataSource(box);
  });

  tearDown(() async {
    if (box.isOpen) {
      await box.close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  ScheduledPaymentModel model({String id = 'pay-1', String name = 'Rent'}) {
    return ScheduledPaymentModel(
      id: id,
      name: name,
      amount: 800,
      category: 'Rent',
      frequency: PaymentFrequency.monthly,
      nextDueDate: DateTime(2026, 10, 23),
      dayOfMonth: 23,
      walletId: 'wallet-bank',
      notes: 'Monthly',
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 2),
      lastPaidAt: DateTime.utc(2026, 9, 23),
    );
  }

  test('round-trips payments through JSON', () async {
    await dataSource.savePayment(model());
    await dataSource.savePayment(
      model(
        id: 'pay-2',
        name: 'Netflix',
      ).copyWith(frequency: PaymentFrequency.yearly, isActive: false),
    );

    final payments = await dataSource.getPayments();

    expect(payments, hasLength(2));
    expect(payments.first.name, 'Rent');
    expect(payments.first.walletId, 'wallet-bank');
    expect(payments.last.frequency, PaymentFrequency.yearly);
    expect(payments.last.isActive, isFalse);
  });

  test('skips corrupted rows', () async {
    await box.put('bad', {'id': '', 'name': 10});
    await box.put('primitive', 42);
    await dataSource.savePayment(model());

    final payments = await dataSource.getPayments();

    expect(payments, hasLength(1));
    expect(payments.single.name, 'Rent');
  });

  test('deletes payments', () async {
    await dataSource.savePayment(model());

    await dataSource.deletePayment('pay-1');

    expect(await dataSource.getPayments(), isEmpty);
  });

  test('hides tombstones from reads and purges them on demand', () async {
    await dataSource.savePayment(
      model().copyWith(
        deletedAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      ),
    );

    expect(await dataSource.getPayments(), isEmpty);
    expect(await dataSource.getAllPayments(), hasLength(1));

    expect(await dataSource.purgeTombstones(DateTime.utc(2026, 10, 2)), 1);
    expect(await dataSource.getAllPayments(), isEmpty);
  });

  test('maps storage errors to CacheException', () async {
    await box.close();

    await expectLater(dataSource.getPayments(), throwsA(isA<CacheException>()));
    await expectLater(
      dataSource.savePayment(model()),
      throwsA(isA<CacheException>()),
    );
    await expectLater(
      dataSource.deletePayment('pay-1'),
      throwsA(isA<CacheException>()),
    );
  });
}
