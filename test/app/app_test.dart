import 'package:fin_sight_ai/app/app.dart';
import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/routing/app_router.dart';
import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/core/services/receipt_image_picker.dart';
import 'package:fin_sight_ai/core/services/receipt_image_store.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/analyze_spending_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_state.dart';
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
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_state.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
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

class MockGetByDateRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

class MockGetDebts extends Mock implements GetDebtsUseCase {}

class MockAddDebt extends Mock implements AddDebtUseCase {}

class MockMakePayment extends Mock implements MakePaymentUseCase {}

class MockDeleteDebt extends Mock implements DeleteDebtUseCase {}

class MockCalculatePayoff extends Mock implements CalculatePayoffUseCase {}

class MockScanReceipt extends Mock implements ScanReceiptUseCase {}

class MockSaveReceipt extends Mock implements SaveReceiptUseCase {}

class MockGetReceipts extends Mock implements GetReceiptsUseCase {}

class MockGetInsights extends Mock implements GetInsightsUseCase {}

class MockAnalyzeSpending extends Mock implements AnalyzeSpendingUseCase {}

class MockGetSavings extends Mock implements GetSavingsSuggestionsUseCase {}

class MockGetSummary extends Mock implements GetDashboardSummaryUseCase {}

class MockGetBreakdown extends Mock implements GetCategoryBreakdownUseCase {}

class MockGetComparison extends Mock implements GetMonthlyComparisonUseCase {}

class MockSyncNow extends Mock implements SyncNowUseCase {}

class MockGetSyncStatus extends Mock implements GetSyncStatusUseCase {}

class MockSignIn extends Mock implements SignInUseCase {}

class MockSignUp extends Mock implements SignUpUseCase {}

class MockSignOut extends Mock implements SignOutUseCase {}

class MockRestoreSession extends Mock implements RestoreSessionUseCase {}

class MockAddBudget extends Mock implements AddBudgetUseCase {}

class MockDeleteBudget extends Mock implements DeleteBudgetUseCase {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgressUseCase {}

class MockGetCategories extends Mock implements GetCategoriesUseCase {}

class MockGetWalletBalances extends Mock implements GetWalletBalancesUseCase {}

class MockSetWalletBalance extends Mock implements SetWalletBalanceUseCase {}

class MockTransferBetweenWallets extends Mock
    implements TransferBetweenWalletsUseCase {}

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

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
  late OcrBloc ocrBloc;
  late AiCoachBloc aiCoachBloc;
  late DashboardBloc dashboardBloc;
  late SyncBloc syncBloc;
  late AuthBloc authBloc;
  late BudgetBloc budgetBloc;
  late WalletBloc walletBloc;
  late CurrencyBloc currencyBloc;

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
    );
    debtBloc = DebtBloc(
      MockGetDebts(),
      MockAddDebt(),
      MockMakePayment(),
      MockDeleteDebt(),
      MockCalculatePayoff(),
    );
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
    );

    final getSummary = MockGetSummary();
    final getBreakdown = MockGetBreakdown();
    final getComparison = MockGetComparison();
    when(() => getSummary(any()))
        .thenAnswer((_) async => const Right(_zeroSummary));
    when(() => getBreakdown(any()))
        .thenAnswer((_) async => const Right(<CategoryBreakdown>[]));
    when(() => getComparison(any()))
        .thenAnswer((_) async => const Right(_zeroComparison));
    when(() => getByRange(any())).thenAnswer(
      (_) async => const Right<Failure, List<TransactionEntity>>([]),
    );

    dashboardBloc = DashboardBloc(
      getSummary,
      getBreakdown,
      getComparison,
      getByRange,
    );

    syncBloc = SyncBloc(MockSyncNow(), MockGetSyncStatus());
    authBloc = AuthBloc(
      MockSignIn(),
      MockSignUp(),
      MockSignOut(),
      MockRestoreSession(),
    );
    budgetBloc = BudgetBloc(
      MockAddBudget(),
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
  });

  Widget buildApp() {
    return FinSightApp(
      themeController: themeController,
      router: router,
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
      ocrBloc: ocrBloc,
      aiCoachBloc: aiCoachBloc,
      dashboardBloc: dashboardBloc,
      syncBloc: syncBloc,
      authBloc: authBloc,
      budgetBloc: budgetBloc,
      walletBloc: walletBloc,
      currencyBloc: currencyBloc,
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
    await tester.pumpWidget(buildApp());
    await tester.pump();
  }

  testWidgets('renders the empty dashboard with quick actions', (tester) async {
    await pumpReady(tester);

    expect(find.text('FinSight AI'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Debts'), findsOneWidget);
    expect(find.text('Scan receipt'), findsOneWidget);
    expect(find.text('AI coach'), findsOneWidget);
  });

  testWidgets('navigates to the transactions feature', (tester) async {
    await pumpReady(tester);

    await tester.tap(find.text('Transactions'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('navigates to the debts feature', (tester) async {
    await pumpReady(tester);

    await tester.tap(find.text('Debts'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Debts'), findsOneWidget);
    expect(find.text('Add debt'), findsOneWidget);
  });

  testWidgets('navigates to OCR and AI coach', (tester) async {
    await pumpReady(tester);

    await tester.tap(find.text('Scan receipt'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Scan receipts'), findsOneWidget);
    expect(find.text('No receipts yet'), findsOneWidget);

    router.goNamed(AppRoutes.dashboardName);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('AI coach'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('AI coach'), findsOneWidget);
    expect(find.text('Your coach is ready'), findsOneWidget);
  });

  testWidgets('toggles between dark and light themes', (tester) async {
    await pumpReady(tester);

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
