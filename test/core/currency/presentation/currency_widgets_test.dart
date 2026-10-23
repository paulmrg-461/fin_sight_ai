import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/locale/locale_usecases.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_state.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/currency/presentation/screens/settings_screen.dart';
import 'package:fin_sight_ai/core/currency/presentation/widgets/money_text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

class MockGetLocale extends Mock implements GetLocaleUseCase {}

class MockSetLocale extends Mock implements SetLocaleUseCase {}

void main() {
  late CurrencyBloc bloc;
  late LocaleBloc localeBloc;
  late MockSetLocale setLocale;

  setUpAll(() {
    registerFallbackValue(AppCurrency.cop);
  });

  setUp(() {
    final getCurrency = MockGetCurrency();
    final setCurrency = MockSetCurrency();
    when(() => setCurrency(any()))
        .thenAnswer((_) async => const Right(AppCurrency.usd));
    bloc = CurrencyBloc(getCurrency, setCurrency);
    setLocale = MockSetLocale();
    when(() => setLocale(any())).thenAnswer((_) async => const Right(null));
    localeBloc = LocaleBloc(MockGetLocale(), setLocale)
      ..emit(const LocaleLoaded(Locale('en')));
  });

  tearDown(() async {
    await bloc.close();
    await localeBloc.close();
  });

  Widget wrap(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<CurrencyBloc>.value(value: bloc),
      BlocProvider<LocaleBloc>.value(value: localeBloc),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('MoneyText formats using the active currency', (tester) async {
    bloc.emit(const CurrencyLoaded(AppCurrency.cop));
    await tester.pumpWidget(wrap(const MoneyText(1234.5)));
    expect(find.textContaining('1.234,50'), findsOneWidget);

    bloc.emit(const CurrencyLoaded(AppCurrency.usd));
    await tester.pumpAndSettle();
    expect(find.textContaining('1,234.50'), findsOneWidget);
  });

  testWidgets('MoneyText supports signed amounts', (tester) async {
    bloc.emit(const CurrencyLoaded(AppCurrency.cop));
    await tester.pumpWidget(wrap(const MoneyText(-20, signed: true)));

    expect(find.textContaining('-'), findsOneWidget);
  });

  testWidgets('MoneyText falls back to COP before loading', (tester) async {
    await tester.pumpWidget(wrap(const MoneyText(10)));

    expect(find.textContaining('10,00'), findsOneWidget);
  });

  testWidgets('CurrencyLabel shows the active code', (tester) async {
    bloc.emit(const CurrencyLoaded(AppCurrency.usd));
    await tester.pumpWidget(wrap(const CurrencyLabel()));
    await tester.pump();

    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows failures', (tester) async {
    bloc.emit(const CurrencyFailure('Storage down.'));
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Storage down.'), findsOneWidget);
  });

  testWidgets('SettingsScreen switches currency', (tester) async {
    bloc.emit(const CurrencyLoaded(AppCurrency.cop));
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('COP'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);

    bloc.emit(const CurrencyLoaded(AppCurrency.usd));
    await tester.pumpAndSettle();

    expect(find.text('USD — US dollar'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows locale failures', (tester) async {
    bloc.emit(const CurrencyLoaded(AppCurrency.cop));
    localeBloc.emit(const LocaleFailure('Read only.'));
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Read only.'), findsOneWidget);
  });

  testWidgets('SettingsScreen switches language', (tester) async {
    when(() => setLocale(any()))
        .thenAnswer((_) async => const Right(Locale('es')));

    bloc.emit(const CurrencyLoaded(AppCurrency.cop));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CurrencyBloc>.value(value: bloc),
          BlocProvider<LocaleBloc>.value(value: localeBloc),
        ],
        child: BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, state) {
            return MaterialApp(
              locale: state is LocaleLoaded ? state.locale : null,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Español'));
    final spanish = localeBloc.stream.firstWhere(
      (state) => state is LocaleLoaded && state.locale?.languageCode == 'es',
    );
    await tester.tap(find.text('Español'));
    await tester.runAsync(() => spanish);
    await tester.pumpAndSettle();

    verify(() => setLocale(any())).called(greaterThan(0));
    expect((localeBloc.state as LocaleLoaded).locale, const Locale('es'));
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);

    when(() => setLocale(any()))
        .thenAnswer((_) async => const Right(Locale('en')));
    final english = localeBloc.stream.firstWhere(
      (state) => state is LocaleLoaded && state.locale?.languageCode == 'en',
    );
    await tester.tap(find.text('English'));
    await tester.runAsync(() => english);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}
