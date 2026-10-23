import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

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
    await pumpUntil(tester, find.text('\$120.00'));

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
    await tester.ensureVisible(find.text('Save receipt'));
    await tester.tap(find.text('Save receipt'));
    await pumpUntilGone(tester, find.text('Receipt preview'));
    await pumpUntil(tester, find.text('ACME MARKET'));

    await tester.pageBack();
    await pumpUntil(tester, find.text('\$25.50'));

    final result = await harness.transactionRepository.getTransactions();
    final transactions = result.getOrElse((_) => const <TransactionEntity>[]);
    final receiptExpense = transactions.where(
      (transaction) =>
          transaction.amount == 25.5 && transaction.category == 'Receipts',
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
    await pumpUntil(tester, find.text('\$40.00'));

    harness.router.goNamed(AppRoutes.budgetsName);
    await pumpUntil(tester, find.text('Add budget'));

    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New budget'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Food');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Save budget'));

    await pumpUntilGone(tester, find.text('New budget'));
    await pumpUntil(tester, find.textContaining('/ \$100.00'));
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
    await pumpUntil(tester, find.byIcon(Icons.person_outline));
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
    expect(find.textContaining('100.00'), findsWidgets);
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
    await pumpUntil(tester, find.text('\$500.00'));

    await tester.pumpWidget(const SizedBox.shrink());
    await harness.restart();
    await harness.pumpApp(tester);
    await pumpUntil(tester, find.text('\$500.00'));

    harness.router.goNamed(AppRoutes.transactionsName);
    await pumpUntil(tester, find.text('Persisted salary'));

    harness.router.goNamed(AppRoutes.debtsName);
    await pumpUntil(tester, find.text('Persistent Bank'));

    harness.router.goNamed(AppRoutes.ocrName);
    await pumpUntil(tester, find.text('Persisted Store'));
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
