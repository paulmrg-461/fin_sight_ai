import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_session.dart';
import '../models/auth_session_model.dart';
import 'session_storage.dart';

/// Stores the session in the platform secure storage (Keychain/Keystore).
@LazySingleton(as: SessionStorage)
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage() : _storage = const FlutterSecureStorage();

  /// Test seam: inject a fake secure storage implementation.
  SecureSessionStorage.withStorage(this._storage);

  static const String _key = 'finsight.auth.session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid stored session.');
    }
    return AuthSessionModel.fromJson(Map<String, dynamic>.from(decoded))
        .toEntity();
  }

  @override
  Future<void> write(AuthSession session) {
    return _storage.write(
      key: _key,
      value: jsonEncode(AuthSessionModel.fromEntity(session).toJson()),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
