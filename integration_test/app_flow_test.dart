import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/core/utils/date_formatters.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:fin_sight_ai/features/wallets/presentation/screens/wallet_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

String money(double amount) => MoneyFormatter.format(amount, AppCurrency.cop);

String signedMoney(double amount) =>
    MoneyFormatter.signed(amount, AppCurrency.cop);

/// Pumps frames until [condition] holds or the timeout elapses.
Future<void> waitForCondition(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      return;
    }
  }
  throw TestFailure('Timed out waiting for condition.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationHarness harness;

  setUp(() async {
    harness = await IntegrationHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('shows an empty dashboard and updates after adding income', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('No transactions yet'));

    expect(find.text('FinSight AI'), findsOneWidget);
    expect(
      find.byTooltip('Sync offline: Supabase is not configured'),
      findsOneWidget,
    );
    expect(find.text('Transactions'), findsOneWidget);

    await tester.tap(find.text('Transactions'));
    await pumpUntil(tester, find.text('Add'));

    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(milliseconds: 400));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '120');
    await tester.enterText(fields.at(1), 'Salary');
    await tester.enterText(fields.at(2), 'Monthly pay');
    await tester.tap(find.text('Income'));
    await tester.pump();
    await tester.tap(find.text('Save transaction'));

    await pumpUntil(tester, find.text('Monthly pay'));
    await tester.pageBack();
    await pumpUntil(tester, find.text(money(120)));

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('scans a receipt and creates an expense transaction', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Scan receipt'));

    await tester.tap(find.text('Scan receipt'));
    await pumpUntil(tester, find.text('Camera'));

    await tester.tap(find.text('Camera'));
    await pumpUntil(tester, find.text('Receipt preview'));

    expect(find.text('ACME MARKET'), findsOneWidget);

    final categoryDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(categoryDropdown);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(categoryDropdown);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Groceries').last);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Save receipt'));
    await tester.tap(find.text('Save receipt'));
    await pumpUntilGone(tester, find.text('Receipt preview'));
    await pumpUntil(tester, find.text('ACME MARKET'));

    await tester.pageBack();
    await pumpUntil(tester, find.text(money(25.5)));

    final result = await harness.transactionRepository.getTransactions();
    final transactions = result.getOrElse((_) => const <TransactionEntity>[]);
    final receiptExpense = transactions.where(
      (transaction) =>
          transaction.amount == 25.5 && transaction.category == 'Groceries',
    );
    expect(receiptExpense, hasLength(1));
    expect(receiptExpense.single.description, 'ACME MARKET');
  });

  testWidgets('adds a debt and shows it in the list', (tester) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Debts'));

    await tester.tap(find.widgetWithText(ActionChip, 'Debts'));
    await pumpUntil(tester, find.byType(FloatingActionButton));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('Creditor name'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bank');
    await tester.enterText(fields.at(1), '1000');
    await tester.enterText(fields.at(2), '12');
    await tester.enterText(fields.at(3), '100');
    await tester.tap(find.text('Save debt'));

    await pumpUntil(tester, find.text('Bank'));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    final result = await harness.debtRepository.getDebts();
    final debts = result.getOrElse((_) => const <DebtEntity>[]);
    expect(debts.single.creditorName, 'Bank');
    expect(debts.single.totalAmount, 1000);
  });

  testWidgets('requests AI insights and renders a suggestion card', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('AI coach'));

    await tester.tap(find.text('AI coach'));
    await pumpUntil(tester, find.text('Get insights'));

    await tester.tap(find.text('Get insights'));
    await pumpUntil(tester, find.text('Automate 10% of your income.'));

    expect(find.text('SUGGESTION'), findsOneWidget);
  });

  testWidgets('adds a budget and shows category progress', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 40,
        type: TransactionType.expense,
        category: 'Food',
        description: 'Groceries',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text(money(40)));

    harness.router.goNamed(AppRoutes.budgetsName);
    await pumpUntil(tester, find.text('Add budget'));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New budget'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Food');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Save budget'));

    await pumpUntilGone(tester, find.text('New budget'));
    await pumpUntil(tester, find.text(money(100)));
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('signs in and out from the dashboard', (tester) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.byIcon(Icons.person_outline));

    await tester.tap(find.byIcon(Icons.person_outline));
    await pumpUntil(tester, find.text('Welcome back'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));

    await pumpUntil(tester, find.byIcon(Icons.logout));
    await tester.tap(find.byIcon(Icons.logout));
    await pumpUntil(tester, find.text('Sign out and erase local data?'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await pumpUntil(tester, find.byIcon(Icons.person_outline));
  });

  testWidgets('signing out erases local data before another sign-in', (
    tester,
  ) async {
    Future<void> signIn() async {
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline));
      await pumpUntil(tester, find.text('Welcome back'));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await pumpUntil(tester, find.byIcon(Icons.logout));
    }

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.byIcon(Icons.person_outline));

    await signIn();
    await harness.addTransaction(
      AddTransactionParams(
        amount: 42,
        type: TransactionType.income,
        category: 'Salary',
        description: 'Private salary',
        date: DateTime.now(),
      ),
    );
    harness.transactionBloc.add(const LoadTransactions());
    harness.dashboardBloc.add(const LoadDashboard());
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Private salary'));

    harness.router.goNamed(AppRoutes.dashboardName);
    await pumpUntil(tester, find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout));
    await pumpUntil(tester, find.text('Sign out and erase local data?'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await pumpUntil(tester, find.byIcon(Icons.person_outline));
    await pumpUntil(tester, find.text('No transactions yet'));

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('No transactions yet'));
    expect(find.text('Private salary'), findsNothing);

    harness.router.goNamed(AppRoutes.dashboardName);
    await pumpUntil(tester, find.byIcon(Icons.person_outline));
    await signIn();

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('No transactions yet'));
    expect(find.text('Private salary'), findsNothing);
  });

  testWidgets('stays signed in when the refresh fails offline', (tester) async {
    harness.seedOfflineExpiredSession();

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.byIcon(Icons.logout));

    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(harness.authRemote.refreshCount, 1);
    // Offline sync waits for a usable token, but the ledger stays readable.
    expect(harness.authRepository.accessToken, isNull);

    harness.authRemote.failRefresh = false;
    harness.authBloc.add(const RestoreAuthSession());
    await waitForCondition(
      tester,
      () => harness.authRepository.accessToken == 'refreshed-access-2',
    );
    await pumpUntil(tester, find.byIcon(Icons.logout));

    expect(harness.authStorage.session?.refreshToken, 'refreshed-refresh-2');
  });

  testWidgets('filters transactions by date range', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 100,
        type: TransactionType.income,
        category: 'Salary',
        description: 'January salary',
        date: DateTime(2026, 1, 10),
      ),
    );
    await harness.addTransaction(
      AddTransactionParams(
        amount: 50,
        type: TransactionType.expense,
        category: 'Shopping',
        description: 'December shopping',
        date: DateTime(2025, 12, 1),
      ),
    );

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Transactions'));
    await tester.tap(find.text('Transactions'));
    await pumpUntil(tester, find.text('January salary'));
    expect(find.text('December shopping'), findsOneWidget);

    harness.transactionBloc.add(
      FilterByDateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59, 999),
      ),
    );
    await pumpUntilGone(tester, find.text('December shopping'));

    expect(find.text('January salary'), findsOneWidget);
    expect(find.text(signedMoney(100)), findsWidgets);
  });

  testWidgets('manages bank/cash balances and switches currency', (
    tester,
  ) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 1000,
        type: TransactionType.income,
        category: 'Salary',
        description: 'Opening balance',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text(money(1000)));

    harness.router.goNamed(AppRoutes.moneyName);
    await pumpUntil(tester, find.text('Total available'));

    await tester.tap(find.text('Set balance').first);
    await pumpUntil(tester, find.text('Actual balance'));
    final balanceField = find.byType(TextFormField).last;
    await tester.enterText(balanceField, '500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await pumpUntil(tester, find.text(money(500)));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('Transfer money'));
    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '100');
    await tester.tap(find.widgetWithText(FilledButton, 'Transfer'));
    await pumpUntil(tester, find.text(money(100)));

    harness.router.goNamed(AppRoutes.settingsName);
    await pumpUntil(tester, find.text('Currency'));
    await tester.tap(find.text('USD'));
    await pumpUntil(tester, find.text('USD — US dollar'));

    final usdBalance = MoneyFormatter.format(500, AppCurrency.usd);
    harness.router.goNamed(AppRoutes.moneyName);
    await pumpUntil(tester, find.text(usdBalance));
    expect(find.text(usdBalance), findsWidgets);
  });

  testWidgets('refreshes wallet balances after a new expense', (tester) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('No transactions yet'));

    harness.router.goNamed(AppRoutes.moneyName);
    await pumpUntil(tester, find.text('Total available'));
    expect(find.text(money(0)), findsWidgets);

    await harness.addTransaction(
      AddTransactionParams(
        amount: 25,
        type: TransactionType.expense,
        category: 'Food',
        description: 'Lunch',
        date: DateTime.now(),
      ),
    );

    await tester.fling(
      find.descendant(
        of: find.byType(WalletScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, 320),
      1000,
    );
    await tester.pump();
    await pumpUntil(tester, find.text(money(-25)));

    expect(find.text(money(-25)), findsWidgets);
  });

  testWidgets('switches between English and Spanish', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.settingsName);
    await pumpUntil(tester, find.text('Settings'));
    expect(find.text('Language'), findsOneWidget);

    await tester.ensureVisible(find.text('Español'));
    await tester.tap(find.text('Español'));
    await pumpUntil(tester, find.text('Ajustes'));
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Moneda'), findsOneWidget);

    await tester.tap(find.text('English'));
    await pumpUntil(tester, find.text('Settings'));
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('manages custom categories', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.categoriesName);
    await pumpUntil(tester, find.text('Categories'));
    await pumpUntil(tester, find.text('Show archived'));

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add category'));
    await pumpUntil(tester, find.text('New category'));
    await tester.enterText(find.byType(TextFormField).last, 'Pets');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await pumpUntil(tester, find.text('Pets'));

    final petsTile = find.widgetWithText(ListTile, 'Pets');
    await tester.tap(
      find.descendant(
        of: petsTile,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await pumpUntil(tester, find.text('Rename category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename category'));
    await pumpUntil(tester, find.text('Category name'));
    await tester.enterText(find.byType(TextFormField).last, 'Pets & vet');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await pumpUntil(tester, find.text('Pets & vet'));

    final renamedTile = find.widgetWithText(ListTile, 'Pets & vet');
    await tester.tap(
      find.descendant(
        of: renamedTile,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await pumpUntil(tester, find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await pumpUntil(tester, find.text('Archive category?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await pumpUntilGone(tester, find.text('Pets & vet'));

    await tester.tap(find.text('Show archived'));
    await pumpUntil(tester, find.text('Pets & vet'));
    expect(find.text('Archived'), findsOneWidget);
    await tester.ensureVisible(find.text('Pets & vet'));
    await tester.drag(find.byType(ListView).last, const Offset(0, -120));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Pets & vet'),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await pumpUntil(tester, find.text('Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await pumpUntilGone(tester, find.text('Archived'));
  });

  testWidgets('schedules a recurring expense and records it', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.scheduledPaymentsName);
    await pumpUntil(tester, find.text('Scheduled payments'));
    await pumpUntil(tester, find.text('No scheduled payments'));

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add payment'));
    await pumpUntil(tester, find.text('New scheduled payment'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rent payment');
    await tester.enterText(fields.at(1), '800');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await pumpUntil(tester, find.text('Rent').last);
    await tester.tap(find.text('Rent').last);
    await tester.pumpAndSettle();

    final savePayment = find.widgetWithText(FilledButton, 'Add payment');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(savePayment);
    await pumpUntil(tester, find.text('1 scheduled expenses were added.'));
    await pumpUntilGone(tester, find.text('New scheduled payment'));
    expect(find.text('Rent payment'), findsOneWidget);

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Transactions'));
    await pumpUntil(tester, find.text('Rent payment'));
    expect(find.text(money(800)), findsWidgets);

    harness.router.goNamed(AppRoutes.scheduledPaymentsName);
    await pumpUntil(tester, find.text('Scheduled payments'));
    await pumpUntil(tester, find.text('Rent payment'));
    expect(find.text('Paid today'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await pumpUntil(tester, find.text('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause'));
    await pumpUntil(tester, find.text('Paused'));
    expect(find.text('Pay now'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await pumpUntil(tester, find.text('Delete scheduled payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete scheduled payment'));
    await pumpUntil(tester, find.text('Delete scheduled payment?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await pumpUntil(tester, find.text('No scheduled payments'));
  });

  testWidgets('persists state across an app restart', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 500,
        type: TransactionType.income,
        category: 'Salary',
        description: 'Persisted salary',
        date: DateTime.now(),
      ),
    );
    await harness.addDebt(
      AddDebtParams(
        creditorName: 'Persistent Bank',
        totalAmount: 1000,
        remainingAmount: 1000,
        interestRate: 12,
        minimumPayment: 100,
        dueDate: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    await harness.saveReceipt(
      ReceiptEntity(
        id: 'persisted-receipt',
        imagePath: '/tmp/persisted.jpg',
        merchantName: 'Persisted Store',
        date: DateTime.now(),
        totalAmount: 15,
        items: const [ReceiptItem(name: 'Tea', quantity: 1, price: 15)],
        currency: 'USD',
      ),
    );

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text(money(500)));

    await tester.pumpWidget(const SizedBox.shrink());
    await harness.restart();
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text(money(500)));

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Persisted salary'));

    harness.router.goNamed(AppRoutes.debtsName);
    await pumpUntil(tester, find.text('Persistent Bank'));

    harness.router.goNamed(AppRoutes.ocrName);
    await pumpUntil(tester, find.text('Persisted Store'));
  });

  testWidgets('records a late-evening transaction on the selected day', (
    tester,
  ) async {
    final today = DateTime.now();
    await harness.addTransaction(
      AddTransactionParams(
        amount: 18,
        type: TransactionType.expense,
        category: 'Food',
        description: 'Late dinner',
        date: DateTime(today.year, today.month, today.day, 20, 30),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Late dinner'));

    final expected = formatDisplayDate(today);
    expect(find.text('Food • $expected'), findsOneWidget);
    final tomorrow = formatDisplayDate(today.add(const Duration(days: 1)));
    expect(find.text('Food • $tomorrow'), findsNothing);
  });

  testWidgets('benchmarks launch and screen render times', (tester) async {
    final launch = Stopwatch()..start();
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('No transactions yet'));
    launch.stop();
    debugPrint(
      'BENCHMARK app_launch_and_dashboard=${launch.elapsedMilliseconds}ms',
    );
    expect(launch.elapsedMilliseconds, lessThan(5000));

    final render = Stopwatch()..start();
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Add'));
    render.stop();
    debugPrint('BENCHMARK transactions_render=${render.elapsedMilliseconds}ms');
    expect(render.elapsedMilliseconds, lessThan(3000));
  });
}
