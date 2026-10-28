import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/startup_loader.dart';
import 'core/di/injection.dart';
import 'core/services/app_boxes.dart';
import 'core/services/calendar_migration.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/reminder_scheduler.dart' show ReminderScheduler;
import 'features/debts/presentation/bloc/debt_bloc.dart';
import 'features/receivables/presentation/bloc/receivable_bloc.dart';
import 'features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'features/ai_coach/presentation/bloc/coach_chat_bloc.dart';
import 'features/auth/data/services/account_scope_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/budgets/data/datasources/budget_local_data_source.dart';
import 'features/budgets/domain/repositories/budget_repository.dart';
import 'features/budgets/presentation/bloc/budget_bloc.dart';
import 'features/budgets/presentation/bloc/budget_event.dart';
import 'features/transactions/data/datasources/transaction_local_data_source.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/wallets/presentation/bloc/wallet_bloc.dart';
import 'features/wallets/presentation/bloc/wallet_event.dart';
import 'core/currency/presentation/bloc/currency_bloc.dart';
import 'core/currency/presentation/bloc/currency_event.dart';
import 'core/locale/presentation/bloc/locale_bloc.dart';
import 'core/locale/presentation/bloc/locale_event.dart';
import 'core/usecase/usecase.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/categories/presentation/bloc/category_event.dart';
import 'features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import 'features/savings/presentation/bloc/savings_bloc.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';
import 'features/import_data/presentation/bloc/import_csv_cubit.dart';
import 'features/security/presentation/bloc/security_cubit.dart';
import 'features/reports/presentation/bloc/reports_event.dart';
import 'features/savings/presentation/bloc/savings_event.dart';
import 'features/scheduled_payments/presentation/bloc/scheduled_payment_event.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';
import 'features/debts/presentation/bloc/debt_event.dart';
import 'features/receivables/presentation/bloc/receivable_event.dart';
import 'features/ocr/presentation/bloc/ocr_bloc.dart';
import 'features/ocr/presentation/bloc/ocr_event.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/sync/presentation/bloc/sync_event.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // Wipe another account's data before any service reads local storage.
  await getIt<AccountScopeService>().ensure();

  // Rewrite pre-plan calendar dates before any BLoC reads local storage.
  await CalendarMigrationService(
    settings: getIt<AppBoxes>().settings,
    transactionDataSource: getIt<TransactionLocalDataSource>(),
    budgetDataSource: getIt<BudgetLocalDataSource>(),
    transactionRepository: getIt<TransactionRepository>(),
    budgetRepository: getIt<BudgetRepository>(),
  ).migrate();

  // Only the dashboard and the UI preferences block the first frame. Feature
  // blocs and due-schedule processing load after it so a large ledger does not
  // delay the dashboard.
  final transactionBloc = getIt<TransactionBloc>();
  final debtBloc = getIt<DebtBloc>();
  final receivableBloc = getIt<ReceivableBloc>();
  final ocrBloc = getIt<OcrBloc>();
  final dashboardBloc = getIt<DashboardBloc>()..add(const LoadDashboard());
  final syncBloc = getIt<SyncBloc>();
  final budgetBloc = getIt<BudgetBloc>();
  final walletBloc = getIt<WalletBloc>();
  final currencyBloc = getIt<CurrencyBloc>()..add(const LoadCurrency());
  final localeBloc = getIt<LocaleBloc>()..add(const LoadLocale());
  final categoryBloc = getIt<CategoryBloc>();
  final scheduledPaymentBloc = getIt<ScheduledPaymentBloc>();
  final savingsBloc = getIt<SavingsBloc>();
  final reportsBloc = getIt<ReportsBloc>();
  final authBloc = getIt<AuthBloc>()..add(const RestoreAuthSession());
  authBloc.stream.listen((state) {
    if (state is AuthAuthenticated) {
      syncBloc.add(const SyncNow());
    }
    if (state is AuthUnauthenticated) {
      // Reads now see the erased boxes, so feature views fall back to their
      // empty states without recreating the blocs.
      transactionBloc.add(const LoadTransactions());
      debtBloc.add(const LoadDebts());
      receivableBloc.add(const LoadReceivables());
      ocrBloc.add(const LoadReceipts());
      dashboardBloc.add(const LoadDashboard());
      budgetBloc.add(const LoadBudgets());
      walletBloc.add(const LoadWallets());
      categoryBloc.add(const LoadCategories());
      savingsBloc.add(const LoadSavingsGoals());
      reportsBloc.add(const LoadReports());
      scheduledPaymentBloc.add(const LoadScheduledPayments());
    }
  });
  runApp(
    FinSightApp(
      themeController: getIt(),
      router: getIt(),
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
      receivableBloc: receivableBloc,
      ocrBloc: ocrBloc,
      aiCoachBloc: getIt<AiCoachBloc>(),
      coachChatBloc: getIt<CoachChatBloc>(),
      dashboardBloc: dashboardBloc,
      syncBloc: syncBloc,
      authBloc: authBloc,
      budgetBloc: budgetBloc,
      walletBloc: walletBloc,
      currencyBloc: currencyBloc,
      localeBloc: localeBloc,
      categoryBloc: categoryBloc,
      scheduledPaymentBloc: scheduledPaymentBloc,
      savingsBloc: savingsBloc,
      reportsBloc: reportsBloc,
      onboardingService: getIt<OnboardingService>(),
      importCsvCubit: getIt<ImportCsvCubit>(),
      securityCubit: getIt<SecurityCubit>(),
    ),
  );

  // Deferred startup: materialize due schedules, then load the remaining
  // screens and the sync queue once the dashboard has painted.
  const StartupLoader().afterFirstFrame([
    () async {
      final stopwatch = Stopwatch()..start();
      await getIt<ReminderScheduler>().initialize();
      final startupPayments = await getIt<ProcessDueScheduledPaymentsUseCase>()(
        const NoParams(),
      );
      final autoCreated = startupPayments.fold(
        (_) => 0,
        (run) => run.createdCount,
      );

      transactionBloc.add(const LoadTransactions());
      debtBloc.add(const LoadDebts());
      receivableBloc.add(const LoadReceivables());
      ocrBloc.add(const LoadReceipts());
      budgetBloc.add(const LoadBudgets());
      walletBloc.add(const LoadWallets());
      categoryBloc.add(const LoadCategories());
      scheduledPaymentBloc.add(
        LoadScheduledPayments(previousAutoCreated: autoCreated),
      );
      syncBloc.add(const SyncNow());
      if (autoCreated > 0) {
        dashboardBloc.add(const RefreshData());
      }
      if (kDebugMode) {
        debugPrint(
          'STARTUP deferred loads scheduled in '
          '${stopwatch.elapsedMilliseconds}ms',
        );
      }
    },
  ]);
}
