import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:fin_sight_ai/features/wallets/presentation/screens/wallet_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBalances extends Mock implements GetWalletBalancesUseCase {}

class MockSetBalance extends Mock implements SetWalletBalanceUseCase {}

class MockTransfer extends Mock implements TransferBetweenWalletsUseCase {}

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

void main() {
  const bank = WalletEntity(
    id: 'wallet-bank',
    name: 'Cuenta principal',
    type: WalletType.bank,
    openingBalance: 0,
  );
  const cash = WalletEntity(
    id: 'wallet-cash',
    name: 'Efectivo',
    type: WalletType.cash,
    openingBalance: 0,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  Widget wrap(WalletBloc walletBloc, {Locale locale = const Locale('en')}) {
    final currencyBloc = CurrencyBloc(MockGetCurrency(), MockSetCurrency())
      ..emit(const CurrencyLoaded(AppCurrency.cop));
    addTearDown(currencyBloc.close);

    return MultiBlocProvider(
      providers: [
        BlocProvider<WalletBloc>.value(value: walletBloc),
        BlocProvider<CurrencyBloc>.value(value: currencyBloc),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WalletScreen(),
      ),
    );
  }

  Future<void> pumpLoaded(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('loads wallet balances when the screen opens', (tester) async {
    final getBalances = MockGetBalances();
    when(() => getBalances(any())).thenAnswer(
      (_) async => Right([WalletBalance(wallet: bank, balance: 100)]),
    );
    final bloc = WalletBloc(getBalances, MockSetBalance(), MockTransfer());
    addTearDown(bloc.close);

    await pumpLoaded(tester, wrap(bloc));

    verify(() => getBalances(any())).called(1);
    expect(find.text('Bank account'), findsOneWidget);
    expect(
      find.text(MoneyFormatter.format(100, AppCurrency.cop)),
      findsWidgets,
    );
  });

  testWidgets('pull-to-refresh reloads the balances', (tester) async {
    var calls = 0;
    final getBalances = MockGetBalances();
    when(() => getBalances(any())).thenAnswer((_) async {
      calls++;
      return Right([
        WalletBalance(wallet: bank, balance: calls == 1 ? 100 : 250),
      ]);
    });
    final bloc = WalletBloc(getBalances, MockSetBalance(), MockTransfer());
    addTearDown(bloc.close);

    await pumpLoaded(tester, wrap(bloc));
    expect(
      find.text(MoneyFormatter.format(100, AppCurrency.cop)),
      findsWidgets,
    );

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    expect(calls, 2);
    expect(
      find.text(MoneyFormatter.format(250, AppCurrency.cop)),
      findsWidgets,
    );
  });

  testWidgets('shows Spanish labels for the default wallets', (tester) async {
    final getBalances = MockGetBalances();
    when(() => getBalances(any())).thenAnswer(
      (_) async => Right([
        WalletBalance(wallet: bank, balance: 100),
        WalletBalance(wallet: cash, balance: 20),
      ]),
    );
    final bloc = WalletBloc(getBalances, MockSetBalance(), MockTransfer());
    addTearDown(bloc.close);

    await pumpLoaded(tester, wrap(bloc, locale: const Locale('es')));

    expect(find.text('Cuenta bancaria'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Cuenta principal'), findsNothing);
  });

  testWidgets('keeps custom wallet names', (tester) async {
    const custom = WalletEntity(
      id: 'custom-wallet',
      name: 'Ahorros',
      type: WalletType.bank,
      openingBalance: 0,
    );
    final getBalances = MockGetBalances();
    when(() => getBalances(any())).thenAnswer(
      (_) async => Right([WalletBalance(wallet: custom, balance: 5)]),
    );
    final bloc = WalletBloc(getBalances, MockSetBalance(), MockTransfer());
    addTearDown(bloc.close);

    await pumpLoaded(tester, wrap(bloc, locale: const Locale('es')));

    expect(find.text('Ahorros'), findsOneWidget);
  });
}
