import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fin_sight_ai/core/services/box_encryption.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late MockSecureStorage storage;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_boxes_');
    Hive.init(directory.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  setUp(() {
    storage = MockSecureStorage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  group('HiveEncryption', () {
    test('generates and stores a 32-byte base64 key on first use', () async {
      final cipher = await HiveEncryption(storage).cipher();

      expect(cipher, isNotNull);
      final captured =
          verify(
                () => storage.write(
                  key: HiveEncryption.storageKey,
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      expect(base64Decode(captured), hasLength(32));
    });

    test('reuses the stored key', () async {
      final key = base64Encode(List<int>.generate(32, (index) => index));
      when(() => storage.read(key: HiveEncryption.storageKey))
          .thenAnswer((_) async => key);

      final cipher = await HiveEncryption(storage).cipher();

      expect(cipher, isNotNull);
      verifyNever(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('falls back to plaintext when secure storage fails', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(StateError('secure storage unavailable'));

      expect(await HiveEncryption(storage).cipher(), isNull);
    });

    test('replaces a malformed key', () async {
      when(() => storage.read(key: HiveEncryption.storageKey))
          .thenAnswer((_) async => 'not-base64');

      final cipher = await HiveEncryption(storage).cipher();

      expect(cipher, isNotNull);
      verify(
        () => storage.write(
          key: HiveEncryption.storageKey,
          value: any(named: 'value'),
        ),
      ).called(1);
    });
  });

  group('EncryptedBoxOpener', () {
    HiveAesCipher cipherFor(int seed) {
      return HiveAesCipher(
        Uint8List.fromList(List<int>.generate(32, (index) => index + seed)),
      );
    }

    test('creates a new box with the cipher', () async {
      const opener = EncryptedBoxOpener();
      final box = await opener.open('fresh_box', cipherFor(1));

      await box.put('key', 'fresh-value');
      await box.close();

      final reopened = await opener.open('fresh_box', cipherFor(1));
      expect(reopened.get('key'), 'fresh-value');
      await reopened.close();
    });

    test('migrates an existing plaintext box', () async {
      const opener = EncryptedBoxOpener();
      final legacy = await Hive.openBox<dynamic>('legacy_box');
      await legacy.put('note', 'legacy-secret');
      await legacy.put('amount', 42);
      await legacy.close();

      final migrated = await opener.open(
        'legacy_box',
        cipherFor(2),
        allowLegacyMigration: true,
      );

      expect(migrated.get('note'), 'legacy-secret');
      expect(migrated.get('amount'), 42);
      await migrated.close();

      final file = File('${directory.path}/legacy_box.hive');
      final raw = latin1.decode(file.readAsBytesSync());
      expect(raw.contains('legacy-secret'), isFalse);
    });

    test('refuses plaintext fallback once migration is complete', () async {
      const opener = EncryptedBoxOpener();
      final legacy = await Hive.openBox<dynamic>('guarded_box');
      await legacy.put('note', 'kept-intact');
      await legacy.close();

      await expectLater(
        opener.open('guarded_box', cipherFor(5)),
        throwsA(anything),
      );

      await Hive.deleteBoxFromDisk('guarded_box');
    });

    test('a wrong key never overwrites encrypted data', () async {
      const opener = EncryptedBoxOpener();
      final box = await opener.open('wrong_key_box', cipherFor(6));
      await box.put('note', 'survives');
      await box.close();

      await expectLater(
        opener.open('wrong_key_box', cipherFor(7)),
        throwsA(anything),
      );

      final reopened = await opener.open('wrong_key_box', cipherFor(6));
      expect(reopened.get('note'), 'survives');
      await reopened.close();
    });

    test('reopening an encrypted box requires the key', () async {
      const opener = EncryptedBoxOpener();
      final box = await opener.open('locked_box', cipherFor(3));
      await box.put('note', 'encrypted-secret');
      await box.close();

      await expectLater(Hive.openBox<dynamic>('locked_box'), throwsA(anything));
      await Hive.deleteBoxFromDisk('locked_box');
    });

    test('creates an empty encrypted box when no legacy data exists', () async {
      const opener = EncryptedBoxOpener();
      final box = await opener.open('empty_box', cipherFor(4));

      expect(box.isEmpty, isTrue);
      await box.close();
    });
  });
}
