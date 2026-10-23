import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/locale/locale_repository.dart';
import 'package:fin_sight_ai/core/locale/locale_usecases.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLocaleRepository extends Mock implements LocaleRepository {}

void main() {
  late MockLocaleRepository repository;

  setUp(() {
    repository = MockLocaleRepository();
  });

  group('GetLocaleUseCase', () {
    test('returns the stored locale', () async {
      when(() => repository.getLocale())
          .thenAnswer((_) async => const Locale('es'));

      final result = await GetLocaleUseCase(repository)(const NoParams());

      expect(result.getOrElse((_) => null), const Locale('es'));
      expect(result.isRight(), isTrue);
    });

    test('falls back to the system locale when storage fails', () async {
      when(() => repository.getLocale()).thenThrow(Exception('offline'));

      final result = await GetLocaleUseCase(repository)(const NoParams());

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => const Locale('en')), isNull);
    });
  });

  group('SetLocaleUseCase', () {
    test('persists the locale', () async {
      when(() => repository.setLocale(any())).thenAnswer((_) async {});

      final result = await SetLocaleUseCase(repository)(const Locale('en'));

      expect(result.getOrElse((_) => null), const Locale('en'));
      verify(() => repository.setLocale(const Locale('en'))).called(1);
    });

    test('clears the preference when switching to system', () async {
      when(() => repository.setLocale(null)).thenAnswer((_) async {});

      final result = await SetLocaleUseCase(repository)(null);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => const Locale('en')), isNull);
    });

    test('returns a cache failure when persistence fails', () async {
      when(() => repository.setLocale(any())).thenThrow(Exception('disk'));

      final result = await SetLocaleUseCase(repository)(const Locale('es'));

      expect(
        result,
        left(
          const CacheFailure(
            'Unable to save the language preference.',
            code: 'locale_write_failed',
          ),
        ),
      );
    });
  });
}
