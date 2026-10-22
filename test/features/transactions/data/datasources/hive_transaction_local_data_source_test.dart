import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveTransactionLocalDataSource dataSource;
  var boxCounter = 0;

  TransactionModel buildModel({
    String id = 'tx-1',
    double amount = 10,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id,
      amount: amount,
      type: TransactionType.expense,
      category: 'Coffee',
      description: 'Morning',
      date: date ?? DateTime.utc(2026, 10, 20, 12),
    );
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_tx_hive_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    boxCounter++;
    box = await Hive.openBox<dynamic>('transactions_$boxCounter');
    dataSource = HiveTransactionLocalDataSource(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  group('HiveTransactionLocalDataSource', () {
    test('returns an empty list for a new box', () async {
      expect(await dataSource.getTransactions(), isEmpty);
    });

    test('persists and reads a transaction', () async {
      final model = buildModel();

      await dataSource.saveTransaction(model);

      expect(await dataSource.getTransactions(), [model]);
    });

    test('sorts transactions newest first', () async {
      await dataSource.saveTransaction(
        buildModel(id: 'older', date: DateTime.utc(2026, 10, 1)),
      );
      await dataSource.saveTransaction(
        buildModel(id: 'newer', date: DateTime.utc(2026, 10, 20)),
      );

      final transactions = await dataSource.getTransactions();

      expect(transactions.map((t) => t.id), ['newer', 'older']);
    });

    test('replaces a record with the same id', () async {
      await dataSource.saveTransaction(buildModel());
      await dataSource.saveTransaction(buildModel(amount: 99));

      final transactions = await dataSource.getTransactions();

      expect(transactions, hasLength(1));
      expect(transactions.single.amount, 99);
    });

    test('deletes a transaction', () async {
      await dataSource.saveTransaction(buildModel());

      await dataSource.deleteTransaction('tx-1');

      expect(await dataSource.getTransactions(), isEmpty);
    });

    test('deleting a missing transaction is a no-op', () async {
      await dataSource.deleteTransaction('missing');

      expect(await dataSource.getTransactions(), isEmpty);
    });

    test('filters an inclusive date range', () async {
      await dataSource.saveTransaction(
        buildModel(id: 'before', date: DateTime.utc(2026, 9, 30, 23, 59)),
      );
      await dataSource.saveTransaction(
        buildModel(id: 'start', date: DateTime.utc(2026, 10, 1)),
      );
      await dataSource.saveTransaction(
        buildModel(id: 'middle', date: DateTime.utc(2026, 10, 15)),
      );
      await dataSource.saveTransaction(
        buildModel(id: 'end', date: DateTime.utc(2026, 10, 31, 23, 59)),
      );
      await dataSource.saveTransaction(
        buildModel(id: 'after', date: DateTime.utc(2026, 11, 1)),
      );

      final transactions = await dataSource.getTransactionsByDateRange(
        start: DateTime.utc(2026, 10, 1),
        end: DateTime.utc(2026, 10, 31, 23, 59),
      );

      expect(transactions.map((t) => t.id), ['end', 'middle', 'start']);
    });

    test('maps corrupted entries to CacheException', () async {
      await box.put('broken', 'not-a-map');

      await expectLater(
        dataSource.getTransactions(),
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
