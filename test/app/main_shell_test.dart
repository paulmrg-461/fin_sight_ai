import 'package:fin_sight_ai/app/app.dart';
import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/currency/presentation/screens/settings_screen.dart';
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
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/coach_chat_store.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/ask_coach_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/insight_cache.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/coach_chat_bloc.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:fin_sight_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_state.dart';
import 'package:fin_sight_ai/features/budgets/presentation/screens/budget_screen.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart'
    as categories;
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_state.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/debts/presentation/screens/debt_list_screen.dart';
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
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/committed_cashflow_usecase.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_state.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/screens/scheduled_payment_screen.dart';
import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/core/services/biometric_service.dart';
import 'package:fin_sight_ai/core/services/onboarding_service.dart';
import 'package:fin_sight_ai/core/services/security_preferences.dart';
import 'package:fin_sight_ai/features/security/presentation/bloc/security_cubit.dart';
import 'package:fin_sight_ai/features/import_data/presentation/bloc/import_csv_cubit.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/import_transactions_csv_usecase.dart';
import 'package:fin_sight_ai/features/reports/domain/repositories/report_exporter.dart';
import 'package:fin_sight_ai/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:fin_sight_ai/features/savings/domain/usecases/savings_usecases.dart';
import 'package:fin_sight_ai/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:fin_sight_ai/features/transactions/presentation/screens/transaction_screen.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_state.dart';
import 'package:fin_sight_ai/features/wallets/presentation/screens/wallet_screen.dart';

import '../support/fake_reminder_scheduler.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactions extends Mock implements GetTransactionsUseCase {}

class MockAskCoach extends Mock implements AskCoachUseCase {}

class MockCoachChatStore extends Mock implements CoachChatStore {}

class MockAddTransaction extends Mock implements AddTransactionUseCase {}

class MockDeleteTransaction extends Mock implements DeleteTransactionUseCase {}

class MockUpdateTransaction extends Mock implements UpdateTransactionUseCase {}

class MockReportExporter extends Mock implements ReportExporter {}

class MockOnboardingService extends Mock implements OnboardingService {}

class MockImportCsvUseCase extends Mock
    implements ImportTransactionsCsvUseCase {}

class MockSecurityPreferences extends Mock implements SecurityPreferences {}

class MockBiometricService extends Mock implements BiometricService {}

class MockGetByDateRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

class MockGetDebts extends Mock implements GetDebtsUseCase {}

class MockGetSavingsGoals extends Mock implements GetSavingsGoalsUseCase {}

class MockCreateSavingsGoal extends Mock implements CreateSavingsGoalUseCase {}

class MockUpdateSavingsGoal extends Mock implements UpdateSavingsGoalUseCase {}

class MockAddSavingsContribution extends Mock
    implements AddSavingsContributionUseCase {}

class MockDeleteSavingsGoal extends Mock implements DeleteSavingsGoalUseCase {}

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

AuthSession _session() => AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  userId: 'user-1',
  email: 'user@example.com',
  expiresAt: DateTime.now().add(const Duration(days: 1)),
);

MockOnboardingService _onboarding() {
  final service = MockOnboardingService();
  when(() => service.isCompleted()).thenAnswer((_) async => true);
  return service;
}

