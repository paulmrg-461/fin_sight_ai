import 'package:fin_sight_ai/app/app.dart';
import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/locale/locale_usecases.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_state.dart';
import 'package:fin_sight_ai/core/routing/app_router.dart';
import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/core/services/receipt_image_picker.dart';
import 'package:fin_sight_ai/core/services/receipt_image_store.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/analyze_spending_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/insight_cache.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_state.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart'
    as categories;
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_state.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/committed_cashflow_usecase.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_state.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/add_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/delete_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/get_receivables_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/make_receivable_payment_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/update_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_bloc.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_state.dart';
import 'package:fin_sight_ai/features/receivables/presentation/screens/receivable_list_screen.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_state.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:fin_sight_ai/features/transactions/presentation/screens/transaction_screen.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactions extends Mock implements GetTransactionsUseCase {}

class MockAddTransaction extends Mock implements AddTransactionUseCase {}

class MockDeleteTransaction extends Mock implements DeleteTransactionUseCase {}

class MockUpdateTransaction extends Mock implements UpdateTransactionUseCase {}

class MockGetByDateRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

class MockGetDebts extends Mock implements GetDebtsUseCase {}

class MockAddDebt extends Mock implements AddDebtUseCase {}

class MockMakePayment extends Mock implements MakePaymentUseCase {}

class MockDeleteDebt extends Mock implements DeleteDebtUseCase {}

class MockCalculatePayoff extends Mock implements CalculatePayoffUseCase {}

class MockGetReceivables extends Mock implements GetReceivablesUseCase {}

class MockAddReceivable extends Mock implements AddReceivableUseCase {}

class MockMakeReceivablePayment extends Mock
    implements MakeReceivablePaymentUseCase {}

class MockUpdateReceivable extends Mock implements UpdateReceivableUseCase {}

class MockDeleteReceivable extends Mock implements DeleteReceivableUseCase {}

class MockCategoryCatalog extends Mock
    implements categories.GetCategoryCatalogUseCase {}

class MockAddCategory extends Mock implements categories.AddCategoryUseCase {}

class MockRenameCategory extends Mock
    implements categories.RenameCategoryUseCase {}

class MockArchiveCategory extends Mock
    implements categories.SetCategoryArchivedUseCase {}

class MockGetScheduledPayments extends Mock
    implements GetScheduledPaymentsUseCase {}

class MockAddScheduledPayment extends Mock
    implements AddScheduledPaymentUseCase {}

class MockUpdateScheduledPayment extends Mock
    implements UpdateScheduledPaymentUseCase {}

class MockSetScheduledPaymentActive extends Mock
    implements SetScheduledPaymentActiveUseCase {}

class MockDeleteScheduledPayment extends Mock
    implements DeleteScheduledPaymentUseCase {}

class MockPayScheduledPayment extends Mock
    implements PayScheduledPaymentUseCase {}

class MockProcessDuePayments extends Mock
    implements ProcessDueScheduledPaymentsUseCase {}

class MockGetCommitted extends Mock implements GetCommittedCashflowUseCase {}

class MockScanReceipt extends Mock implements ScanReceiptUseCase {}

class MockSaveReceipt extends Mock implements SaveReceiptUseCase {}

class MockGetReceipts extends Mock implements GetReceiptsUseCase {}

class MockGetInsights extends Mock implements GetInsightsUseCase {}

class MockInsightCache extends Mock implements InsightCache {}

class MockAnalyzeSpending extends Mock implements AnalyzeSpendingUseCase {}

class MockGetSavings extends Mock implements GetSavingsSuggestionsUseCase {}

class MockGetDashboardData extends Mock implements GetDashboardDataUseCase {}

class MockDashboardCommitted extends Mock
    implements GetCommittedCashflowUseCase {}

class MockSyncNow extends Mock implements SyncNowUseCase {}

class MockGetSyncStatus extends Mock implements GetSyncStatusUseCase {}

class MockSignIn extends Mock implements SignInUseCase {}

class MockSignUp extends Mock implements SignUpUseCase {}

class MockSignOut extends Mock implements SignOutUseCase {}

class MockRestoreSession extends Mock implements RestoreSessionUseCase {}

class MockAddBudget extends Mock implements AddBudgetUseCase {}

class MockDeleteBudget extends Mock implements DeleteBudgetUseCase {}

