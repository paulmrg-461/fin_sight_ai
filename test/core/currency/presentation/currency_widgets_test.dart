import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
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

void main() {
  late CurrencyBloc bloc;

  setUpAll(() {
    registerFallbackValue(AppCurrency.cop);
  });

  setUp(() {
    final getCurrency = MockGetCurrency();
    final setCurrency = MockSetCurrency();
    when(() => setCurrency(any()))
        .thenAnswer((_) async => const Right(AppCurrency.usd));
    bloc = CurrencyBloc(getCurrency, setCurrency);
  });

  tearDown(() => bloc.close());

  Widget wrap(Widget child) => BlocProvider.value(
    value: bloc,
    child: MaterialApp(home: Scaffold(body: child)),
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

    expect(find.text('USD — US Dollar'), findsOneWidget);
  });
}
