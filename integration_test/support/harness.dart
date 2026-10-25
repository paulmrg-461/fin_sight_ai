import 'dart:io';

import 'package:fin_sight_ai/app/app.dart';
import 'package:fin_sight_ai/core/routing/app_router.dart';
import 'package:fin_sight_ai/core/services/app_boxes.dart';
import 'package:fin_sight_ai/core/services/calendar_migration.dart';
import 'package:fin_sight_ai/core/services/local_data_scope.dart';
import 'package:fin_sight_ai/core/services/receipt_image_store.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/hive_currency_repository.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_event.dart';
import 'package:fin_sight_ai/core/locale/hive_locale_repository.dart';
import 'package:fin_sight_ai/core/locale/locale_usecases.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_event.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/features/ai_coach/data/repositories/ai_coach_repository_impl.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/analyze_spending_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fin_sight_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/hive_budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_event.dart';
import 'package:fin_sight_ai/features/categories/data/datasources/hive_category_local_data_source.dart';
import 'package:fin_sight_ai/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fin_sight_ai/features/categories/domain/repositories/category_repository.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_event.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/datasources/hive_scheduled_payment_local_data_source.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_event.dart';
import 'package:fin_sight_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/hive_debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_event.dart';
import 'package:fin_sight_ai/features/receivables/data/datasources/hive_receivable_local_data_source.dart';
import 'package:fin_sight_ai/features/receivables/data/repositories/receivable_repository_impl.dart';
import 'package:fin_sight_ai/features/receivables/domain/repositories/receivable_repository.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/add_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/delete_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/get_receivables_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/make_receivable_payment_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/update_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_bloc.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_event.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/hive_receipt_local_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/repositories/receipt_repository_impl.dart';
import 'package:fin_sight_ai/features/ocr/domain/repositories/receipt_repository.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_event.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/hive_sync_local_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/supabase_rest_sync_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_event.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:fin_sight_ai/features/wallets/data/datasources/hive_wallet_local_data_source.dart';
import 'package:fin_sight_ai/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_event.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'fakes.dart';

/// Builds the production widget graph with real Hive persistence and fake
/// external services (OCR, Groq, image picker).
class IntegrationHarness {
  IntegrationHarness._(this.directory);

  final Directory directory;
  final ThemeController themeController = ThemeController();
  final FakeOcrDataSource ocr = FakeOcrDataSource();
  final FakeGroqDatasource groq = FakeGroqDatasource();
  final FakeReceiptImagePicker imagePicker = FakeReceiptImagePicker();
  final FakeAuthRemoteDataSource authRemote = FakeAuthRemoteDataSource();
  final InMemorySessionStorage authStorage = InMemorySessionStorage();

  late Box<dynamic> _transactionsBox;
  late Box<dynamic> _debtsBox;
  late Box<dynamic> _receivablesBox;
  late Box<dynamic> _receiptsBox;
  late Box<dynamic> _syncQueueBox;
  late Box<dynamic> _syncMetaBox;
  late Box<dynamic> _budgetsBox;
  late Box<dynamic> _walletsBox;
  late Box<dynamic> _walletTransfersBox;
  late Box<dynamic> _settingsBox;
  late Box<dynamic> _categoriesBox;
  late Box<dynamic> _scheduledPaymentsBox;

  late LocalDataScope localDataScope;
  late AuthRepository authRepository;
  late TransactionRepository transactionRepository;
  late DebtRepository debtRepository;
  late ReceivableRepository receivableRepository;
  late ReceiptRepository receiptRepository;
  late CategoryRepository categoryRepository;
  late ScheduledPaymentRepository scheduledPaymentRepository;

  late AddTransactionUseCase addTransaction;
  late GetTransactionsUseCase getTransactions;
  late GetTransactionsByDateRangeUseCase getTransactionsByDateRange;
  late AddDebtUseCase addDebt;
  late AddReceivableUseCase addReceivable;
  late SaveReceiptUseCase saveReceipt;

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
  late GoRouter router;

  static Future<IntegrationHarness> create() async {
    final directory = await Directory.systemTemp.createTemp(
      'finsight_integration_',
    );
    final harness = IntegrationHarness._(directory);
    await harness._openStorage();
    harness._wire();
    await harness._runCalendarMigration();
    return harness;
  }

