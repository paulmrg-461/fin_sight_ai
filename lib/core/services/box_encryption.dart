import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Supplies the Hive AES key from platform secure storage.
///
/// The key lives outside the boxes so encrypted files are useless on their
/// own. When secure storage is unavailable the provider returns `null` and the
/// app falls back to unencrypted boxes instead of failing to start.
class HiveEncryption {
  HiveEncryption([this._secureStorage = const FlutterSecureStorage()]);

  static const String storageKey = 'hive_encryption_key';

  final FlutterSecureStorage _secureStorage;

  Future<HiveAesCipher?> cipher() async {
    try {
      final encoded = await _secureStorage.read(key: storageKey);
      final bytes = encoded == null ? null : _decode(encoded);
      if (bytes != null && bytes.length == 32) {
        return HiveAesCipher(bytes);
      }
      final generated = Uint8List.fromList(Hive.generateSecureKey());
      await _secureStorage.write(
        key: storageKey,
        value: base64Encode(generated),
      );
      return HiveAesCipher(generated);
    } catch (_) {
      return null;
    }
  }

  Uint8List? _decode(String encoded) {
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}

/// Opens Hive boxes with [cipher], migrating existing plaintext boxes once.
///
/// [allowLegacyMigration] must only be `true` for the first launch after the
/// encryption rollout. Afterwards a failed decryption is a hard error: falling
/// back to the plaintext reader could replace encrypted data with garbage.
class EncryptedBoxOpener {
  const EncryptedBoxOpener();

  Future<Box<dynamic>> open(
    String name,
    HiveAesCipher? cipher, {
    bool allowLegacyMigration = false,
  }) async {
    if (cipher == null) {
      return Hive.openBox<dynamic>(name);
    }

    try {
      return await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    } catch (error) {
      if (!allowLegacyMigration) {
        rethrow;
      }
      final legacy = await _openLegacy(name);
      if (legacy == null) {
        rethrow;
      }

      final values = Map<dynamic, dynamic>.from(legacy.toMap());
      await legacy.close();
      await Hive.deleteBoxFromDisk(name);

      final encrypted = await Hive.openBox<dynamic>(
        name,
        encryptionCipher: cipher,
      );
      if (values.isNotEmpty) {
        await encrypted.putAll(values);
      }
      return encrypted;
    }
  }

  Future<Box<dynamic>?> _openLegacy(String name) async {
    try {
      return await Hive.openBox<dynamic>(name);
    } catch (_) {
      return null;
    }
  }
}
