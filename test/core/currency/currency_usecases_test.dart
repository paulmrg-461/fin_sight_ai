import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_repository.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  late MockCurrencyRepository repository;

  setUpAll(() {
    registerFallbackValue(AppCurrency.cop);
  });

  setUp(() {
    repository = MockCurrencyRepository();
  });

  test('GetCurrencyUseCase returns the stored currency', () async {
    when(() => repository.getCurrency())
        .thenAnswer((_) async => AppCurrency.usd);

    final result = await GetCurrencyUseCase(repository)(const NoParams());

    expect(result.getOrElse((_) => AppCurrency.cop), AppCurrency.usd);
  });

  test('GetCurrencyUseCase falls back to COP on storage errors', () async {
    when(() => repository.getCurrency()).thenThrow(Exception('storage'));

    final result = await GetCurrencyUseCase(repository)(const NoParams());

    expect(result.getOrElse((_) => AppCurrency.usd), AppCurrency.cop);
  });

  test('SetCurrencyUseCase persists the currency', () async {
    when(() => repository.setCurrency(any())).thenAnswer((_) async {});

    final result = await SetCurrencyUseCase(repository)(AppCurrency.usd);

    expect(result.getOrElse((_) => AppCurrency.cop), AppCurrency.usd);
    verify(() => repository.setCurrency(AppCurrency.usd)).called(1);
  });

  test('SetCurrencyUseCase maps write failures', () async {
    when(() => repository.setCurrency(any())).thenThrow(Exception('disk'));

    final result = await SetCurrencyUseCase(repository)(AppCurrency.usd);

    expect(result.getLeft().toNullable()?.code, 'currency_write_failed');
  });
}
