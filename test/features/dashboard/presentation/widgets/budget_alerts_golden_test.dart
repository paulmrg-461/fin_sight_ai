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
  testWidgets('budget alerts card matches its golden', (tester) async {
    final currencyBloc = CurrencyBloc(MockGetCurrency(), MockSetCurrency())
      ..emit(const CurrencyLoaded(AppCurrency.cop));
    addTearDown(currencyBloc.close);

    final progress = [
      BudgetProgress(
        budget: BudgetEntity(
          id: 'b-1',
          category: 'Dining',
          monthlyLimit: 200000,
          month: DateTime(2026, 10),
        ),
        spent: 190000,
      ),
      BudgetProgress(
        budget: BudgetEntity(
          id: 'b-2',
          category: 'Groceries',
          monthlyLimit: 300000,
          month: DateTime(2026, 10),
        ),
        spent: 330000,
      ),
    ];

    await tester.pumpWidget(
      BlocProvider<CurrencyBloc>.value(
        value: currencyBloc,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: BudgetAlertsCard(progress: progress, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BudgetAlertsCard),
      matchesGoldenFile('goldens/budget_alerts_card.png'),
    );
  });
}