class MockUpdateBudget extends Mock implements UpdateBudgetUseCase {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgressUseCase {}

class MockGetCategories extends Mock implements GetCategoriesUseCase {}

class MockGetWalletBalances extends Mock implements GetWalletBalancesUseCase {}

class MockSetWalletBalance extends Mock implements SetWalletBalanceUseCase {}

class MockTransferBetweenWallets extends Mock
    implements TransferBetweenWalletsUseCase {}

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

class MockGetLocale extends Mock implements GetLocaleUseCase {}

class MockSetLocale extends Mock implements SetLocaleUseCase {}

class MockReceiptImageStore extends Mock implements ReceiptImageStore {}

class _FakeReceiptImagePicker implements ReceiptImagePicker {
  @override
  Future<String?> pick(ReceiptImageSource source) async => null;
}

void main() {
  late ThemeController themeController;
  late GoRouter router;
  late TransactionBloc transactionBloc;
  late DebtBloc debtBloc;
  late ReceivableBloc receivableBloc;
  late OcrBloc ocrBloc;
  late AiCoachBloc aiCoachBloc;
  late DashboardBloc dashboardBloc;
  late SyncBloc syncBloc;
  late AuthBloc authBloc;
  late BudgetBloc budgetBloc;
  late WalletBloc walletBloc;
  late CurrencyBloc currencyBloc;
  late LocaleBloc localeBloc;
  late CategoryBloc categoryBloc;
  late ScheduledPaymentBloc scheduledPaymentBloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      DashboardRangeParams(
        start: DateTime.utc(2026),
        end: DateTime.utc(2026, 1, 31),
      ),
    );
    registerFallbackValue(
      DateRangeParams(
        start: DateTime.utc(2026),
        end: DateTime.utc(2026, 1, 31),
      ),
    );
  });

  setUp(() {
    themeController = ThemeController();
    router = buildRouter(
      themeController: themeController,
      receiptImagePicker: _FakeReceiptImagePicker(),
    );

    final getTransactions = MockGetTransactions();
    final addTransaction = MockAddTransaction();
    final getByRange = MockGetByDateRange();

    transactionBloc = TransactionBloc(
      getTransactions,
      addTransaction,
      MockDeleteTransaction(),
      getByRange,
      MockUpdateTransaction(),
    );
    debtBloc = DebtBloc(
      MockGetDebts(),
      MockAddDebt(),
      MockMakePayment(),
      MockDeleteDebt(),
      MockCalculatePayoff(),
    );
    final getReceivables = MockGetReceivables();
    when(() => getReceivables(any()))
        .thenAnswer((_) async => const Right(<ReceivableEntity>[]));
    receivableBloc = ReceivableBloc(
      getReceivables,
      MockAddReceivable(),
      MockUpdateReceivable(),
      MockMakeReceivablePayment(),
      MockDeleteReceivable(),
    );
    addTearDown(receivableBloc.close);
    ocrBloc = OcrBloc(
      MockScanReceipt(),
      MockSaveReceipt(),
      MockGetReceipts(),
      addTransaction,
      MockReceiptImageStore(),
    );
    aiCoachBloc = AiCoachBloc(
      MockGetInsights(),
      MockAnalyzeSpending(),
      MockGetSavings(),
      getTransactions,
      MockInsightCache(),
    );

    final getDashboard = MockGetDashboardData();
    when(() => getDashboard(any())).thenAnswer(
      (_) async => Right(
        DashboardData(
          summary: _zeroSummary,
          breakdown: const [],
          comparison: _zeroComparison,
          recentTransactions: const [],
          start: _zeroStart,
          end: _zeroEnd,
        ),
      ),
    );

    dashboardBloc = DashboardBloc(getDashboard, MockDashboardCommitted());

    syncBloc = SyncBloc(MockSyncNow(), MockGetSyncStatus());
    authBloc = AuthBloc(
      MockSignIn(),
      MockSignUp(),
      MockSignOut(),
      MockRestoreSession(),
    );
    budgetBloc = BudgetBloc(
      MockAddBudget(),
      MockUpdateBudget(),
      MockDeleteBudget(),
      MockGetBudgetProgress(),
      MockGetCategories(),
    );
    walletBloc = WalletBloc(
      MockGetWalletBalances(),
      MockSetWalletBalance(),
      MockTransferBetweenWallets(),
    );
    currencyBloc = CurrencyBloc(MockGetCurrency(), MockSetCurrency());
    localeBloc = LocaleBloc(MockGetLocale(), MockSetLocale());
    categoryBloc = CategoryBloc(
      MockCategoryCatalog(),
      MockAddCategory(),
      MockRenameCategory(),
      MockArchiveCategory(),
    );
    scheduledPaymentBloc = ScheduledPaymentBloc(
      MockGetScheduledPayments(),
      MockAddScheduledPayment(),
      MockUpdateScheduledPayment(),
      MockSetScheduledPaymentActive(),
      MockDeleteScheduledPayment(),
      MockPayScheduledPayment(),
      MockProcessDuePayments(),
      MockGetCommitted(),
    );
  });

  Widget buildApp() {
    return FinSightApp(
      themeController: themeController,
      router: router,
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
      receivableBloc: receivableBloc,
      ocrBloc: ocrBloc,
      aiCoachBloc: aiCoachBloc,
      dashboardBloc: dashboardBloc,
      syncBloc: syncBloc,
      authBloc: authBloc,
      budgetBloc: budgetBloc,
      walletBloc: walletBloc,
      currencyBloc: currencyBloc,
      localeBloc: localeBloc,
      categoryBloc: categoryBloc,
      scheduledPaymentBloc: scheduledPaymentBloc,
    );
  }

  Future<void> pumpReady(WidgetTester tester) async {
    dashboardBloc.emit(
      DashboardEmpty(start: DateTime.now(), end: DateTime.now()),
    );
    syncBloc.emit(
      const SyncIdle(
        SyncStatusEntity(
          pendingCount: 0,
          isConfigured: true,
          isAuthenticated: true,
        ),
      ),
    );
    authBloc.emit(const AuthUnauthenticated());
    budgetBloc.emit(const BudgetEmpty(categories: []));
    receivableBloc.emit(const ReceivableEmpty());
    categoryBloc.emit(const CategoryEmpty());
    scheduledPaymentBloc.emit(const ScheduledPaymentEmpty());
    walletBloc.emit(
      WalletLoaded([
        WalletBalance(
          wallet: const WalletEntity(
            id: 'wallet-bank',
            name: 'Cuenta principal',
            type: WalletType.bank,
            openingBalance: 0,
          ),
          balance: 0,
        ),
        WalletBalance(
          wallet: const WalletEntity(
            id: 'wallet-cash',
            name: 'Efectivo',
            type: WalletType.cash,
            openingBalance: 0,
          ),
          balance: 0,
        ),
      ]),
    );
    currencyBloc.emit(const CurrencyLoaded(AppCurrency.cop));
    localeBloc.emit(const LocaleLoaded(Locale('en')));
    await tester.pumpWidget(buildApp());
    await tester.pump();
  }

  testWidgets('renders the empty dashboard with quick actions', (tester) async {
    await pumpReady(tester);

    expect(find.text('FinSight AI'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quick-action-transactions')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quick-action-transactions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('quick-action-debts')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-action-ocr')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-action-ai-coach')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Money'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('navigates to the transactions feature', (tester) async {
    await pumpReady(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transactions'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TransactionScreen), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('navigates to the debts feature', (tester) async {
    await pumpReady(tester);

    final debtsAction = find.byKey(const ValueKey('quick-action-debts'));
    await tester.scrollUntilVisible(
      debtsAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(debtsAction);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Debts'), findsOneWidget);
    expect(find.text('Add debt'), findsOneWidget);
  });

  testWidgets('navigates to receivables from the dashboard', (tester) async {
    await pumpReady(tester);

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
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ReceivableListScreen), findsOneWidget);
    expect(find.text('Add money lent'), findsWidgets);
  });

  testWidgets('navigates to OCR and AI coach', (tester) async {
    await pumpReady(tester);

    final ocrAction = find.byKey(const ValueKey('quick-action-ocr'));
    await tester.scrollUntilVisible(
      ocrAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(ocrAction);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Scan receipts'), findsOneWidget);
    expect(find.text('No receipts yet'), findsOneWidget);

    router.goNamed(AppRoutes.dashboardName);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final aiAction = find.byKey(const ValueKey('quick-action-ai-coach'));
    await tester.scrollUntilVisible(
      aiAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(aiAction);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('AI coach'), findsOneWidget);
    expect(find.text('Your coach is ready'), findsOneWidget);
  });

  testWidgets('toggles between dark and light themes', (tester) async {
    await pumpReady(tester);

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app().themeMode, ThemeMode.system);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(SwitchListTile),
      120,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.dark);
    expect(app().themeMode, ThemeMode.dark);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.light);
    expect(app().themeMode, ThemeMode.light);
  });

  testWidgets('localizes the login app bar when the locale changes', (
    tester,
  ) async {
    await pumpReady(tester);

    router.goNamed(AppRoutes.loginName);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    localeBloc.emit(const LocaleLoaded(Locale('es')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });
}

final _zeroStart = DateTime.utc(2026, 10);
final _zeroEnd = DateTime.utc(2026, 10, 31);

const _zeroSummary = DashboardSummaryEntity(
  totalIncome: 0,
  totalExpenses: 0,
  balance: 0,
  savingsRate: 0,
  monthOverMonthChange: 0,
);

const _zeroComparison = MonthlyComparisonEntity(
  currentIncome: 0,
  currentExpenses: 0,
  previousIncome: 0,
  previousExpenses: 0,
  expenseChangePercentage: 0,
);
