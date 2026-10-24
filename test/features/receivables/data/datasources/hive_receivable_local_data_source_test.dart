import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/receivables/data/datasources/hive_receivable_local_data_source.dart';
import 'package:fin_sight_ai/features/receivables/data/models/receivable_model.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveReceivableLocalDataSource dataSource;
  var boxCounter = 0;

  final dateLent = DateTime.utc(2026, 10, 1);
  final createdAt = DateTime.utc(2026, 10, 1, 9);

  ReceivableModel buildModel({
    String id = 'receivable-1',
    String debtor = 'Ana',
    double remaining = 600,
    DateTime? dueDate,
    ReceivableStatus status = ReceivableStatus.active,
    DateTime? updatedAt,
  }) {
    return ReceivableModel(
      id: id,
      debtorName: debtor,
      totalAmount: 1000,
      remainingAmount: remaining,
      dateLent: dateLent,
      dueDate: dueDate,
      notes: 'Lunch loan',
      status: status,
      paymentHistory: [
        ReceivablePayment(
          id: 'p-1',
          amount: 400,
          paidAt: DateTime.utc(2026, 10, 15),
          note: 'Cash',
        ),
      ],
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
    );
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'finsight_receivable_hive_',
    );
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    boxCounter++;
    box = await Hive.openBox<dynamic>('receivables_$boxCounter');
    dataSource = HiveReceivableLocalDataSource(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  group('HiveReceivableLocalDataSource', () {
    test('returns an empty list for a new box', () async {
      expect(await dataSource.getReceivables(), isEmpty);
    });

    test('persists and reads a receivable with payment history', () async {
      await dataSource.saveReceivable(buildModel());

      final receivables = await dataSource.getReceivables();

      expect(receivables, hasLength(1));
      expect(receivables.single.debtorName, 'Ana');
      expect(receivables.single.notes, 'Lunch loan');
      expect(receivables.single.paymentHistory, hasLength(1));
      expect(receivables.single.paymentHistory.single.amount, 400);
      expect(receivables.single.paymentHistory.single.note, 'Cash');
    });

    test('orders active receivables before paid entries', () async {
      await dataSource.saveReceivable(
        buildModel(id: 'paid', remaining: 0, status: ReceivableStatus.paid),
      );
      await dataSource.saveReceivable(
        buildModel(id: 'active', dueDate: DateTime.utc(2026, 12, 1)),
      );

      final receivables = await dataSource.getReceivables();

      expect(receivables.map((item) => item.id), ['active', 'paid']);
    });

    test('orders active receivables by due date then date lent', () async {
      await dataSource.saveReceivable(
        buildModel(id: 'later', dueDate: DateTime.utc(2027, 1, 1)),
      );
      await dataSource.saveReceivable(
        buildModel(id: 'sooner', dueDate: DateTime.utc(2026, 11, 1)),
      );
      await dataSource.saveReceivable(buildModel(id: 'no-due', dueDate: null));

      final receivables = await dataSource.getReceivables();

      expect(receivables.map((item) => item.id), ['no-due', 'sooner', 'later']);
    });

    test('replaces a record with the same id', () async {
      await dataSource.saveReceivable(buildModel());
      await dataSource.saveReceivable(buildModel(remaining: 0));

      final receivables = await dataSource.getReceivables();

      expect(receivables, hasLength(1));
      expect(receivables.single.remainingAmount, 0);
    });

    test('deletes a receivable', () async {
      await dataSource.saveReceivable(buildModel());

      await dataSource.deleteReceivable('receivable-1');

      expect(await dataSource.getReceivables(), isEmpty);
    });

    test('deleting a missing receivable is a no-op', () async {
      await dataSource.deleteReceivable('missing');

      expect(await dataSource.getReceivables(), isEmpty);
    });

    test('maps corrupted entries to CacheException', () async {
      await box.put('broken', 'not-a-map');

      await expectLater(
        dataSource.getReceivables(),
        throwsA(
          isA<CacheException>().having(
            (error) => error.code,
            'code',
            'cache_read_failed',
          ),
        ),
      );
    });
  });
}
