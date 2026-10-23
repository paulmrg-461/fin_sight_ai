import 'dart:convert';

import 'package:fin_sight_ai/features/auth/data/models/auth_session_model.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final expiresAt = DateTime.utc(2030, 1, 1, 12);

  AuthSessionModel buildModel() {
    return AuthSessionModel(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: 'user-1',
      email: 'user@example.com',
      expiresAt: expiresAt,
    );
  }

  group('AuthSessionModel', () {
    test('maps from and to an entity', () {
      final entity = AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: 'user-1',
        email: 'user@example.com',
        expiresAt: expiresAt,
      );

      final model = AuthSessionModel.fromEntity(entity);

      expect(model.accessToken, entity.accessToken);
      expect(model.toEntity(), entity);
    });

    test('round-trips through JSON', () {
      final model = buildModel();

      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = AuthSessionModel.fromJson(
        decoded as Map<String, dynamic>,
      );

      expect(restored.toEntity(), model.toEntity());
      expect(restored.expiresAt, expiresAt);
    });

    test('rejects invalid fields', () {
      final valid = buildModel().toJson();

      for (final key in [
        'accessToken',
        'refreshToken',
        'userId',
        'expiresAt',
      ]) {
        final json = Map<String, dynamic>.from(valid)..[key] = '';
        expect(
          () => AuthSessionModel.fromJson(json),
          throwsFormatException,
          reason: key,
        );
      }
      final invalidEmail = Map<String, dynamic>.from(buildModel().toJson())
        ..['email'] = 1;
      expect(
        () => AuthSessionModel.fromJson(invalidEmail),
        throwsFormatException,
      );
    });

    test('reports expiry from the session', () {
      expect(buildModel().isExpired, isFalse);
      expect(buildModel().copyWithExpiry(DateTime.utc(2020)).isExpired, isTrue);
    });
  });
}

extension on AuthSessionModel {
  AuthSessionModel copyWithExpiry(DateTime expiry) {
    return AuthSessionModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: email,
      expiresAt: expiry,
    );
  }
}
