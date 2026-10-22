import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('subclasses with the same message and code are equal', () {
      const first = CacheFailure('Store unavailable.', code: 'cache_down');
      const second = CacheFailure('Store unavailable.', code: 'cache_down');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different failure types are never equal', () {
      const cacheFailure = CacheFailure('Request failed.');
      const serverFailure = ServerFailure('Request failed.');

      expect(cacheFailure, isNot(serverFailure));
    });

    test('different codes are not equal', () {
      const first = ValidationFailure('Invalid input.', code: 'invalid_amount');
      const second = ValidationFailure(
        'Invalid input.',
        code: 'missing_category',
      );

      expect(first, isNot(second));
    });

    test('toString exposes the type, message, and code', () {
      const failure = ServerFailure('Service unavailable.', code: 'http_503');

      final description = failure.toString();

      expect(description, contains('ServerFailure'));
      expect(description, contains('Service unavailable.'));
      expect(description, contains('http_503'));
    });
  });
}
