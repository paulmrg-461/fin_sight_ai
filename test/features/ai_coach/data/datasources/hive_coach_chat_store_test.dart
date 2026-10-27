import 'dart:io';

import 'package:fin_sight_ai/core/services/app_boxes.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/hive_coach_chat_store.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/coach_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveCoachChatStore store;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_chat_');
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
    store = HiveCoachChatStore(boxes);
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

  CoachMessage message({
    String id = 'm-1',
    CoachRole role = CoachRole.user,
    String content = 'How?',
    DateTime? at,
  }) {
    return CoachMessage(
      id: id,
      role: role,
      content: content,
      createdAt: at ?? DateTime.utc(2026, 10, 27, 12),
    );
  }

  test('appends and reads messages in order', () async {
    await store.append(message());
    await store.append(
      message(id: 'm-2', role: CoachRole.coach, content: 'Pay.'),
    );

    final messages = await store.read();

    expect(messages.map((item) => item.id), ['m-1', 'm-2']);
    expect(messages.last.content, 'Pay.');
  });

  test('caps stored messages at 100', () async {
    for (var index = 0; index < 105; index++) {
      await store.append(
        message(
          id: 'm-$index',
          at: DateTime.utc(2026, 10, 1).add(Duration(minutes: index)),
        ),
      );
    }

    final messages = await store.read();

    expect(messages, hasLength(HiveCoachChatStore.maxMessages));
    expect(messages.first.id, 'm-5');
    expect(messages.last.id, 'm-104');
  });

  test('skips corrupt rows and clears the conversation', () async {
    await box.put('chat_messages', [
      {'id': 'bad', 'role': 'unknown', 'content': 'x', 'createdAt': 'nope'},
      {
        'id': 'm-1',
        'role': 'user',
        'content': 'Hi',
        'createdAt': '2026-10-27T12:00:00.000Z',
      },
    ]);

    expect(await store.read(), hasLength(1));

    await store.clear();
    expect(await store.read(), isEmpty);
  });
}
