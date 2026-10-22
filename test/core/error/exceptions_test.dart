import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException', () {
    test('renders its type, message, and code', () {
      // Arrange
      const exception = CacheException('Disk full.', code: 'disk_full');

      // Act
      final description = exception.toString();

      // Assert
      expect(description, contains('CacheException'));
      expect(description, contains('Disk full.'));
      expect(description, contains('disk_full'));
    });
  });

  group('NoParams', () {
    test('all instances are equal', () {
      // Arrange
      const first = NoParams();
      const second = NoParams();

      // Act & Assert
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
