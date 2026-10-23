import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/locale/locale_usecases.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_event.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_state.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetLocale extends Mock implements GetLocaleUseCase {}

class MockSetLocale extends Mock implements SetLocaleUseCase {}

void main() {
  late MockGetLocale getLocale;
  late MockSetLocale setLocale;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getLocale = MockGetLocale();
    setLocale = MockSetLocale();
  });

  LocaleBloc buildBloc() => LocaleBloc(getLocale, setLocale);

  blocTest<LocaleBloc, LocaleState>(
    'loads the stored locale',
    setUp: () {
      when(() => getLocale(any()))
          .thenAnswer((_) async => const Right(Locale('es')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadLocale()),
    expect: () => [const LocaleLoaded(Locale('es'))],
  );

  blocTest<LocaleBloc, LocaleState>(
    'changes the locale',
    setUp: () {
      when(() => setLocale(any()))
          .thenAnswer((_) async => const Right(Locale('es')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ChangeLocale(Locale('es'))),
    expect: () => [const LocaleLoaded(Locale('es'))],
  );

  blocTest<LocaleBloc, LocaleState>(
    'surfaces failures',
    setUp: () {
      when(() => getLocale(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Storage down.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadLocale()),
    expect: () => [const LocaleFailure('Storage down.')],
  );

  blocTest<LocaleBloc, LocaleState>(
    'surfaces write failures',
    setUp: () {
      when(() => setLocale(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Read only.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ChangeLocale(Locale('es'))),
    expect: () => [const LocaleFailure('Read only.')],
  );

  test('states compare by value', () {
    expect(const LocaleInitial(), const LocaleInitial());
    expect(const LocaleLoaded(Locale('en')), const LocaleLoaded(Locale('en')));
    expect(const LocaleFailure('x'), const LocaleFailure('x'));
  });

  test('events compare by value', () {
    expect(const LoadLocale(), const LoadLocale());
    expect(const ChangeLocale(Locale('es')), const ChangeLocale(Locale('es')));
  });
}
