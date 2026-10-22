import 'package:fin_sight_ai/app/app.dart';
import 'package:fin_sight_ai/core/routing/app_router.dart';
import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactions extends Mock implements GetTransactionsUseCase {}

class MockAddTransaction extends Mock implements AddTransactionUseCase {}

class MockDeleteTransaction extends Mock implements DeleteTransactionUseCase {}

class MockGetByDateRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

class MockGetDebts extends Mock implements GetDebtsUseCase {}

class MockAddDebt extends Mock implements AddDebtUseCase {}

class MockMakePayment extends Mock implements MakePaymentUseCase {}

class MockDeleteDebt extends Mock implements DeleteDebtUseCase {}

class MockCalculatePayoff extends Mock implements CalculatePayoffUseCase {}

void main() {
  late ThemeController themeController;
  late GoRouter router;
  late TransactionBloc transactionBloc;
  late DebtBloc debtBloc;

  setUp(() {
    themeController = ThemeController();
    router = buildRouter(themeController: themeController);
    transactionBloc = TransactionBloc(
      MockGetTransactions(),
      MockAddTransaction(),
      MockDeleteTransaction(),
      MockGetByDateRange(),
    );
    debtBloc = DebtBloc(
      MockGetDebts(),
      MockAddDebt(),
      MockMakePayment(),
      MockDeleteDebt(),
      MockCalculatePayoff(),
    );
  });

  Widget buildApp() {
    return FinSightApp(
      themeController: themeController,
      router: router,
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
    );
  }

  testWidgets('renders the dashboard with every feature shortcut', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('FinSight AI'), findsOneWidget);
    expect(find.text('Your money, clearly.'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Debts'), findsOneWidget);
    expect(find.text('Scan receipts'), findsOneWidget);
    expect(find.text('AI coach'), findsOneWidget);
  });

  testWidgets('navigates to the transactions feature', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transactions'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Your money, clearly.'), findsNothing);

    router.goNamed(AppRoutes.dashboardName);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your money, clearly.'), findsOneWidget);
  });

  testWidgets('navigates to the debts feature', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debts'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Debts'), findsOneWidget);
    expect(find.text('Add debt'), findsOneWidget);
  });

  testWidgets('toggles between dark and light themes', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app().themeMode, ThemeMode.system);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.dark);
    expect(app().themeMode, ThemeMode.dark);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.light);
    expect(app().themeMode, ThemeMode.light);
  });
}
