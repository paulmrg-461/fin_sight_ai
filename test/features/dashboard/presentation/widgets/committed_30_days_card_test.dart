import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/widgets/committed_30_days_card.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/committed_cashflow.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

void main() {
  late CurrencyBloc currencyBloc;

  setUp(() {
    currencyBloc = CurrencyBloc(MockGetCurrency(), MockSetCurrency())
      ..emit(const CurrencyLoaded(AppCurrency.cop));
  });

  tearDown(() async {
    await currencyBloc.close();
  });

  Widget wrap(Widget child) {
    return BlocProvider<CurrencyBloc>.value(
      value: currencyBloc,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows the total and the next three commitments', (tester) async {
    var taps = 0;
    final cashflow = CommittedCashflow(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
      payments: [
        for (var index = 0; index < 4; index++)
          CommittedPayment(
            date: DateTime(2026, 10, 5 + index),
            name: 'Payment $index',
            amount: 100,
            category: 'Bills',
            source: CommittedSource.scheduledPayment,
          ),
      ],
    );

    await tester.pumpWidget(
      wrap(Committed30DaysCard(cashflow: cashflow, onTap: () => taps++)),
    );

    expect(find.text('Committed next 30 days'), findsOneWidget);
    expect(find.text('Payment 0'), findsOneWidget);
    expect(find.text('Payment 2'), findsOneWidget);
    expect(find.text('Payment 3'), findsNothing);

    await tester.tap(find.text('Committed next 30 days'));
    expect(taps, 1);
  });
}