  Future<void> _openStorage() async {
    Hive.init(directory.path);
    _transactionsBox = await Hive.openBox<dynamic>('transactions');
    _debtsBox = await Hive.openBox<dynamic>('debts');
    _receivablesBox = await Hive.openBox<dynamic>('receivables');
    _receiptsBox = await Hive.openBox<dynamic>('receipts');
    _syncQueueBox = await Hive.openBox<dynamic>('sync_queue');
    _syncMetaBox = await Hive.openBox<dynamic>('sync_meta');
    _budgetsBox = await Hive.openBox<dynamic>('budgets');
    _walletsBox = await Hive.openBox<dynamic>('wallets');
    _walletTransfersBox = await Hive.openBox<dynamic>('wallet_transfers');
    _settingsBox = await Hive.openBox<dynamic>('settings');
    _categoriesBox = await Hive.openBox<dynamic>('categories');
    _scheduledPaymentsBox = await Hive.openBox<dynamic>('scheduled_payments');
  }

  void _wire() {
    final boxes = AppBoxes(
      transactions: _transactionsBox,
      debts: _debtsBox,
      receivables: _receivablesBox,
      receipts: _receiptsBox,
      syncQueue: _syncQueueBox,
      syncMeta: _syncMetaBox,
      budgets: _budgetsBox,
      wallets: _walletsBox,
      walletTransfers: _walletTransfersBox,
      settings: _settingsBox,
      categories: _categoriesBox,
      scheduledPayments: _scheduledPaymentsBox,
    );
    localDataScope = HiveLocalDataScope(boxes);
    final syncLocal = HiveSyncLocalDataSource(_syncQueueBox, _syncMetaBox);

    transactionRepository = TransactionRepositoryImpl(
      HiveTransactionLocalDataSource(_transactionsBox),
      syncQueue: syncLocal,
    );
    debtRepository = DebtRepositoryImpl(
      HiveDebtLocalDataSource(_debtsBox),
      syncQueue: syncLocal,
    );
    receivableRepository = ReceivableRepositoryImpl(
      HiveReceivableLocalDataSource(_receivablesBox),
      syncQueue: syncLocal,
    );
    receiptRepository = ReceiptRepositoryImpl(
      HiveReceiptLocalDataSource(_receiptsBox),
      ocr,
    );
    categoryRepository = CategoryRepositoryImpl(
      HiveCategoryLocalDataSource(_categoriesBox),
      languageCode: 'en',
    );
    scheduledPaymentRepository = ScheduledPaymentRepositoryImpl(
      HiveScheduledPaymentLocalDataSource(_scheduledPaymentsBox),
      transactionRepository,
    );

    addTransaction = AddTransactionUseCase(transactionRepository);
    getTransactions = GetTransactionsUseCase(transactionRepository);
    getTransactionsByDateRange = GetTransactionsByDateRangeUseCase(
      transactionRepository,
    );
    final deleteTransaction = DeleteTransactionUseCase(transactionRepository);

    addDebt = AddDebtUseCase(debtRepository);
    final getDebts = GetDebtsUseCase(debtRepository);
    final makePayment = MakePaymentUseCase(debtRepository);
    final deleteDebt = DeleteDebtUseCase(debtRepository);
    final calculatePayoff = CalculatePayoffUseCase(debtRepository);

    addReceivable = AddReceivableUseCase(receivableRepository);
    final getReceivables = GetReceivablesUseCase(receivableRepository);
    final makeReceivablePayment = MakeReceivablePaymentUseCase(
      receivableRepository,
    );
    final deleteReceivable = DeleteReceivableUseCase(receivableRepository);

    final scanReceipt = ScanReceiptUseCase(receiptRepository);
    saveReceipt = SaveReceiptUseCase(receiptRepository);
    final getReceipts = GetReceiptsUseCase(receiptRepository);

    final aiCoachRepository = AiCoachRepositoryImpl(groq);
    final getInsights = GetInsightsUseCase(aiCoachRepository);
    final analyzeSpending = AnalyzeSpendingUseCase(aiCoachRepository);
    final getSavings = GetSavingsSuggestionsUseCase(aiCoachRepository);

    final dashboardRepository = DashboardRepositoryImpl(transactionRepository);
    final getSummary = GetDashboardSummaryUseCase(dashboardRepository);
    final getBreakdown = GetCategoryBreakdownUseCase(dashboardRepository);
    final getComparison = GetMonthlyComparisonUseCase(dashboardRepository);

    transactionBloc = TransactionBloc(
      getTransactions,
      addTransaction,
      deleteTransaction,
      getTransactionsByDateRange,
    );
    debtBloc = DebtBloc(
      getDebts,
      addDebt,
      makePayment,
      deleteDebt,
      calculatePayoff,
    );
    receivableBloc = ReceivableBloc(
      getReceivables,
      addReceivable,
      UpdateReceivableUseCase(receivableRepository),
      makeReceivablePayment,
      deleteReceivable,
    );
    ocrBloc = OcrBloc(
      scanReceipt,
      saveReceipt,
      getReceipts,
      addTransaction,
      const _FakeReceiptImageStore(),
    );
    aiCoachBloc = AiCoachBloc(
      getInsights,
      analyzeSpending,
      getSavings,
      getTransactions,
    );
    dashboardBloc = DashboardBloc(
      getSummary,
      getBreakdown,
      getComparison,
      getTransactionsByDateRange,
    );

    const appEnv = AppEnv(supabaseUrl: '', supabaseAnonKey: '', groqApiKey: '');
    authRepository = AuthRepositoryImpl(
      authRemote,
      authStorage,
      localDataScope,
    );
    final budgetLocal = HiveBudgetLocalDataSource(_budgetsBox);
    final syncRepository = SyncRepositoryImpl(
      syncLocal,
      SupabaseRestSyncDataSource(http.Client(), appEnv, authRepository),
      HiveTransactionLocalDataSource(_transactionsBox),
      HiveDebtLocalDataSource(_debtsBox),
      budgetLocal,
      HiveReceivableLocalDataSource(_receivablesBox),
      appEnv,
      authRepository,
    );
    syncBloc = SyncBloc(
      SyncNowUseCase(syncRepository),
      GetSyncStatusUseCase(syncRepository),
    );
    authBloc = AuthBloc(
      SignInUseCase(authRepository),
      SignUpUseCase(authRepository),
      SignOutUseCase(authRepository),
      RestoreSessionUseCase(authRepository),
    );

    final budgetRepository = BudgetRepositoryImpl(
      budgetLocal,
      transactionRepository,
      syncQueue: syncLocal,
    );
    budgetBloc = BudgetBloc(
      AddBudgetUseCase(budgetRepository),
      DeleteBudgetUseCase(budgetRepository),
      GetBudgetProgressUseCase(budgetRepository),
      GetCategoriesUseCase(budgetRepository),
    );

    final walletRepository = WalletRepositoryImpl(
      HiveWalletLocalDataSource(_walletsBox, _walletTransfersBox),
      transactionRepository,
    );
    walletBloc = WalletBloc(
      GetWalletBalancesUseCase(walletRepository),
      SetWalletBalanceUseCase(walletRepository),
      TransferBetweenWalletsUseCase(walletRepository),
    );
    final currencyRepository = HiveCurrencyRepository(_settingsBox);
    currencyBloc = CurrencyBloc(
      GetCurrencyUseCase(currencyRepository),
      SetCurrencyUseCase(currencyRepository),
    );
    final localeRepository = HiveLocaleRepository(_settingsBox);
    localeBloc = LocaleBloc(
      GetLocaleUseCase(localeRepository),
      SetLocaleUseCase(localeRepository),
    );
    categoryBloc = CategoryBloc(
      GetCategoryCatalogUseCase(categoryRepository),
      AddCategoryUseCase(categoryRepository),
      RenameCategoryUseCase(
        categoryRepository,
        transactionRepository,
        budgetRepository,
        scheduledPaymentRepository,
      ),
      SetCategoryArchivedUseCase(categoryRepository),
    );
    scheduledPaymentBloc = ScheduledPaymentBloc(
      GetScheduledPaymentsUseCase(scheduledPaymentRepository),
      AddScheduledPaymentUseCase(scheduledPaymentRepository),
      SetScheduledPaymentActiveUseCase(scheduledPaymentRepository),
      DeleteScheduledPaymentUseCase(scheduledPaymentRepository),
      PayScheduledPaymentUseCase(scheduledPaymentRepository),
      ProcessDueScheduledPaymentsUseCase(scheduledPaymentRepository),
    );

    // Mirrors `main.dart`: sign-out reloads the feature blocs so they render
    // the erased boxes instead of stale in-memory data.
    authBloc.stream.listen((state) {
      if (state is AuthUnauthenticated) {
        transactionBloc.add(const LoadTransactions());
        debtBloc.add(const LoadDebts());
        receivableBloc.add(const LoadReceivables());
        ocrBloc.add(const LoadReceipts());
        dashboardBloc.add(const LoadDashboard());
        budgetBloc.add(const LoadBudgets());
        walletBloc.add(const LoadWallets());
        categoryBloc.add(const LoadCategories());
        scheduledPaymentBloc.add(const LoadScheduledPayments());
      }
    });

    router = buildRouter(
      themeController: themeController,
      receiptImagePicker: imagePicker,
    );
  }

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    transactionBloc.add(const LoadTransactions());
    debtBloc.add(const LoadDebts());
    receivableBloc.add(const LoadReceivables());
    ocrBloc.add(const LoadReceipts());
    dashboardBloc.add(const LoadDashboard());
    syncBloc.add(const LoadSyncStatus());
    authBloc.add(const RestoreAuthSession());
    budgetBloc.add(const LoadBudgets());
    walletBloc.add(const LoadWallets());
    currencyBloc.add(const LoadCurrency());
    localeBloc.add(const LoadLocale());
    categoryBloc.add(const LoadCategories());
    scheduledPaymentBloc.add(const LoadScheduledPayments());
    await tester.pump();
  }

  /// Seeds an expired stored session whose next refresh fails as if offline.
  void seedOfflineExpiredSession() {
    final expired = AuthSession(
      accessToken: 'expired-access-token',
      refreshToken: 'expired-refresh-token',
      userId: 'integration-user',
      email: 'user@example.com',
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    authStorage.session = expired;
    authRemote
      ..session = expired
      ..failRefresh = true;
  }

  Future<void> restart() async {
    await _closeBlocs();
    await _transactionsBox.close();
    await _debtsBox.close();
    await _receivablesBox.close();
    await _receiptsBox.close();
    await _syncQueueBox.close();
    await _syncMetaBox.close();
    await _budgetsBox.close();
    await _walletsBox.close();
    await _walletTransfersBox.close();
    await _settingsBox.close();
    await _categoriesBox.close();
    await _scheduledPaymentsBox.close();
    await Hive.close();
    await _openStorage();
    _wire();
    await _runCalendarMigration();
  }

  Future<void> _runCalendarMigration() async {
    await CalendarMigrationService(
      settings: _settingsBox,
      transactionDataSource: HiveTransactionLocalDataSource(_transactionsBox),
      budgetDataSource: HiveBudgetLocalDataSource(_budgetsBox),
      transactionRepository: transactionRepository,
      budgetRepository: BudgetRepositoryImpl(
        HiveBudgetLocalDataSource(_budgetsBox),
        transactionRepository,
      ),
    ).migrate();
  }

  Future<void> _closeBlocs() async {
    await transactionBloc.close();
    await debtBloc.close();
    await receivableBloc.close();
    await ocrBloc.close();
    await aiCoachBloc.close();
    await dashboardBloc.close();
    await syncBloc.close();
    await authBloc.close();
    await budgetBloc.close();
    await walletBloc.close();
    await currencyBloc.close();
    await localeBloc.close();
    await categoryBloc.close();
    await scheduledPaymentBloc.close();
  }

  Future<void> dispose() async {
    await _closeBlocs();
    if (_transactionsBox.isOpen) {
      await _transactionsBox.close();
    }
    if (_debtsBox.isOpen) {
      await _debtsBox.close();
    }
    if (_receivablesBox.isOpen) {
      await _receivablesBox.close();
    }
    if (_receiptsBox.isOpen) {
      await _receiptsBox.close();
    }
    if (_syncQueueBox.isOpen) {
      await _syncQueueBox.close();
    }
    if (_syncMetaBox.isOpen) {
      await _syncMetaBox.close();
    }
    if (_budgetsBox.isOpen) {
      await _budgetsBox.close();
    }
    if (_walletsBox.isOpen) {
      await _walletsBox.close();
    }
    if (_walletTransfersBox.isOpen) {
      await _walletTransfersBox.close();
    }
    if (_settingsBox.isOpen) {
      await _settingsBox.close();
    }
    if (_categoriesBox.isOpen) {
      await _categoriesBox.close();
    }
    if (_scheduledPaymentsBox.isOpen) {
      await _scheduledPaymentsBox.close();
    }
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

/// Pumps frames until [finder] matches or the timeout elapses.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('Timed out waiting for: $finder');
}

/// Pumps frames until [finder] stops matching or the timeout elapses.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  throw TestFailure('Timed out waiting for disappearance of: $finder');
}

class _FakeReceiptImageStore implements ReceiptImageStore {
  const _FakeReceiptImageStore();

  @override
  Future<String> persist(String sourcePath) async => sourcePath;

  @override
  Future<void> delete(String path) async {}
}
