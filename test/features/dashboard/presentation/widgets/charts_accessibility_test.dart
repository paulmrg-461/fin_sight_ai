import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/widgets/category_pie_chart.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/widgets/monthly_comparison_chart.dart';
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

  tearDown(() => currencyBloc.close());

  Widget wrap(Widget child) {
    return BlocProvider<CurrencyBloc>.value(
      value: currencyBloc,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('pie chart announces the category breakdown', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
        const CategoryPieChart(
          breakdown: [
            CategoryBreakdown(category: 'Food', amount: 60, percentage: 60),
            CategoryBreakdown(category: 'Rent', amount: 40, percentage: 40),
          ],
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        RegExp('Spending by category chart: Food 60%, Rent 40%'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('comparison chart announces what it compares', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
        const MonthlyComparisonChart(
          comparison: MonthlyComparisonEntity(
            currentIncome: 1000,
            currentExpenses: 400,
            previousIncome: 900,
            previousExpenses: 300,
            expenseChangePercentage: 33.3,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Monthly expense comparison chart. Current period versus previous period.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
