import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/core/widgets/app_progress_bar.dart';
import 'package:fin_sight_ai/core/utils/date_formatters.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:fin_sight_ai/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_event.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_state.dart';
import 'package:fin_sight_ai/features/wallets/presentation/screens/wallet_screen.dart';
import 'package:flutter/services.dart';
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

Future<void> openDrawer(WidgetTester tester) async {
  await pumpUntil(tester, find.byTooltip('Open menu'));
  if (find.byType(Drawer).evaluate().isEmpty) {
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
  }
}

Future<void> scrollDrawerTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeDrawer(WidgetTester tester) async {
  if (find.byType(Drawer).evaluate().isEmpty) {
    return;
  }
  Scaffold.of(tester.element(find.byType(Drawer))).closeDrawer();
  await tester.pumpAndSettle();
}

Future<void> tapDrawerItem(WidgetTester tester, String label) async {
  await openDrawer(tester);
  await scrollDrawerTo(tester, find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
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

  testWidgets('locks the app until biometrics succeed', (tester) async {
    harness.securityPreferences.enabled = true;
    harness.biometrics.result = false;

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('FinSight AI is locked'));

    harness.biometrics.result = true;
    await tester.tap(find.text('Unlock'));
    await pumpUntil(tester, find.text('No transactions yet'));
  });

  testWidgets('shows onboarding once and opens the dashboard', (tester) async {
    harness.onboardingService.completed = false;

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Welcome to FinSight AI'));

    await tester.tap(find.text('Skip'));
    await pumpUntil(tester, find.text('No transactions yet'));
    expect(harness.onboardingService.completed, isTrue);
  });

  testWidgets('shows an empty dashboard and updates after adding income', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('No transactions yet'));
    // Let categories seed so the transaction form has a default category.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('FinSight AI'), findsOneWidget);
    await openDrawer(tester);
    await scrollDrawerTo(
      tester,
      find.text('Sync offline: Supabase is not configured'),
    );
    expect(
      find.text('Sync offline: Supabase is not configured'),
      findsOneWidget,
    );
    await closeDrawer(tester);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transactions'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transactions'),
      ),
    );
    await pumpUntil(tester, find.text('Add'));

    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(milliseconds: 400));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '120');
    await tester.enterText(fields.at(1), 'Monthly pay');
    await tester.tap(find.text('Income'));
    await tester.pump();
    final saveTransaction = find.text('Save transaction');
    await tester.ensureVisible(saveTransaction);
    await tester.pumpAndSettle();
    await tester.tap(saveTransaction);

    await pumpUntil(tester, find.text('Monthly pay'));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Dashboard'),
      ),
    );
    await tester.pump();
    harness.dashboardBloc.add(const LoadDashboard());
    await pumpUntil(tester, find.text(money(120)));

    expect(find.text('Income'), findsWidgets);
    expect(find.text('No transactions yet'), findsNothing);

    harness.syncBloc.add(const LoadSyncStatus());
    await waitForCondition(tester, () {
      final state = harness.syncBloc.state;
      // Seeded categories and default wallets are queued too, so assert that
      // the transaction write reached the queue rather than an exact total.
      return state is SyncIdle && state.status.pendingCount >= 1;
    });
  });

  testWidgets('shows committed debt minimums on the dashboard', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 2000,
        type: TransactionType.income,
        category: 'Salary',
        description: 'Monthly pay',
        date: DateTime.now(),
      ),
    );
    await harness.addDebt(
      AddDebtParams(
        creditorName: 'Bank',
        totalAmount: 1000,
        remainingAmount: 1000,
        interestRate: 0,
        minimumPayment: 150,
        dueDate: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Balance'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text('Committed next 30 days'));
    expect(find.text(money(150)), findsWidgets);
  });

  testWidgets('scans a receipt and creates an expense transaction', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    final ocrAction = find.byKey(const ValueKey('quick-action-ocr'));
    await tester.scrollUntilVisible(
      ocrAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(ocrAction);
    await pumpUntil(tester, find.text('Camera'));
    await tester.pumpAndSettle();
    final camera = find.text('Camera');
    await tester.ensureVisible(camera);
    await tester.tap(camera);
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
    final debtsAction = find.byKey(const ValueKey('quick-action-debts'));
    await tester.scrollUntilVisible(
      debtsAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(debtsAction);
    await pumpUntil(tester, find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('Creditor name'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bank');
    await tester.enterText(fields.at(1), '1000');
    await tester.enterText(fields.at(2), '12');
    await tester.enterText(fields.at(3), '100');
    await tester.tap(find.text('Save debt'));
    await pumpUntilGone(tester, find.text('Save debt'));

    await pumpUntil(tester, find.text('Bank'));
    expect(find.byType(AppProgressBar), findsOneWidget);

    final result = await harness.debtRepository.getDebts();
    final debts = result.getOrElse((_) => const <DebtEntity>[]);
    expect(debts.single.creditorName, 'Bank');
    expect(debts.single.totalAmount, 1000);

    await tester.tap(find.text('Bank'));
    await pumpUntil(tester, find.text('Debt details'));
    await tester.tap(find.text('Calculate'));
    await pumpUntil(tester, find.text('Payment plan'));
    expect(find.text('Total interest'), findsOneWidget);
    expect(find.textContaining('payments'), findsWidgets);
  });

  testWidgets('tracks money lent, receives a payment, and persists restart', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    final receivablesAction = find.byKey(
      const ValueKey('quick-action-receivables'),
    );
    await tester.scrollUntilVisible(
      receivablesAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(receivablesAction);
    await pumpUntil(tester, find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('Who owes you'));

    await tester.enterText(
      find.byKey(const ValueKey('receivable-debtor-field')),
      'Ana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('receivable-amount-field')),
      '1000',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('receivable-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receivable-save')));

    await pumpUntil(tester, find.text('Ana'));
    expect(find.byType(AppProgressBar), findsOneWidget);
    expect(find.text(money(1000)), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Add payment'));
    await pumpUntil(tester, find.text('Payment amount'));
    await tester.enterText(
      find.byKey(const ValueKey('receivable-payment-amount-field')),
      '400',
    );
    await tester.tap(find.byKey(const ValueKey('receivable-payment-submit')));

    await pumpUntil(tester, find.text(money(600)));
    expect(find.text(money(600)), findsWidgets);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ana'));
    await pumpUntil(tester, find.text('Receivable details'));
    await tester.tap(find.byKey(const ValueKey('receivable-edit')));
    await pumpUntil(tester, find.text('Edit receivable'));
    await tester.enterText(
      find.byKey(const ValueKey('receivable-debtor-field')),
      'Ana María',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('receivable-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receivable-save')));
    await pumpUntil(tester, find.text('Ana María'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    final summary = find.byKey(const ValueKey('receivables-summary-card'));
    await pumpUntil(tester, summary);
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: summary, matching: find.text(money(600))),
      findsOneWidget,
    );
    expect(find.text('1 person owes you'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await harness.restart();
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.receivablesName);
    await pumpUntil(tester, find.text('Ana María'));
    expect(find.text(money(600)), findsWidgets);

    final result = await harness.receivableRepository.getReceivables();
    final receivables = result.getOrElse((_) => const <ReceivableEntity>[]);
    expect(receivables.single.remainingAmount, 600);
    expect(receivables.single.paymentHistory, hasLength(1));
  });

  testWidgets('asks the AI coach a free-form question', (tester) async {
    harness.groq.response = 'Pay the card first.';

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.aiCoachName);
    await pumpUntil(tester, find.byTooltip('Ask the coach'));

    await tester.tap(find.byTooltip('Ask the coach'));
    await pumpUntil(tester, find.text('Ask anything about your finances'));

    await tester.tap(find.text('Where am I overspending?'));
    await pumpUntil(tester, find.text('Pay the card first.'));

    expect(find.text('Where am I overspending?'), findsOneWidget);
  });

  testWidgets('requests AI insights and renders a suggestion card', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    final aiAction = find.byKey(const ValueKey('quick-action-ai-coach'));
    await tester.scrollUntilVisible(
      aiAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(aiAction);
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

  testWidgets('edits a transaction in place, then deletes and undoes it', (
    tester,
  ) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 20,
        type: TransactionType.expense,
        category: 'Food',
        description: 'Lunch',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Lunch'));

    await tester.tap(find.byTooltip('Edit transaction'));
    await pumpUntil(tester, find.text('Edit transaction'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '45');
    await tester.enterText(fields.at(1), 'Lunch updated');
    final saveChanges = find.text('Save changes');
    await tester.ensureVisible(saveChanges);
    await tester.pumpAndSettle();
    await tester.tap(saveChanges);
    await pumpUntilGone(tester, find.text('Save changes'));

    await pumpUntil(tester, find.text('Lunch updated'));
    expect(find.text('Lunch'), findsNothing);

    final stored = await harness.transactionRepository.getTransactions();
    final updated = stored.getOrElse(
      (failure) =>
          throw TestFailure('Expected stored transaction: ${failure.message}'),
    );
    expect(updated, hasLength(1));
    expect(updated.single.description, 'Lunch updated');
    expect(updated.single.amount, 45);
    expect(updated.single.category, 'Food');

    await tester.tap(find.byTooltip('Delete transaction'));
    await pumpUntil(tester, find.text('Delete transaction?'));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await pumpUntilGone(tester, find.text('Lunch updated'));

    final afterDelete = await harness.transactionRepository.getTransactions();
    expect(
      afterDelete.getOrElse(
        (failure) => throw TestFailure('Expected empty list'),
      ),
      isEmpty,
    );

    await pumpUntil(tester, find.text('Undo'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Undo'));
    await pumpUntil(tester, find.text('Lunch updated'));

    final restored = await harness.transactionRepository.getTransactions();
    expect(
      restored.getOrElse(
        (failure) => throw TestFailure('Expected restored transaction'),
      ),
      hasLength(1),
    );
  });

  testWidgets('duplicates a transaction as a new record', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 20,
        type: TransactionType.expense,
        category: 'Food',
        description: 'Lunch',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Lunch'));

    await tester.tap(find.byTooltip('Edit transaction'));
    await pumpUntil(tester, find.text('Edit transaction'));
    final copy = find.text('Save as copy');
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await pumpUntilGone(tester, find.text('Save as copy'));
    await pumpUntil(tester, find.text('Lunch'));

    final stored = await harness.transactionRepository.getTransactions();
    final transactions = stored.getOrElse(
      (_) => throw TestFailure('Expected transactions'),
    );
    expect(transactions, hasLength(2));
    expect(transactions.map((item) => item.id).toSet(), hasLength(2));
    expect(transactions.map((item) => item.amount), everyElement(20));
  });

  testWidgets('edits and deletes a budget with confirmation', (tester) async {
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
    harness.router.goNamed(AppRoutes.budgetsName);
    await pumpUntil(tester, find.text('Add budget'));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New budget'));
    var fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Food');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Save budget'));
    await pumpUntilGone(tester, find.text('New budget'));
    await pumpUntil(tester, find.text(money(100)));

    await tester.tap(find.text('Food'));
    await pumpUntil(tester, find.text('Edit budget'));
    fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller?.text,
      isNotEmpty,
    );
    await tester.enterText(fields.at(1), '150');
    await tester.tap(find.text('Save changes'));
    await pumpUntilGone(tester, find.text('Edit budget'));
    await pumpUntil(tester, find.text(money(150)));

    await tester.tap(find.byTooltip('Delete budget'));
    await pumpUntil(tester, find.text('Delete budget?'));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await pumpUntilGone(tester, find.text('Delete budget?'));
    expect(find.text(money(150)), findsOneWidget);

    await tester.tap(find.byTooltip('Delete budget'));
    await pumpUntil(tester, find.text('Delete budget?'));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await pumpUntil(tester, find.text('No budgets yet'));
  });

  testWidgets('navigates between budget months', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.budgetsName);
    await pumpUntil(tester, find.text('Add budget'));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New budget'));
    var fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Food');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Save budget'));
    await pumpUntilGone(tester, find.text('New budget'));
    await pumpUntil(tester, find.text(money(100)));

    await tester.tap(find.byTooltip('Previous month'));
    await pumpUntil(tester, find.text('No budgets yet'));

    await tester.tap(find.byTooltip('Next month'));
    await pumpUntil(tester, find.text(money(100)));
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('copies the previous month budgets into the selected month', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.budgetsName);
    await pumpUntil(tester, find.text('Add budget'));

    await tester.tap(find.byTooltip('Previous month'));
    await pumpUntil(tester, find.text('No budgets yet'));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New budget'));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Food');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Save budget'));
    await pumpUntilGone(tester, find.text('New budget'));
    await pumpUntil(tester, find.text(money(100)));

    await tester.tap(find.byTooltip('Next month'));
    await pumpUntil(tester, find.text('Copy previous month'));
    await tester.tap(find.text('Copy previous month'));
    await pumpUntil(tester, find.text(money(100)));
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('imports transactions from pasted CSV and skips duplicates', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.importCsvName);
    await pumpUntil(tester, find.text('Import CSV'));

    const csv =
        'date,type,category,description,amount,wallet\n'
        '2026-10-31,expense,Dining,Lunch,25000,wallet-bank\n'
        '2026-11-01,income,Freelance,Invoice,300000,wallet-bank';
    await tester.enterText(find.byType(TextField).first, csv);
    await tester.tap(find.text('Import transactions'));
    await pumpUntil(tester, find.textContaining('2 imported'));

    final stored = await harness.transactionRepository.getTransactions();
    final transactions = stored.getOrElse(
      (_) => throw TestFailure('Expected imported transactions'),
    );
    expect(transactions, hasLength(2));
    expect(transactions.map((item) => item.description), contains('Lunch'));

    await tester.tap(find.text('Import transactions'));
    await pumpUntil(tester, find.textContaining('2 skipped'));
    expect(
      (await harness.transactionRepository.getTransactions()).getOrElse(
        (_) => throw TestFailure('Expected transactions'),
      ),
      hasLength(2),
    );
  });

  testWidgets('builds a monthly report and shares its CSV', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 300,
        type: TransactionType.income,
        category: 'Freelance',
        description: 'Invoice',
        date: DateTime.now(),
      ),
    );
    await harness.addTransaction(
      AddTransactionParams(
        amount: 100,
        type: TransactionType.expense,
        category: 'Dining',
        description: 'Dinner',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.reportsName);
    await pumpUntil(tester, find.text('Reports'));

    await pumpUntil(tester, find.text(money(200)));
    await tester.tap(find.byTooltip('Share CSV'));
    await pumpUntil(tester, find.text('Report shared.'));

    expect(harness.reportExporter.lastCsv, contains('Dinner'));
    expect(harness.reportExporter.lastFileName, endsWith('.csv'));

    await tester.tap(find.byTooltip('Previous month'));
    await pumpUntil(tester, find.text('Nothing recorded this month'));
  });

  testWidgets('builds an annual report and shares its PDF', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 300,
        type: TransactionType.income,
        category: 'Freelance',
        description: 'Invoice',
        date: DateTime.now(),
      ),
    );
    await harness.addTransaction(
      AddTransactionParams(
        amount: 100,
        type: TransactionType.expense,
        category: 'Dining',
        description: 'Dinner',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.reportsName);
    await pumpUntil(tester, find.text('Reports'));

    await pumpUntil(tester, find.text('Monthly'));
    await tester.tap(find.text('Annual'));
    await pumpUntil(tester, find.text('Annual ${DateTime.now().year}'));

    await tester.tap(find.byTooltip('Share annual PDF'));
    await pumpUntil(tester, find.text('Annual PDF shared.'));

    final pdf = harness.reportExporter.lastPdf;
    expect(pdf, isNotNull);
    expect(String.fromCharCodes(pdf!.take(4)), '%PDF');
    expect(harness.reportExporter.lastFileName, endsWith('.pdf'));
  });

  testWidgets('searches across transactions, debts, and goals', (tester) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 47,
        type: TransactionType.expense,
        category: 'Dining',
        description: 'Salchipapas',
        date: DateTime.now(),
      ),
    );
    await harness.addDebt(
      AddDebtParams(
        creditorName: 'Banco',
        totalAmount: 1000,
        remainingAmount: 600,
        interestRate: 12,
        minimumPayment: 100,
        dueDate: DateTime.now().add(const Duration(days: 10)),
      ),
    );
    await harness.savingsRepository.addGoal(
      SavingsGoalEntity(
        id: 'goal-trip',
        name: 'Viaje',
        targetAmount: 2000,
        createdAt: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Balance'));
    harness.router.goNamed(AppRoutes.searchName);
    await pumpUntil(tester, find.text('Search everything'));

    final field = find.byType(TextField).first;
    await tester.enterText(field, 'banco');
    await tester.pump();
    await pumpUntil(tester, find.text('Banco'));
    expect(find.text('Debts'), findsOneWidget);

    await tester.enterText(field, 'viaje');
    await tester.pump();
    await pumpUntil(tester, find.text('Viaje'));
    expect(find.text('Savings goals'), findsOneWidget);

    await tester.enterText(field, 'zzz');
    await tester.pump();
    await pumpUntil(tester, find.text('No results'));
  });

  testWidgets('creates a savings goal and adds money', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.savingsName);
    await pumpUntil(tester, find.text('No savings goals yet'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'New savings goal'),
    );
    await pumpUntil(tester, find.text('Create goal'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Trip');
    await tester.enterText(fields.at(1), '1000');
    await tester.tap(find.text('Create goal'));
    await pumpUntilGone(tester, find.text('Create goal'));
    await pumpUntil(tester, find.text('Trip'));

    await tester.tap(find.widgetWithText(FilledButton, 'Add money'));
    await pumpUntil(tester, find.text('Contribution amount'));
    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.tap(find.widgetWithText(FilledButton, 'Add money').last);
    await pumpUntil(tester, find.text(money(400)));

    final stored = await harness.savingsRepository.getGoals();
    final goals = stored.getOrElse(
      (_) => throw TestFailure('Expected savings goals'),
    );
    expect(goals, hasLength(1));
    expect(goals.single.name, 'Trip');
    expect(goals.single.savedAmount, 400);

    await tester.tap(find.byKey(const ValueKey('goal-actions')).first);
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text('Edit savings goal'));
    await tester.tap(find.text('Edit savings goal'));
    await pumpUntil(tester, find.text('Save changes'));
    await tester.enterText(find.byType(TextFormField).at(1), '1200');
    await tester.tap(find.text('Save changes'));
    await pumpUntilGone(tester, find.text('Save changes'));

    final edited = (await harness.savingsRepository.getGoals()).getOrElse(
      (_) => throw TestFailure('Expected edited goal'),
    );
    expect(edited.single.targetAmount, 1200);
    expect(edited.single.savedAmount, 400);
  });

  testWidgets('signs in and out from the drawer', (tester) async {
    await harness.pumpApp(tester);
    await tapDrawerItem(tester, 'Sign in');
    await pumpUntil(tester, find.text('Welcome back'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));

    await waitForCondition(
      tester,
      () => harness.authRepository.isAuthenticated,
    );
    await tapDrawerItem(tester, 'Sign out');
    await pumpUntil(tester, find.text('Sign out and erase local data?'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await pumpUntil(tester, find.text('No transactions yet'));
  });

  testWidgets('signing out erases local data before another sign-in', (
    tester,
  ) async {
    Future<void> signIn() async {
      await tester.pumpAndSettle();
      await tapDrawerItem(tester, 'Sign in');
      await pumpUntil(tester, find.text('Welcome back'));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await waitForCondition(
        tester,
        () => harness.authRepository.isAuthenticated,
      );
    }

    await harness.pumpApp(tester);
    await pumpUntil(tester, find.byTooltip('Open menu'));

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
    await tapDrawerItem(tester, 'Sign out');
    await pumpUntil(tester, find.text('Sign out and erase local data?'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await pumpUntil(tester, find.text('No transactions yet'));

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('No transactions yet'));
    expect(find.text('Private salary'), findsNothing);

    harness.router.goNamed(AppRoutes.dashboardName);
    await waitForCondition(
      tester,
      () => !harness.authRepository.isAuthenticated,
    );
    await signIn();

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('No transactions yet'));
    expect(find.text('Private salary'), findsNothing);
  });

  testWidgets('stays signed in when the refresh fails offline', (tester) async {
    harness.seedOfflineExpiredSession();

    await harness.pumpApp(tester);
    await openDrawer(tester);
    await scrollDrawerTo(tester, find.text('Sign out'));

    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(harness.authRemote.refreshCount, 1);
    // Offline sync waits for a usable token, but the ledger stays readable.
    expect(harness.authRepository.accessToken, isNull);

    harness.authRemote.failRefresh = false;
    harness.authBloc.add(const RestoreAuthSession());
    await waitForCondition(
      tester,
      () => harness.authRepository.accessToken == 'refreshed-access-2',
    );
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('Sign out')),
      findsOneWidget,
    );

    expect(harness.authStorage.session?.refreshToken, 'refreshed-refresh-2');
  });

  testWidgets('searches transactions by text and clears the query', (
    tester,
  ) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 12,
        type: TransactionType.expense,
        category: 'Dining',
        description: 'Coffee beans',
        date: DateTime.now(),
      ),
    );
    await harness.addTransaction(
      AddTransactionParams(
        amount: 800,
        type: TransactionType.expense,
        category: 'Rent',
        description: 'Monthly rent',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Coffee beans'));
    expect(find.text('Monthly rent'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'coffee');
    await tester.pump();
    await pumpUntil(tester, find.text('Coffee beans'));
    expect(find.text('Monthly rent'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump();
    await pumpUntil(tester, find.text('No matching transactions'));

    await tester.tap(find.text('Clear search'));
    await pumpUntil(tester, find.text('Coffee beans'));
    expect(find.text('Monthly rent'), findsOneWidget);
  });

  testWidgets('copies the visible transactions as CSV', (tester) async {
    // The Linux embedder clipboard needs a live display server; route the
    // platform channel through an in-memory handler so the assertion stays
    // deterministic on headless CI.
    String? clipboardText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String?;
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        final text = clipboardText;
        return text == null ? null : <String, dynamic>{'text': text};
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await harness.addTransaction(
      AddTransactionParams(
        amount: 12.5,
        type: TransactionType.expense,
        category: 'Dining',
        description: 'Coffee beans',
        date: DateTime.now(),
      ),
    );

    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Coffee beans'));

    await tester.tap(find.byTooltip('Copy CSV'));
    await pumpUntil(
      tester,
      find.text('Copied 1 transaction to the clipboard.'),
    );

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, contains('date,type,category,description,amount'));
    expect(clipboard?.text, contains('Coffee beans'));
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
    await pumpUntil(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transactions'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transactions'),
      ),
    );
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

  testWidgets('switches to money and opens settings from the drawer', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('No transactions yet'));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Money'),
      ),
    );
    await pumpUntil(tester, find.text('Total available'));
    expect(find.byType(WalletScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Main menu'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Settings'),
      120,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Settings'));
    await pumpUntil(tester, find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await pumpUntil(tester, find.byType(NavigationBar));
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Total available'), findsOneWidget);
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

  testWidgets('renames a category across existing transactions', (
    tester,
  ) async {
    await harness.addTransaction(
      AddTransactionParams(
        amount: 25,
        type: TransactionType.expense,
        category: 'Dining',
        description: 'Cascade lunch',
        date: DateTime.now(),
      ),
    );
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.categoriesName);
    await pumpUntil(tester, find.text('Dining'));
    await tester.pumpAndSettle();

    final diningTile = find.widgetWithText(ListTile, 'Dining');
    await tester.ensureVisible(diningTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: diningTile,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await pumpUntil(tester, find.text('Rename category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename category'));
    await pumpUntil(tester, find.text('Category name'));
    await tester.enterText(find.byType(TextFormField).last, 'Eating out');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await pumpUntil(tester, find.text('Eating out'));

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Cascade lunch'));
    expect(find.text('Eating out'), findsOneWidget);
  });

  testWidgets('manages custom categories', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.categoriesName);
    await pumpUntil(tester, find.text('Categories'));
    await pumpUntil(tester, find.text('Show archived'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add category'));
    await pumpUntil(tester, find.text('New category'));
    await tester.enterText(find.byType(TextFormField).last, 'Pets');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await pumpUntil(tester, find.text('Pets'));
    await tester.pumpAndSettle();

    final petsTile = find.widgetWithText(ListTile, 'Pets');
    await tester.ensureVisible(petsTile);
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(renamedTile);
    await tester.pumpAndSettle();
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
    await tester.drag(find.byType(ListView).last, const Offset(0, 700));
    await tester.pumpAndSettle();

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
    await tester.ensureVisible(find.text('Rent').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rent').last);
    await tester.pumpAndSettle();

    final savePayment = find.widgetWithText(FilledButton, 'Add payment');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(savePayment);
    await pumpUntil(tester, find.text('1 scheduled entry was added.'));
    await pumpUntilGone(tester, find.text('New scheduled payment'));
    expect(find.text('Rent payment'), findsOneWidget);
    expect(find.text('Committed cashflow'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Add'));
    harness.transactionBloc.add(const LoadTransactions());
    await pumpUntil(tester, find.text('Rent payment'));
    expect(find.text(signedMoney(-800)), findsWidgets);

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

  testWidgets('edits a scheduled payment in place', (tester) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.scheduledPaymentsName);
    await pumpUntil(tester, find.text('Scheduled payments'));
    await pumpUntil(tester, find.text('No scheduled payments'));

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add payment'));
    await pumpUntil(tester, find.text('New scheduled payment'));
    var fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rent payment');
    await tester.enterText(fields.at(1), '800');
    final savePayment = find.widgetWithText(FilledButton, 'Add payment');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(savePayment);
    await pumpUntilGone(tester, find.text('New scheduled payment'));
    await pumpUntil(tester, find.text('Rent payment'));
    await pumpUntil(tester, find.text(money(800)));

    final before = await harness.scheduledPaymentRepository.getPayments();
    final original = before
        .getOrElse((_) => throw TestFailure('Expected scheduled payment'))
        .single;

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await pumpUntil(tester, find.text('Edit scheduled payment'));
    await tester.tap(find.text('Edit scheduled payment'));
    await pumpUntil(tester, find.text('Save changes'));

    fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '950');
    final saveChanges = find.text('Save changes');
    await tester.ensureVisible(saveChanges);
    await tester.pumpAndSettle();
    await tester.tap(saveChanges);
    await pumpUntilGone(tester, find.text('Save changes'));
    await pumpUntil(tester, find.text(money(950)));

    final after = await harness.scheduledPaymentRepository.getPayments();
    final updated = after
        .getOrElse((_) => throw TestFailure('Expected updated payment'))
        .single;
    expect(updated.id, original.id);
    expect(updated.amount, 950);
    expect(updated.createdAt, original.createdAt);
    expect(find.text('Committed cashflow'), findsOneWidget);
  });

  testWidgets('schedules a recurring salary and records it as income', (
    tester,
  ) async {
    await harness.pumpApp(tester);
    harness.router.goNamed(AppRoutes.scheduledPaymentsName);
    await pumpUntil(tester, find.text('Scheduled payments'));
    await pumpUntil(tester, find.text('No scheduled payments'));

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add payment'));
    await pumpUntil(tester, find.text('New scheduled payment'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Monthly salary');
    await tester.enterText(fields.at(1), '3000');
    await tester.tap(find.text('Income'));
    await tester.pump();
    expect(find.text('Salary'), findsWidgets);

    final savePayment = find.widgetWithText(FilledButton, 'Add payment');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(savePayment);
    await pumpUntil(tester, find.text('1 scheduled entry was added.'));
    await pumpUntilGone(tester, find.text('New scheduled payment'));

    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.text('Expected monthly income'), findsOneWidget);
    expect(find.text(money(3000)), findsOneWidget);
    expect(find.textContaining('Next income:'), findsOneWidget);

    final schedules = await harness.scheduledPaymentRepository.getPayments();
    final saved = schedules.getOrElse((_) => const <ScheduledPaymentEntity>[]);
    expect(saved.single.type, TransactionType.income);
    expect(saved.single.category, 'Salary');

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Add'));
    harness.transactionBloc.add(const LoadTransactions());
    await pumpUntil(tester, find.text('Monthly salary'));
    expect(find.text(signedMoney(3000)), findsWidgets);
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
    // Seed three months of ledger history so the benchmark measures a real
    // dashboard instead of the empty state.
    final now = DateTime.now();
    for (var index = 0; index < 300; index++) {
      final monthsBack = index % 3;
      final month = DateTime(now.year, now.month - monthsBack);
      final day = (index % 27) + 1;
      await harness.addTransaction(
        AddTransactionParams(
          amount: (index % 50) + 1,
          type: index % 30 == 0
              ? TransactionType.income
              : TransactionType.expense,
          category: index % 2 == 0 ? 'Groceries' : 'Dining',
          description: 'Benchmark entry $index',
          date: DateTime(month.year, month.month, day, 12),
        ),
      );
    }
    final count = await harness.transactionRepository.getTransactions();
    expect(count.getOrElse((_) => const <TransactionEntity>[]), hasLength(300));

    final launch = Stopwatch()..start();
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('Balance'));
    expect(harness.dashboardBloc.state, isA<DashboardLoaded>());
    launch.stop();
    debugPrint(
      'BENCHMARK app_launch_and_dashboard=${launch.elapsedMilliseconds}ms '
      '(seeded=300)',
    );
    expect(launch.elapsedMilliseconds, lessThan(5000));

    final render = Stopwatch()..start();
    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Add'));
    render.stop();
    debugPrint(
      'BENCHMARK transactions_render=${render.elapsedMilliseconds}ms '
      '(seeded=300)',
    );
    expect(render.elapsedMilliseconds, lessThan(3000));
  });
}