SecurityCubit _security() {
  final preferences = MockSecurityPreferences();
  final biometrics = MockBiometricService();
  when(() => preferences.isBiometricEnabled()).thenAnswer((_) async => false);
  when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
  return SecurityCubit(preferences, biometrics);
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
        start: DateTime.utc(2026, 10, 1),
        end: DateTime.utc(2026, 10, 31),
      ),
    );
  });

  setUp(() {
    themeController = ThemeController();
    final getWalletBalances = MockGetWalletBalances();
    when(() => getWalletBalances(any()))
        .thenAnswer((_) async => const Right(<WalletBalance>[]));

    final getTransactions = MockGetTransactions();
    final addTransaction = MockAddTransaction();

    transactionBloc = TransactionBloc(
      getTransactions,
      addTransaction,
      MockDeleteTransaction(),
      MockGetByDateRange(),
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
      MockGetDebts(),
      MockGetSavingsGoals(),
      MockInsightCache(),
    );
    final getDashboard = MockGetDashboardData();
    when(() => getDashboard(any())).thenAnswer(
      (_) async => Right(
        DashboardData(
          summary: const DashboardSummaryEntity(
            totalIncome: 0,
            totalExpenses: 0,
            balance: 0,
            savingsRate: 0,
            monthOverMonthChange: 0,
          ),
          breakdown: const <CategoryBreakdown>[],
          comparison: const MonthlyComparisonEntity(
            currentIncome: 0,
            currentExpenses: 0,
            previousIncome: 0,
            previousExpenses: 0,
            expenseChangePercentage: 0,
          ),
          recentTransactions: const <TransactionEntity>[],
          start: DateTime.utc(2026, 10),
          end: DateTime.utc(2026, 10, 31),
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
      getWalletBalances,
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
      FakeReminderScheduler(),
    );

    router = buildRouter(
      themeController: themeController,
      receiptImagePicker: _FakeReceiptImagePicker(),
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
      reportsBloc: ReportsBloc(MockGetByDateRange(), MockReportExporter()),
      onboardingService: _onboarding(),
      importCsvCubit: ImportCsvCubit(MockImportCsvUseCase()),
      securityCubit: _security(),
      savingsBloc: SavingsBloc(
        MockGetSavingsGoals(),
        MockCreateSavingsGoal(),
        MockUpdateSavingsGoal(),
        MockAddSavingsContribution(),
        MockDeleteSavingsGoal(),
      ),
      coachChatBloc: CoachChatBloc(
        MockAskCoach(),
        MockGetTransactions(),
        MockGetDebts(),
        MockGetSavingsGoals(),
        MockCoachChatStore(),
      ),
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
    transactionBloc.emit(const TransactionEmpty());
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
    walletBloc.emit(const WalletLoaded([]));
    currencyBloc.emit(const CurrencyLoaded(AppCurrency.cop));
    localeBloc.emit(const LocaleLoaded(Locale('en')));
    await tester.pumpWidget(buildApp());
    await tester.pump();
  }

  Future<void> tapDestination(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollDrawerTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
  }

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('renders the dashboard on a compact phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpReady(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('FinSight AI'), findsOneWidget);
  });

  testWidgets('switches among the five primary destinations', (tester) async {
    await pumpReady(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(selectedIndex(tester), 0);

    await tapDestination(tester, 'Transactions');
    expect(find.byType(TransactionScreen), findsOneWidget);
    expect(selectedIndex(tester), 1);

    await tapDestination(tester, 'Budgets');
    expect(find.byType(BudgetScreen), findsOneWidget);
    expect(selectedIndex(tester), 2);

    await tapDestination(tester, 'Scheduled');
    expect(find.byType(ScheduledPaymentScreen), findsOneWidget);
    expect(selectedIndex(tester), 3);

    await tapDestination(tester, 'Money');
    expect(find.byType(WalletScreen), findsOneWidget);
    expect(selectedIndex(tester), 4);

    await tapDestination(tester, 'Dashboard');
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(selectedIndex(tester), 0);
  });

  testWidgets('renders every primary destination on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpReady(tester);
    for (final label in const [
      'Transactions',
      'Budgets',
      'Scheduled',
      'Money',
      'Dashboard',
    ]) {
      await tapDestination(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('selects the destination for a deep link', (tester) async {
    await pumpReady(tester);

    router.goNamed(AppRoutes.moneyName);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WalletScreen), findsOneWidget);
    expect(selectedIndex(tester), 4);
  });

  testWidgets('opens the drawer from every primary screen', (tester) async {
    await pumpReady(tester);

    for (final label in const [
      'Dashboard',
      'Transactions',
      'Budgets',
      'Scheduled',
      'Money',
    ]) {
      await tapDestination(tester, label);
      await openDrawer(tester);

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Main menu'), findsOneWidget);

      await tester.tapAt(const Offset(780, 300));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('pushes debts over the shell and returns on back', (
    tester,
  ) async {
    await pumpReady(tester);
    await openDrawer(tester);

    await scrollDrawerTo(tester, find.widgetWithText(ListTile, 'Debts'));
    await tester.tap(find.widgetWithText(ListTile, 'Debts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DebtListScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('pushes receivables over the shell and returns on back', (
    tester,
  ) async {
    await pumpReady(tester);
    await openDrawer(tester);

    await scrollDrawerTo(tester, find.widgetWithText(ListTile, 'Owed to me'));
    await tester.tap(find.widgetWithText(ListTile, 'Owed to me'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ReceivableListScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('opens settings from the drawer without the bottom bar', (
    tester,
  ) async {
    await pumpReady(tester);
    await openDrawer(tester);

    await scrollDrawerTo(tester, find.widgetWithText(ListTile, 'Settings'));
    await tester.tap(find.widgetWithText(ListTile, 'Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('toggles the theme from the drawer', (tester) async {
    await pumpReady(tester);
    expect(themeController.themeMode, ThemeMode.system);

    await openDrawer(tester);
    await scrollDrawerTo(tester, find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(themeController.themeMode, ThemeMode.dark);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(themeController.themeMode, ThemeMode.light);
  });

  testWidgets('shows the signed-in email in the drawer header', (tester) async {
    await pumpReady(tester);
    authBloc.emit(AuthAuthenticated(_session()));

    await openDrawer(tester);

    expect(find.text('user@example.com'), findsOneWidget);
  });

  testWidgets('keeps sign-out and sync out of the dashboard app bar', (
    tester,
  ) async {
    await pumpReady(tester);
    authBloc.emit(AuthAuthenticated(_session()));
    await tester.pump();

    expect(find.byIcon(Icons.logout), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_sync_outlined), findsNothing);
  });

  testWidgets('moves sync and sign-out into the drawer', (tester) async {
    await pumpReady(tester);
    authBloc.emit(AuthAuthenticated(_session()));

    await openDrawer(tester);
    await scrollDrawerTo(tester, find.text('Sign out'));

    expect(find.widgetWithText(ListTile, 'Sync'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Sign out'), findsOneWidget);
  });

  testWidgets('confirms sign-out from the drawer', (tester) async {
    await pumpReady(tester);
    authBloc.emit(AuthAuthenticated(_session()));

    await openDrawer(tester);
    await scrollDrawerTo(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out and erase local data?'), findsOneWidget);
  });

  testWidgets('offers sign-in in the drawer when signed out', (tester) async {
    await pumpReady(tester);

    await openDrawer(tester);
    await scrollDrawerTo(tester, find.text('Sign in'));

    expect(find.widgetWithText(ListTile, 'Sign in'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Sign out'), findsNothing);
  });

  testWidgets('keeps login outside the shell', (tester) async {
    await pumpReady(tester);

    router.goNamed(AppRoutes.loginName);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
