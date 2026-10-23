import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_event.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

void main() {
  late MockGetCurrency getCurrency;
  late MockSetCurrency setCurrency;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(AppCurrency.cop);
  });

  setUp(() {
    getCurrency = MockGetCurrency();
    setCurrency = MockSetCurrency();
  });

  CurrencyBloc buildBloc() => CurrencyBloc(getCurrency, setCurrency);

  blocTest<CurrencyBloc, CurrencyState>(
    'loads the stored currency',
    setUp: () {
      when(() => getCurrency(any()))
          .thenAnswer((_) async => const Right(AppCurrency.usd));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadCurrency()),
    expect: () => [const CurrencyLoaded(AppCurrency.usd)],
  );

  blocTest<CurrencyBloc, CurrencyState>(
    'changes the currency',
    setUp: () {
      when(() => setCurrency(any()))
          .thenAnswer((_) async => const Right(AppCurrency.usd));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ChangeCurrency(AppCurrency.usd)),
    expect: () => [const CurrencyLoaded(AppCurrency.usd)],
  );

  blocTest<CurrencyBloc, CurrencyState>(
    'surfaces change failures',
    setUp: () {
      when(() => setCurrency(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Write failed.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ChangeCurrency(AppCurrency.usd)),
    expect: () => [const CurrencyFailure('Write failed.')],
  );

  test('exposes COP before loading and the loaded currency afterwards', () {
    final bloc = buildBloc();
    expect(bloc.currency, AppCurrency.cop);

    bloc.emit(const CurrencyLoaded(AppCurrency.usd));
    expect(bloc.currency, AppCurrency.usd);
    bloc.close();
  });

  test('currency events compare by value', () {
    expect(const LoadCurrency(), const LoadCurrency());
    expect(
      const ChangeCurrency(AppCurrency.usd),
      const ChangeCurrency(AppCurrency.usd),
    );
    expect(const ChangeCurrency(AppCurrency.usd).props, [AppCurrency.usd]);
  });

  blocTest<CurrencyBloc, CurrencyState>(
    'surfaces failures',
    setUp: () {
      when(() => getCurrency(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Storage down.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadCurrency()),
    expect: () => [const CurrencyFailure('Storage down.')],
  );
}
