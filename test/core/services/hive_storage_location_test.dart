import 'dart:io';

import 'package:fin_sight_ai/core/services/hive_storage_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory documents;
  late Directory support;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('finsight_storage_');
    documents = Directory(p.join(root.path, 'documents'))..createSync();
    support = Directory(p.join(root.path, 'support'))..createSync();
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  HiveStorageLocation build({bool desktop = true}) {
    return HiveStorageLocation(
      supportDirectory: () async => support,
      documentsDirectory: () async => documents,
      isDesktopOverride: desktop,
    );
  }

  test('desktop resolves the application support directory', () async {
    final resolved = await build().resolve();

    expect(resolved.path, support.path);
  });

  test('copies legacy boxes without deleting the originals', () async {
    File(p.join(documents.path, 'transactions.hive'))
        .writeAsStringSync('legacy-data');
    File(p.join(documents.path, 'transactions.lock')).writeAsStringSync('lock');
    File(p.join(documents.path, 'notes.txt')).writeAsStringSync('ignore me');

    final resolved = await build().resolve();

    expect(resolved.path, support.path);
    expect(
      File(p.join(support.path, 'transactions.hive')).readAsStringSync(),
      'legacy-data',
    );
    expect(
      File(p.join(support.path, 'transactions.lock')).existsSync(),
      isFalse,
    );
    expect(File(p.join(support.path, 'notes.txt')).existsSync(), isFalse);
    expect(
      File(p.join(documents.path, 'transactions.hive')).existsSync(),
      isTrue,
    );
  });

  test('never overwrites boxes already present in support', () async {
    File(p.join(documents.path, 'transactions.hive'))
        .writeAsStringSync('legacy-data');
    File(p.join(support.path, 'transactions.hive'))
        .writeAsStringSync('current-data');

    final resolved = await build().resolve();

    expect(resolved.path, support.path);
    expect(
      File(p.join(support.path, 'transactions.hive')).readAsStringSync(),
      'current-data',
    );
  });

  test('mobile keeps using the documents directory', () async {
    final resolved = await build(desktop: false).resolve();

    expect(resolved.path, documents.path);
    expect(
      File(p.join(support.path, 'transactions.hive')).existsSync(),
      isFalse,
    );
  });

  test('falls back to documents when support cannot be resolved', () async {
    final location = HiveStorageLocation(
      supportDirectory: () async => throw StateError('no xdg'),
      documentsDirectory: () async => documents,
    );

    final resolved = await location.resolve();

    expect(resolved.path, documents.path);
  });

  test('returns support even when there is nothing to migrate', () async {
    final resolved = await build().resolve();

    expect(resolved.path, support.path);
  });
}
