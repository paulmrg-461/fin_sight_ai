import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/hive_debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/models/debt_model.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveDebtLocalDataSource dataSource;
  var boxCounter = 0;

  DebtModel buildModel({
    String id = 'debt-1',
    double remaining = 600,
    DateTime? dueDate,
  }) {
    return DebtModel(
      id: id,
      creditorName: 'Bank',
      totalAmount: 1000,
      remainingAmount: remaining,
      interestRate: 12,
      minimumPayment: 100,
      dueDate: dueDate ?? DateTime.utc(2026, 12, 1),
    );
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'finsight_debt_hive_',
    );
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    boxCounter++;
    box = await Hive.openBox<dynamic>('debts_$boxCounter');
    dataSource = HiveDebtLocalDataSource(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  group('HiveDebtLocalDataSource', () {
    test('returns an empty list for a new box', () async {
      expect(await dataSource.getDebts(), isEmpty);
    });

    test('persists and reads a debt with payment history', () async {
      final model = DebtModel(
        id: 'debt-1',
        creditorName: 'Bank',
        totalAmount: 1000,
        remainingAmount: 600,
        interestRate: 12,
        minimumPayment: 100,
        dueDate: DateTime.utc(2026, 12, 1),
        paymentHistory: [
          PaymentRecord(
            id: 'p-1',
            amount: 100,
            paidAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      );

      await dataSource.saveDebt(model);

      final debts = await dataSource.getDebts();
      expect(debts, hasLength(1));
      expect(debts.single.paymentHistory, hasLength(1));
      expect(debts.single.paymentHistory.single.amount, 100);
    });

    test('sorts debts by due date ascending', () async {
      await dataSource.saveDebt(
        buildModel(id: 'later', dueDate: DateTime.utc(2027, 1, 1)),
      );
      await dataSource.saveDebt(
        buildModel(id: 'sooner', dueDate: DateTime.utc(2026, 11, 1)),
      );

      final debts = await dataSource.getDebts();

      expect(debts.map((d) => d.id), ['sooner', 'later']);
    });

    test('replaces a record with the same id', () async {
      await dataSource.saveDebt(buildModel());
      await dataSource.saveDebt(buildModel(remaining: 0));

      final debts = await dataSource.getDebts();

      expect(debts, hasLength(1));
      expect(debts.single.remainingAmount, 0);
    });

    test('deletes a debt', () async {
      await dataSource.saveDebt(buildModel());

      await dataSource.deleteDebt('debt-1');

      expect(await dataSource.getDebts(), isEmpty);
    });

    test('deleting a missing debt is a no-op', () async {
      await dataSource.deleteDebt('missing');

      expect(await dataSource.getDebts(), isEmpty);
    });

    test('maps corrupted entries to CacheException', () async {
      await box.put('broken', 'not-a-map');

      await expectLater(
        dataSource.getDebts(),
        throwsA(
          isA<CacheException>().having(
            (e) => e.code,
            'code',
            'cache_read_failed',
          ),
        ),
      );
    });
  });
}
