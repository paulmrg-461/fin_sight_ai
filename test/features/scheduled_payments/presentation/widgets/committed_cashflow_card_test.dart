import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/committed_cashflow.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/widgets/committed_cashflow_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

void main() {
  late CurrencyBloc currencyBloc;

  final start = DateTime(2026, 10, 1);
  final end30 = DateTime(2026, 10, 31);
  final end90 = DateTime(2026, 12, 30);

  CommittedPayment payment({
    required DateTime date,
    required String name,
    double amount = 100,
  }) {
    return CommittedPayment(
      date: date,
      name: name,
      amount: amount,
      category: 'Rent',
      source: CommittedSource.scheduledPayment,
    );
  }

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

  testWidgets('shows the 30-day total and preview, then switches to 90', (
    tester,
  ) async {
    final thirty = CommittedCashflow(
      start: start,
      end: end30,
      payments: [
        payment(date: DateTime(2026, 10, 5), name: 'Rent'),
        payment(date: DateTime(2026, 10, 10), name: 'Phone', amount: 50),
      ],
    );
    final ninety = CommittedCashflow(
      start: start,
      end: end90,
      payments: [
        payment(date: DateTime(2026, 12, 1), name: 'Yearly insurance'),
      ],
    );

    await tester.pumpWidget(
      wrap(CommittedCashflowCard(thirtyDays: thirty, ninetyDays: ninety)),
    );

    expect(find.text('Committed cashflow'), findsOneWidget);
    expect(find.text('Committed total'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Yearly insurance'), findsNothing);

    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();

    expect(find.text('Yearly insurance'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
  });

  testWidgets('shows guidance when the window has no commitments', (
    tester,
  ) async {
    final empty = CommittedCashflow(
      start: start,
      end: end30,
      payments: const [],
    );

    await tester.pumpWidget(
      wrap(CommittedCashflowCard(thirtyDays: empty, ninetyDays: empty)),
    );

    expect(find.text('No commitments yet'), findsOneWidget);
    expect(find.textContaining('No active schedules'), findsOneWidget);
  });

  testWidgets('hides itself when both projections are unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const CommittedCashflowCard(thirtyDays: null, ninetyDays: null)),
    );

    expect(find.text('Committed cashflow'), findsNothing);
  });
}
