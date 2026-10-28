import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/presentation/widgets/transaction_list.dart';
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

  TransactionEntity transaction({
    required String id,
    required double amount,
    required TransactionType type,
    required DateTime date,
  }) {
    return TransactionEntity(
      id: id,
      amount: amount,
      type: type,
      category: 'Food',
      description: id,
      date: date,
    );
  }

  testWidgets('groups transactions by day with a daily net', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    final yesterday = today.subtract(const Duration(days: 1));

    await tester.pumpWidget(
      BlocProvider<CurrencyBloc>.value(
        value: currencyBloc,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TransactionList(
              transactions: [
                transaction(
                  id: 'coffee',
                  amount: 10,
                  type: TransactionType.expense,
                  date: today,
                ),
                transaction(
                  id: 'pay',
                  amount: 50,
                  type: TransactionType.income,
                  date: today,
                ),
                transaction(
                  id: 'lunch',
                  amount: 5,
                  type: TransactionType.expense,
                  date: yesterday,
                ),
              ],
              onDelete: (_) {},
              onEdit: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('coffee'), findsOneWidget);
    expect(find.text('lunch'), findsOneWidget);

    // Today nets +40; yesterday nets -5 (header plus the lunch tile).
    expect(find.textContaining('40,00'), findsOneWidget);
    expect(find.textContaining('-5,00'), findsNWidgets(2));
  });
}
