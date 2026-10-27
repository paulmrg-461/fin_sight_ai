import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/budgets/domain/entities/budget_entity.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/widgets/budget_alerts_card.dart';
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

  BudgetProgress progress(String category, double limit, double spent) {
    return BudgetProgress(
      budget: BudgetEntity(
        id: category,
        category: category,
        monthlyLimit: limit,
        month: DateTime(2026, 10),
      ),
      spent: spent,
    );
  }

  testWidgets('shows only categories at 80% or more', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        BudgetAlertsCard(
          progress: [
            progress('Dining', 100, 90),
            progress('Food', 100, 40),
            progress('Travel', 100, 120),
          ],
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('Budget alerts'), findsOneWidget);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    expect(find.text('90% used'), findsOneWidget);

    await tester.tap(find.text('Budget alerts'));
    expect(taps, 1);
  });

  testWidgets('hides when no budget is close to its limit', (tester) async {
    await tester.pumpWidget(
      wrap(
        BudgetAlertsCard(progress: [progress('Food', 100, 10)], onTap: () {}),
      ),
    );

    expect(find.text('Budget alerts'), findsNothing);
  });
}
