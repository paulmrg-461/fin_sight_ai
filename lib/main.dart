import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/services/app_boxes.dart';
import 'core/services/calendar_migration.dart';
import 'features/debts/presentation/bloc/debt_bloc.dart';
import 'features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
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
import 'features/scheduled_payments/presentation/bloc/scheduled_payment_event.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';
import 'features/debts/presentation/bloc/debt_event.dart';
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

  // Materialize due expenses before the dashboard and wallets read storage.
  final startupPayments = await getIt<ProcessDueScheduledPaymentsUseCase>()(
    const NoParams(),
  );
  final startupAutoCreated = startupPayments.fold(
    (_) => 0,
    (run) => run.createdCount,
  );

  final transactionBloc = getIt<TransactionBloc>()
    ..add(const LoadTransactions());
  final debtBloc = getIt<DebtBloc>()..add(const LoadDebts());
  final ocrBloc = getIt<OcrBloc>()..add(const LoadReceipts());
  final dashboardBloc = getIt<DashboardBloc>()..add(const LoadDashboard());
  final syncBloc = getIt<SyncBloc>();
  final budgetBloc = getIt<BudgetBloc>()..add(const LoadBudgets());
  final walletBloc = getIt<WalletBloc>()..add(const LoadWallets());
  final currencyBloc = getIt<CurrencyBloc>()..add(const LoadCurrency());
  final localeBloc = getIt<LocaleBloc>()..add(const LoadLocale());
  final categoryBloc = getIt<CategoryBloc>()..add(const LoadCategories());
  final scheduledPaymentBloc = getIt<ScheduledPaymentBloc>()
    ..add(LoadScheduledPayments(previousAutoCreated: startupAutoCreated));
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
      ocrBloc.add(const LoadReceipts());
      dashboardBloc.add(const LoadDashboard());
      budgetBloc.add(const LoadBudgets());
      walletBloc.add(const LoadWallets());
      categoryBloc.add(const LoadCategories());
      scheduledPaymentBloc.add(const LoadScheduledPayments());
    }
  });
  syncBloc.add(const SyncNow());

  runApp(
    FinSightApp(
      themeController: getIt(),
      router: getIt(),
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
      ocrBloc: ocrBloc,
      aiCoachBloc: getIt<AiCoachBloc>(),
      dashboardBloc: dashboardBloc,
      syncBloc: syncBloc,
      authBloc: authBloc,
      budgetBloc: budgetBloc,
      walletBloc: walletBloc,
      currencyBloc: currencyBloc,
      localeBloc: localeBloc,
      categoryBloc: categoryBloc,
      scheduledPaymentBloc: scheduledPaymentBloc,
    ),
  );
}
