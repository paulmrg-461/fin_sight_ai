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

  group('desktop storage', () {
    late Directory documents;
    late Directory support;

    setUp(() {
      documents = Directory(p.join(tempDirectory.path, 'documents'))
        ..createSync();
      support = Directory(p.join(tempDirectory.path, 'support'))..createSync();
    });

    FileReceiptImageStore desktopStore() => FileReceiptImageStore(
      supportDirectory: () async => support,
      documentsDirectory: () async => documents,
      isDesktopOverride: true,
    );

    test('migrates legacy receipt images once', () async {
      final legacyDir = Directory(p.join(documents.path, 'receipts'))
        ..createSync();
      File(p.join(legacyDir.path, 'receipt_old.jpg')).writeAsBytesSync([9]);
      File(p.join(legacyDir.path, 'keep.txt')).writeAsStringSync('user file');

      final source = File(p.join(tempDirectory.path, 'source.jpg'));
      await source.writeAsBytes([1, 2]);
      final persisted = await desktopStore().persist(source.path);

      expect(persisted, startsWith(p.join(support.path, 'receipts')));
      expect(
        File(p.join(support.path, 'receipts', 'receipt_old.jpg')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(support.path, 'receipts', 'keep.txt')).existsSync(),
        isFalse,
      );
    });

    test(
      'clears new and legacy receipts without touching other files',
      () async {
        final targetDir = Directory(p.join(support.path, 'receipts'))
          ..createSync();
        File(p.join(targetDir.path, 'receipt_new.jpg')).writeAsBytesSync([1]);
        final legacyDir = Directory(p.join(documents.path, 'receipts'))
          ..createSync();
        File(p.join(legacyDir.path, 'receipt_old.jpg')).writeAsBytesSync([2]);
        File(p.join(legacyDir.path, 'keep.txt')).writeAsStringSync('user file');

        await desktopStore().clear();

        expect(
          File(p.join(targetDir.path, 'receipt_new.jpg')).existsSync(),
          isFalse,
        );
        expect(
          File(p.join(legacyDir.path, 'receipt_old.jpg')).existsSync(),
          isFalse,
        );
        expect(File(p.join(legacyDir.path, 'keep.txt')).existsSync(), isTrue);
      },
    );
  });
}
