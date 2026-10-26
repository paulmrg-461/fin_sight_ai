import 'dart:io';

import 'package:fin_sight_ai/core/services/app_boxes.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/hive_insight_cache.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveInsightCache cache;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_insights_');
    Hive.init(directory.path);
  });

  setUp(() async {
    box = await Hive.openBox<dynamic>('ai_insights');
    final boxes = AppBoxes(
      transactions: box,
      debts: box,
      receivables: box,
      receipts: box,
      syncQueue: box,
      syncMeta: box,
      budgets: box,
      wallets: box,
      walletTransfers: box,
      settings: box,
      categories: box,
      scheduledPayments: box,
      aiInsights: box,
    );
    cache = HiveInsightCache(boxes);
  });

  tearDown(() async {
    if (box.isOpen) {
      await box.close();
      await Hive.deleteBoxFromDisk('ai_insights');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  FinancialInsightEntity insight({
    String id = 'i-1',
    String content = 'Save.',
  }) {
    return FinancialInsightEntity(
      id: id,
      type: InsightType.suggestion,
      content: content,
      timestamp: DateTime.utc(2026, 10, 26, 12),
    );
  }

  test('stores insights per language', () async {
    await cache.write('es', [insight()]);

    final spanish = await cache.read('es');
    expect(spanish?.single.content, 'Save.');
    expect(await cache.read('en'), isNull);
  });

  test('returns null for empty or corrupt entries', () async {
    expect(await cache.read('en'), isNull);

    await box.put('insights_en', {'insights': 'nope'});
    expect(await cache.read('en'), isNull);

    await box.put('insights_en', {
      'insights': [
        {'id': 'bad', 'type': 'unknown', 'content': 'x', 'timestamp': 'nope'},
      ],
    });
    expect(await cache.read('en'), isNull);
  });

  test('clears all cached languages', () async {
    await cache.write('en', [insight()]);
    await cache.write('es', [insight(id: 'i-2')]);

    await cache.clear();

    expect(await cache.read('en'), isNull);
    expect(await cache.read('es'), isNull);
  });
}
