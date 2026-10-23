import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/services/receipt_image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  late Directory receiptsDirectory;
  late FileReceiptImageStore store;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_images_');
    receiptsDirectory = Directory(p.join(tempDirectory.path, 'receipts'));
    store = FileReceiptImageStore.withDirectory(receiptsDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('copies an image into persistent storage', () async {
    final source = File(p.join(tempDirectory.path, 'source.jpg'));
    await source.writeAsBytes([1, 2, 3, 4]);

    final persisted = await store.persist(source.path);

    expect(persisted, startsWith(receiptsDirectory.path));
    expect(p.basename(persisted), startsWith('receipt_'));
    expect(await File(persisted).readAsBytes(), [1, 2, 3, 4]);
    expect(await File(persisted).exists(), isTrue);
  });

  test('creates unique names for repeated scans', () async {
    final source = File(p.join(tempDirectory.path, 'source.jpg'));
    await source.writeAsBytes([1]);

    final first = await store.persist(source.path);
    final second = await store.persist(source.path);

    expect(first, isNot(second));
  });

  test('rejects a missing source image', () async {
    await expectLater(
      store.persist(p.join(tempDirectory.path, 'missing.jpg')),
      throwsA(
        isA<CacheException>().having(
          (e) => e.code,
          'code',
          'receipt_image_missing',
        ),
      ),
    );
  });

  test('deletes a persisted image', () async {
    final source = File(p.join(tempDirectory.path, 'source.jpg'));
    await source.writeAsBytes([1]);
    final persisted = await store.persist(source.path);

    await store.delete(persisted);

    expect(await File(persisted).exists(), isFalse);
  });

  test('deleting a missing image is a no-op', () async {
    await store.delete(p.join(tempDirectory.path, 'missing.jpg'));
  });
}
