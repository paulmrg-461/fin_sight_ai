import 'package:fin_sight_ai/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('subclasses with the same message and code are equal', () {
      // Arrange
      const first = CacheFailure('Store unavailable.', code: 'cache_down');
      const second = CacheFailure('Store unavailable.', code: 'cache_down');

      // Act & Assert
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different failure types are never equal', () {
      // Arrange
      const cacheFailure = CacheFailure('Request failed.');
      const serverFailure = ServerFailure('Request failed.');

      // Act & Assert
      expect(cacheFailure, isNot(serverFailure));
    });

    test('different codes are not equal', () {
      // Arrange
      const first = ValidationFailure('Invalid input.', code: 'invalid_amount');
      const second = ValidationFailure(
        'Invalid input.',
        code: 'missing_category',
      );

      // Act & Assert
      expect(first, isNot(second));
    });

    test('toString exposes the type, message, and code for diagnostics', () {
      // Arrange
      const failure = ServerFailure('Service unavailable.', code: 'http_503');

      // Act
      final description = failure.toString();

      // Assert
      expect(description, contains('ServerFailure'));
      expect(description, contains('Service unavailable.'));
      expect(description, contains('http_503'));
    });
  });
}
