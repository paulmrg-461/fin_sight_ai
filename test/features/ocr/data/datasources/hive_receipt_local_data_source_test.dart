import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/hive_receipt_local_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/models/receipt_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveReceiptLocalDataSource dataSource;
  var boxCounter = 0;

  ReceiptModel buildModel({
    String id = 'receipt-1',
    DateTime? date,
    double total = 11.5,
  }) {
    return ReceiptModel(
      id: id,
      imagePath: '/tmp/r.jpg',
      merchantName: 'Shop',
      date: date ?? DateTime.utc(2026, 10, 22),
      totalAmount: total,
      items: const [],
      currency: 'USD',
    );
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_ocr_hive_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    boxCounter++;
    box = await Hive.openBox<dynamic>('receipts_$boxCounter');
    dataSource = HiveReceiptLocalDataSource(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  group('HiveReceiptLocalDataSource', () {
    test('returns an empty list for a new box', () async {
      expect(await dataSource.getReceipts(), isEmpty);
    });

    test('persists and reads a receipt', () async {
      final model = buildModel();

      await dataSource.saveReceipt(model);

      expect(await dataSource.getReceipts(), [model]);
    });

    test('sorts receipts newest first', () async {
      await dataSource.saveReceipt(
        buildModel(id: 'older', date: DateTime.utc(2026, 9, 1)),
      );
      await dataSource.saveReceipt(
        buildModel(id: 'newer', date: DateTime.utc(2026, 10, 1)),
      );

      final receipts = await dataSource.getReceipts();

      expect(receipts.map((r) => r.id), ['newer', 'older']);
    });

    test('replaces a record with the same id', () async {
      await dataSource.saveReceipt(buildModel());
      await dataSource.saveReceipt(buildModel(total: 99));

      final receipts = await dataSource.getReceipts();

      expect(receipts, hasLength(1));
      expect(receipts.single.totalAmount, 99);
    });

    test('maps corrupted entries to CacheException', () async {
      await box.put('broken', 'not-a-map');

      await expectLater(
        dataSource.getReceipts(),
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
