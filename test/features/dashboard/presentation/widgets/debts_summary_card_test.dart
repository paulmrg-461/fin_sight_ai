import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/widgets/debts_summary_card.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
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

  DebtEntity debt({
    String id = 'debt-1',
    String creditor = 'Bank',
    double remaining = 600,
    double minimum = 100,
    DateTime? due,
    DebtStatus status = DebtStatus.active,
  }) {
    return DebtEntity(
      id: id,
      creditorName: creditor,
      totalAmount: 1000,
      remainingAmount: remaining,
      interestRate: 12,
      minimumPayment: minimum,
      dueDate: due ?? DateTime(2026, 11, 5),
      status: status,
    );
  }

  testWidgets('shows the total, active count, and next due debt', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        DebtsSummaryCard(
          debts: [
            debt(),
            debt(
              id: 'debt-2',
              creditor: 'Card',
              remaining: 400,
              minimum: 50,
              due: DateTime(2026, 11, 1),
            ),
            debt(id: 'debt-3', status: DebtStatus.paid, remaining: 0),
          ],
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('Current debts'), findsOneWidget);
    expect(find.text('2 active'), findsOneWidget);
    expect(find.textContaining('Card'), findsOneWidget);

    await tester.tap(find.text('Current debts'));
    expect(taps, 1);
  });

  testWidgets('hides when there are no active debts', (tester) async {
    await tester.pumpWidget(
      wrap(
        DebtsSummaryCard(
          debts: [debt(status: DebtStatus.paid, remaining: 0)],
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Current debts'), findsNothing);
  });
}
