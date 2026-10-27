// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:fin_sight_ai/core/currency/currency_module.dart' as _i827;
import 'package:fin_sight_ai/core/currency/currency_repository.dart' as _i1029;
import 'package:fin_sight_ai/core/currency/currency_usecases.dart' as _i192;
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart'
    as _i542;
import 'package:fin_sight_ai/core/di/injection.dart' as _i1015;
import 'package:fin_sight_ai/core/locale/locale_module.dart' as _i688;
import 'package:fin_sight_ai/core/locale/locale_repository.dart' as _i385;
import 'package:fin_sight_ai/core/locale/locale_usecases.dart' as _i4;
import 'package:fin_sight_ai/core/locale/presentation/bloc/locale_bloc.dart'
    as _i282;
import 'package:fin_sight_ai/core/services/app_boxes.dart' as _i422;
import 'package:fin_sight_ai/core/services/local_data_scope.dart' as _i1041;
import 'package:fin_sight_ai/core/services/receipt_image_picker.dart' as _i147;
import 'package:fin_sight_ai/core/services/receipt_image_store.dart' as _i666;
import 'package:fin_sight_ai/core/services/reminder_scheduler.dart' as _i244;
import 'package:fin_sight_ai/core/sync/sync_operation.dart' as _i588;
import 'package:fin_sight_ai/core/theme/theme_controller.dart' as _i32;
import 'package:fin_sight_ai/core/utils/app_env.dart' as _i1042;
import 'package:fin_sight_ai/core/utils/clock.dart' as _i956;
import 'package:fin_sight_ai/features/ai_coach/data/datasources/ai_coach_datasource.dart'
    as _i323;
import 'package:fin_sight_ai/features/ai_coach/data/datasources/groq_api_datasource.dart'
    as _i369;
import 'package:fin_sight_ai/features/ai_coach/data/datasources/hive_insight_cache.dart'
    as _i220;
import 'package:fin_sight_ai/features/ai_coach/data/repositories/ai_coach_repository_impl.dart'
    as _i587;
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/ai_coach_repository.dart'
    as _i853;
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/insight_cache.dart'
    as _i802;
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/analyze_spending_usecase.dart'
    as _i177;
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart'
    as _i811;
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart'
    as _i363;
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart'
    as _i872;
import 'package:fin_sight_ai/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i231;
import 'package:fin_sight_ai/features/auth/data/datasources/secure_session_storage.dart'
    as _i26;
import 'package:fin_sight_ai/features/auth/data/datasources/session_storage.dart'
    as _i441;
import 'package:fin_sight_ai/features/auth/data/datasources/supabase_auth_data_source.dart'
    as _i862;
import 'package:fin_sight_ai/features/auth/data/repositories/auth_repository_impl.dart'
    as _i889;
import 'package:fin_sight_ai/features/auth/data/services/account_scope_service.dart'
    as _i754;
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart'
    as _i993;
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart'
    as _i998;
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart'
    as _i661;
import 'package:fin_sight_ai/features/budgets/data/budgets_module.dart'
    as _i950;
import 'package:fin_sight_ai/features/budgets/data/datasources/budget_local_data_source.dart'
    as _i8;
import 'package:fin_sight_ai/features/budgets/data/repositories/budget_repository_impl.dart'
    as _i545;
import 'package:fin_sight_ai/features/budgets/domain/repositories/budget_repository.dart'
    as _i575;
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart'
    as _i41;
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart'
    as _i746;
import 'package:fin_sight_ai/features/categories/data/categories_module.dart'
    as _i873;
import 'package:fin_sight_ai/features/categories/data/datasources/category_local_data_source.dart'
    as _i65;
import 'package:fin_sight_ai/features/categories/domain/repositories/category_repository.dart'
    as _i888;
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart'
    as _i195;
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart'
    as _i968;
import 'package:fin_sight_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart'
    as _i366;
import 'package:fin_sight_ai/features/dashboard/domain/repositories/dashboard_repository.dart'
    as _i864;
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart'
    as _i905;
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i850;
import 'package:fin_sight_ai/features/debts/data/datasources/debt_local_data_source.dart'
    as _i1035;
import 'package:fin_sight_ai/features/debts/data/repositories/debt_repository_impl.dart'
    as _i140;
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart'
    as _i268;
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart'
    as _i144;
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart'
    as _i1045;
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart'
    as _i24;
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart'
    as _i243;
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart'
    as _i978;
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart'
    as _i1009;
import 'package:fin_sight_ai/features/ocr/data/datasources/mlkit_ocr_data_source.dart'
    as _i598;
import 'package:fin_sight_ai/features/ocr/data/datasources/ocr_data_source.dart'
    as _i880;
import 'package:fin_sight_ai/features/ocr/data/datasources/receipt_local_data_source.dart'
    as _i783;
import 'package:fin_sight_ai/features/ocr/data/ocr_module.dart' as _i600;
import 'package:fin_sight_ai/features/ocr/data/repositories/receipt_repository_impl.dart'
    as _i367;
import 'package:fin_sight_ai/features/ocr/domain/repositories/receipt_repository.dart'
    as _i832;
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart'
    as _i937;
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart'
    as _i292;
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart'
    as _i826;
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_bloc.dart'
    as _i1031;
import 'package:fin_sight_ai/features/receivables/data/datasources/receivable_local_data_source.dart'
    as _i315;
import 'package:fin_sight_ai/features/receivables/data/repositories/receivable_repository_impl.dart'
    as _i908;
import 'package:fin_sight_ai/features/receivables/domain/repositories/receivable_repository.dart'
    as _i554;
import 'package:fin_sight_ai/features/receivables/domain/usecases/add_receivable_usecase.dart'
    as _i734;
import 'package:fin_sight_ai/features/receivables/domain/usecases/delete_receivable_usecase.dart'
    as _i279;
import 'package:fin_sight_ai/features/receivables/domain/usecases/get_receivables_usecase.dart'
    as _i728;
import 'package:fin_sight_ai/features/receivables/domain/usecases/make_receivable_payment_usecase.dart'
    as _i946;
import 'package:fin_sight_ai/features/receivables/domain/usecases/update_receivable_usecase.dart'
    as _i642;
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_bloc.dart'
    as _i9;
import 'package:fin_sight_ai/features/scheduled_payments/data/datasources/scheduled_payment_local_data_source.dart'
    as _i462;
import 'package:fin_sight_ai/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart'
    as _i403;
import 'package:fin_sight_ai/features/scheduled_payments/data/scheduled_payments_module.dart'
    as _i942;
import 'package:fin_sight_ai/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart'
    as _i312;
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/committed_cashflow_usecase.dart'
    as _i387;
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart'
    as _i160;
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart'
    as _i200;
import 'package:fin_sight_ai/features/sync/data/datasources/supabase_rest_sync_data_source.dart'
    as _i995;
import 'package:fin_sight_ai/features/sync/data/datasources/sync_local_data_source.dart'
    as _i921;
import 'package:fin_sight_ai/features/sync/data/datasources/sync_remote_data_source.dart'
    as _i984;
import 'package:fin_sight_ai/features/sync/data/repositories/sync_repository_impl.dart'
    as _i1020;
import 'package:fin_sight_ai/features/sync/data/sync_module.dart' as _i273;
import 'package:fin_sight_ai/features/sync/domain/repositories/sync_repository.dart'
    as _i272;
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart'
    as _i558;
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart'
    as _i470;
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart'
    as _i228;
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart'
    as _i529;
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart'
    as _i544;
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart'
    as _i361;
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart'
    as _i69;
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart'
    as _i271;
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart'
    as _i1051;
import 'package:fin_sight_ai/features/transactions/domain/usecases/update_transaction_usecase.dart'
    as _i913;
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart'
    as _i820;
import 'package:fin_sight_ai/features/wallets/data/datasources/wallet_local_data_source.dart'
    as _i261;
import 'package:fin_sight_ai/features/wallets/data/repositories/wallet_repository_impl.dart'
    as _i532;
import 'package:fin_sight_ai/features/wallets/data/wallets_module.dart'
    as _i326;
import 'package:fin_sight_ai/features/wallets/domain/repositories/wallet_repository.dart'
    as _i305;
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart'
    as _i1013;
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart'
    as _i163;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final storageModule = _$StorageModule();
    final reminderModule = _$ReminderModule();
    final coreModule = _$CoreModule();
    final currencyModule = _$CurrencyModule();
    final localDataModule = _$LocalDataModule();
    final transactionsModule = _$TransactionsModule();
    final debtsModule = _$DebtsModule();
    final receivablesModule = _$ReceivablesModule();
    final localeModule = _$LocaleModule();
    final budgetsModule = _$BudgetsModule();
    final categoriesModule = _$CategoriesModule();
    final ocrModule = _$OcrModule();
    final scheduledPaymentsModule = _$ScheduledPaymentsModule();
    final syncModule = _$SyncModule();
    final walletsModule = _$WalletsModule();
    final routingModule = _$RoutingModule();
    await gh.factoryAsync<_i422.AppBoxes>(
      () => storageModule.provideAppBoxes(),
      preResolve: true,
    );
    gh.lazySingleton<_i244.ReminderScheduler>(
      () => reminderModule.provideReminderScheduler(),
    );
    gh.lazySingleton<_i706.Uuid>(() => coreModule.provideUuid());
    gh.lazySingleton<_i1042.AppEnv>(() => coreModule.provideAppEnv());
    gh.lazySingleton<_i519.Client>(() => coreModule.provideHttpClient());
    gh.lazySingleton<_i32.ThemeController>(() => _i32.ThemeController());
    gh.lazySingleton<_i956.Clock>(() => const _i956.Clock());
    gh.lazySingleton<_i880.OcrDataSource>(
      () => const _i598.MlKitOcrDataSource(),
    );
    gh.lazySingleton<_i802.InsightCache>(
      () => _i220.HiveInsightCache(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i441.SessionStorage>(() => _i26.SecureSessionStorage());
    gh.lazySingleton<_i666.ReceiptImageStore>(
      () => _i666.FileReceiptImageStore(),
    );
    gh.lazySingleton<_i147.ReceiptImagePicker>(
      () => _i147.ImagePickerReceiptImagePicker(),
    );
    gh.lazySingleton<_i231.AuthRemoteDataSource>(
      () =>
          _i862.SupabaseAuthDataSource(gh<_i519.Client>(), gh<_i1042.AppEnv>()),
    );
    gh.lazySingleton<_i323.AiCoachDatasource>(
      () => _i369.GroqApiDatasource(gh<_i519.Client>(), gh<_i1042.AppEnv>()),
    );
    gh.lazySingleton<_i1029.CurrencyRepository>(
      () => currencyModule.provideCurrencyRepository(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i1041.LocalDataScope>(
      () => localDataModule.provideLocalDataScope(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i228.TransactionLocalDataSource>(
      () => transactionsModule.provideTransactionLocalDataSource(
        gh<_i422.AppBoxes>(),
      ),
    );
    gh.lazySingleton<_i1035.DebtLocalDataSource>(
      () => debtsModule.provideDebtLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i315.ReceivableLocalDataSource>(
      () => receivablesModule.provideReceivableLocalDataSource(
        gh<_i422.AppBoxes>(),
      ),
    );
    gh.lazySingleton<_i385.LocaleRepository>(
      () => localeModule.provideLocaleRepository(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i8.BudgetLocalDataSource>(
      () => budgetsModule.provideBudgetLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i65.CategoryLocalDataSource>(
      () =>
          categoriesModule.provideCategoryLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i783.ReceiptLocalDataSource>(
      () => ocrModule.provideReceiptLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i462.ScheduledPaymentLocalDataSource>(
      () => scheduledPaymentsModule.provideScheduledPaymentLocalDataSource(
        gh<_i422.AppBoxes>(),
      ),
    );
    gh.lazySingleton<_i921.SyncLocalDataSource>(
      () => syncModule.provideSyncLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i261.WalletLocalDataSource>(
      () => walletsModule.provideWalletLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => routingModule.provideGoRouter(
        gh<_i32.ThemeController>(),
        gh<_i147.ReceiptImagePicker>(),
      ),
    );
    gh.lazySingleton<_i853.AiCoachRepository>(
      () => _i587.AiCoachRepositoryImpl(
        gh<_i323.AiCoachDatasource>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i4.GetLocaleUseCase>(
      () => _i4.GetLocaleUseCase(gh<_i385.LocaleRepository>()),
    );
    gh.lazySingleton<_i4.SetLocaleUseCase>(
      () => _i4.SetLocaleUseCase(gh<_i385.LocaleRepository>()),
    );
    gh.lazySingleton<_i177.AnalyzeSpendingUseCase>(
      () => _i177.AnalyzeSpendingUseCase(gh<_i853.AiCoachRepository>()),
    );
    gh.lazySingleton<_i811.GetInsightsUseCase>(
      () => _i811.GetInsightsUseCase(gh<_i853.AiCoachRepository>()),
    );
    gh.lazySingleton<_i363.GetSavingsSuggestionsUseCase>(
      () => _i363.GetSavingsSuggestionsUseCase(gh<_i853.AiCoachRepository>()),
    );
    gh.lazySingleton<_i544.TransactionRepository>(
      () => _i529.TransactionRepositoryImpl(
        gh<_i228.TransactionLocalDataSource>(),
        syncQueue: gh<_i588.SyncQueue>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i754.AccountScopeService>(
      () => _i754.AccountScopeService(
        gh<_i441.SessionStorage>(),
        gh<_i1041.LocalDataScope>(),
      ),
    );
    gh.lazySingleton<_i993.AuthRepository>(
      () => _i889.AuthRepositoryImpl(
        gh<_i231.AuthRemoteDataSource>(),
        gh<_i441.SessionStorage>(),
        gh<_i1041.LocalDataScope>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i305.WalletRepository>(
      () => _i532.WalletRepositoryImpl(
        gh<_i261.WalletLocalDataSource>(),
        gh<_i544.TransactionRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
        syncQueue: gh<_i588.SyncQueue>(),
      ),
    );
    gh.factory<_i282.LocaleBloc>(
      () => _i282.LocaleBloc(
        gh<_i4.GetLocaleUseCase>(),
        gh<_i4.SetLocaleUseCase>(),
      ),
    );
    gh.lazySingleton<_i575.BudgetRepository>(
      () => _i545.BudgetRepositoryImpl(
        gh<_i8.BudgetLocalDataSource>(),
        gh<_i544.TransactionRepository>(),
        syncQueue: gh<_i588.SyncQueue>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i588.SyncQueue>(
      () => syncModule.provideSyncQueue(gh<_i921.SyncLocalDataSource>()),
    );
    gh.lazySingleton<_i41.UpdateBudgetUseCase>(
      () => _i41.UpdateBudgetUseCase(gh<_i575.BudgetRepository>()),
    );
    gh.lazySingleton<_i41.DeleteBudgetUseCase>(
      () => _i41.DeleteBudgetUseCase(gh<_i575.BudgetRepository>()),
    );
    gh.lazySingleton<_i41.GetBudgetProgressUseCase>(
      () => _i41.GetBudgetProgressUseCase(gh<_i575.BudgetRepository>()),
    );
    gh.lazySingleton<_i41.GetCategoriesUseCase>(
      () => _i41.GetCategoriesUseCase(gh<_i575.BudgetRepository>()),
    );
    gh.lazySingleton<_i1013.GetWalletBalancesUseCase>(
      () => _i1013.GetWalletBalancesUseCase(gh<_i305.WalletRepository>()),
    );
    gh.lazySingleton<_i1013.SetWalletBalanceUseCase>(
      () => _i1013.SetWalletBalanceUseCase(gh<_i305.WalletRepository>()),
    );
    gh.lazySingleton<_i41.AddBudgetUseCase>(
      () => _i41.AddBudgetUseCase(
        gh<_i575.BudgetRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i888.CategoryRepository>(
      () => categoriesModule.provideCategoryRepository(
        gh<_i65.CategoryLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i1013.TransferBetweenWalletsUseCase>(
      () => _i1013.TransferBetweenWalletsUseCase(
        gh<_i305.WalletRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i192.GetCurrencyUseCase>(
      () => _i192.GetCurrencyUseCase(gh<_i1029.CurrencyRepository>()),
    );
    gh.lazySingleton<_i192.SetCurrencyUseCase>(
      () => _i192.SetCurrencyUseCase(gh<_i1029.CurrencyRepository>()),
    );
    gh.lazySingleton<_i268.DebtRepository>(
      () => _i140.DebtRepositoryImpl(
        gh<_i1035.DebtLocalDataSource>(),
        syncQueue: gh<_i588.SyncQueue>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i864.DashboardRepository>(
      () => _i366.DashboardRepositoryImpl(gh<_i544.TransactionRepository>()),
    );
    gh.lazySingleton<_i832.ReceiptRepository>(
      () => _i367.ReceiptRepositoryImpl(
        gh<_i783.ReceiptLocalDataSource>(),
        gh<_i880.OcrDataSource>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i69.DeleteTransactionUseCase>(
      () => _i69.DeleteTransactionUseCase(gh<_i544.TransactionRepository>()),
    );
    gh.lazySingleton<_i271.GetTransactionsByDateRangeUseCase>(
      () => _i271.GetTransactionsByDateRangeUseCase(
        gh<_i544.TransactionRepository>(),
      ),
    );
    gh.lazySingleton<_i1051.GetTransactionsUseCase>(
      () => _i1051.GetTransactionsUseCase(gh<_i544.TransactionRepository>()),
    );
    gh.lazySingleton<_i913.UpdateTransactionUseCase>(
      () => _i913.UpdateTransactionUseCase(gh<_i544.TransactionRepository>()),
    );
    gh.lazySingleton<_i905.GetDashboardDataUseCase>(
      () => _i905.GetDashboardDataUseCase(gh<_i864.DashboardRepository>()),
    );
    gh.lazySingleton<_i361.AddTransactionUseCase>(
      () => _i361.AddTransactionUseCase(
        gh<_i544.TransactionRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i554.ReceivableRepository>(
      () => _i908.ReceivableRepositoryImpl(
        gh<_i315.ReceivableLocalDataSource>(),
        syncQueue: gh<_i588.SyncQueue>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i978.MakePaymentUseCase>(
      () => _i978.MakePaymentUseCase(
        gh<_i268.DebtRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i734.AddReceivableUseCase>(
      () => _i734.AddReceivableUseCase(
        gh<_i554.ReceivableRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i946.MakeReceivablePaymentUseCase>(
      () => _i946.MakeReceivablePaymentUseCase(
        gh<_i554.ReceivableRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.factory<_i746.BudgetBloc>(
      () => _i746.BudgetBloc(
        gh<_i41.AddBudgetUseCase>(),
        gh<_i41.UpdateBudgetUseCase>(),
        gh<_i41.DeleteBudgetUseCase>(),
        gh<_i41.GetBudgetProgressUseCase>(),
        gh<_i41.GetCategoriesUseCase>(),
      ),
    );
    gh.lazySingleton<_i312.ScheduledPaymentRepository>(
      () => _i403.ScheduledPaymentRepositoryImpl(
        gh<_i462.ScheduledPaymentLocalDataSource>(),
        gh<_i544.TransactionRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
        syncQueue: gh<_i588.SyncQueue>(),
      ),
    );
    gh.lazySingleton<_i195.RenameCategoryUseCase>(
      () => _i195.RenameCategoryUseCase(
        gh<_i888.CategoryRepository>(),
        gh<_i544.TransactionRepository>(),
        gh<_i575.BudgetRepository>(),
        gh<_i312.ScheduledPaymentRepository>(),
      ),
    );
    gh.factory<_i542.CurrencyBloc>(
      () => _i542.CurrencyBloc(
        gh<_i192.GetCurrencyUseCase>(),
        gh<_i192.SetCurrencyUseCase>(),
      ),
    );
    gh.lazySingleton<_i998.SignInUseCase>(
      () => _i998.SignInUseCase(gh<_i993.AuthRepository>()),
    );
    gh.lazySingleton<_i998.SignUpUseCase>(
      () => _i998.SignUpUseCase(gh<_i993.AuthRepository>()),
    );
    gh.lazySingleton<_i998.RestoreSessionUseCase>(
      () => _i998.RestoreSessionUseCase(gh<_i993.AuthRepository>()),
    );
    gh.lazySingleton<_i998.SignOutUseCase>(
      () => _i998.SignOutUseCase(gh<_i993.AuthRepository>()),
    );
    gh.lazySingleton<_i984.SyncRemoteDataSource>(
      () => _i995.SupabaseRestSyncDataSource(
        gh<_i519.Client>(),
        gh<_i1042.AppEnv>(),
        gh<_i993.AuthRepository>(),
      ),
    );
    gh.factory<_i820.TransactionBloc>(
      () => _i820.TransactionBloc(
        gh<_i1051.GetTransactionsUseCase>(),
        gh<_i361.AddTransactionUseCase>(),
        gh<_i69.DeleteTransactionUseCase>(),
        gh<_i271.GetTransactionsByDateRangeUseCase>(),
        gh<_i913.UpdateTransactionUseCase>(),
      ),
    );
    gh.lazySingleton<_i144.AddDebtUseCase>(
      () => _i144.AddDebtUseCase(
        gh<_i268.DebtRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i160.UpdateScheduledPaymentUseCase>(
      () => _i160.UpdateScheduledPaymentUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i160.PayScheduledPaymentUseCase>(
      () => _i160.PayScheduledPaymentUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i160.ProcessDueScheduledPaymentsUseCase>(
      () => _i160.ProcessDueScheduledPaymentsUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i272.SyncRepository>(
      () => _i1020.SyncRepositoryImpl(
        gh<_i921.SyncLocalDataSource>(),
        gh<_i984.SyncRemoteDataSource>(),
        gh<_i228.TransactionLocalDataSource>(),
        gh<_i1035.DebtLocalDataSource>(),
        gh<_i8.BudgetLocalDataSource>(),
        gh<_i315.ReceivableLocalDataSource>(),
        gh<_i65.CategoryLocalDataSource>(),
        gh<_i462.ScheduledPaymentLocalDataSource>(),
        gh<_i261.WalletLocalDataSource>(),
        gh<_i1042.AppEnv>(),
        gh<_i993.AuthRepository>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.factory<_i163.WalletBloc>(
      () => _i163.WalletBloc(
        gh<_i1013.GetWalletBalancesUseCase>(),
        gh<_i1013.SetWalletBalanceUseCase>(),
        gh<_i1013.TransferBetweenWalletsUseCase>(),
      ),
    );
    gh.lazySingleton<_i387.GetCommittedCashflowUseCase>(
      () => _i387.GetCommittedCashflowUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
        gh<_i268.DebtRepository>(),
      ),
    );
    gh.lazySingleton<_i642.UpdateReceivableUseCase>(
      () => _i642.UpdateReceivableUseCase(
        gh<_i554.ReceivableRepository>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i279.DeleteReceivableUseCase>(
      () => _i279.DeleteReceivableUseCase(gh<_i554.ReceivableRepository>()),
    );
    gh.lazySingleton<_i728.GetReceivablesUseCase>(
      () => _i728.GetReceivablesUseCase(gh<_i554.ReceivableRepository>()),
    );
    gh.lazySingleton<_i1045.CalculatePayoffUseCase>(
      () => _i1045.CalculatePayoffUseCase(gh<_i268.DebtRepository>()),
    );
    gh.lazySingleton<_i24.DeleteDebtUseCase>(
      () => _i24.DeleteDebtUseCase(gh<_i268.DebtRepository>()),
    );
    gh.lazySingleton<_i243.GetDebtsUseCase>(
      () => _i243.GetDebtsUseCase(gh<_i268.DebtRepository>()),
    );
    gh.lazySingleton<_i558.SyncNowUseCase>(
      () => _i558.SyncNowUseCase(gh<_i272.SyncRepository>()),
    );
    gh.lazySingleton<_i558.GetSyncStatusUseCase>(
      () => _i558.GetSyncStatusUseCase(gh<_i272.SyncRepository>()),
    );
    gh.lazySingleton<_i195.GetCategoryCatalogUseCase>(
      () => _i195.GetCategoryCatalogUseCase(gh<_i888.CategoryRepository>()),
    );
    gh.lazySingleton<_i195.AddCategoryUseCase>(
      () => _i195.AddCategoryUseCase(gh<_i888.CategoryRepository>()),
    );
    gh.lazySingleton<_i195.SetCategoryArchivedUseCase>(
      () => _i195.SetCategoryArchivedUseCase(gh<_i888.CategoryRepository>()),
    );
    gh.lazySingleton<_i937.GetReceiptsUseCase>(
      () => _i937.GetReceiptsUseCase(gh<_i832.ReceiptRepository>()),
    );
    gh.lazySingleton<_i826.ScanReceiptUseCase>(
      () => _i826.ScanReceiptUseCase(gh<_i832.ReceiptRepository>()),
    );
    gh.lazySingleton<_i160.GetScheduledPaymentsUseCase>(
      () => _i160.GetScheduledPaymentsUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
      ),
    );
    gh.lazySingleton<_i160.SetScheduledPaymentActiveUseCase>(
      () => _i160.SetScheduledPaymentActiveUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
      ),
    );
    gh.lazySingleton<_i160.DeleteScheduledPaymentUseCase>(
      () => _i160.DeleteScheduledPaymentUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
      ),
    );
    gh.factory<_i661.AuthBloc>(
      () => _i661.AuthBloc(
        gh<_i998.SignInUseCase>(),
        gh<_i998.SignUpUseCase>(),
        gh<_i998.SignOutUseCase>(),
        gh<_i998.RestoreSessionUseCase>(),
      ),
    );
    gh.factory<_i872.AiCoachBloc>(
      () => _i872.AiCoachBloc(
        gh<_i811.GetInsightsUseCase>(),
        gh<_i177.AnalyzeSpendingUseCase>(),
        gh<_i363.GetSavingsSuggestionsUseCase>(),
        gh<_i1051.GetTransactionsUseCase>(),
        gh<_i243.GetDebtsUseCase>(),
        gh<_i802.InsightCache>(),
      ),
    );
    gh.factory<_i1009.DebtBloc>(
      () => _i1009.DebtBloc(
        gh<_i243.GetDebtsUseCase>(),
        gh<_i144.AddDebtUseCase>(),
        gh<_i978.MakePaymentUseCase>(),
        gh<_i24.DeleteDebtUseCase>(),
        gh<_i1045.CalculatePayoffUseCase>(),
      ),
    );
    gh.factory<_i850.DashboardBloc>(
      () => _i850.DashboardBloc(
        gh<_i905.GetDashboardDataUseCase>(),
        gh<_i387.GetCommittedCashflowUseCase>(),
      ),
    );
    gh.lazySingleton<_i160.AddScheduledPaymentUseCase>(
      () => _i160.AddScheduledPaymentUseCase(
        gh<_i312.ScheduledPaymentRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.factory<_i968.CategoryBloc>(
      () => _i968.CategoryBloc(
        gh<_i195.GetCategoryCatalogUseCase>(),
        gh<_i195.AddCategoryUseCase>(),
        gh<_i195.RenameCategoryUseCase>(),
        gh<_i195.SetCategoryArchivedUseCase>(),
      ),
    );
    gh.lazySingleton<_i292.SaveReceiptUseCase>(
      () => _i292.SaveReceiptUseCase(
        gh<_i832.ReceiptRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.factory<_i9.ReceivableBloc>(
      () => _i9.ReceivableBloc(
        gh<_i728.GetReceivablesUseCase>(),
        gh<_i734.AddReceivableUseCase>(),
        gh<_i642.UpdateReceivableUseCase>(),
        gh<_i946.MakeReceivablePaymentUseCase>(),
        gh<_i279.DeleteReceivableUseCase>(),
      ),
    );
    gh.factory<_i470.SyncBloc>(
      () => _i470.SyncBloc(
        gh<_i558.SyncNowUseCase>(),
        gh<_i558.GetSyncStatusUseCase>(),
      ),
    );
    gh.factory<_i200.ScheduledPaymentBloc>(
      () => _i200.ScheduledPaymentBloc(
        gh<_i160.GetScheduledPaymentsUseCase>(),
        gh<_i160.AddScheduledPaymentUseCase>(),
        gh<_i160.UpdateScheduledPaymentUseCase>(),
        gh<_i160.SetScheduledPaymentActiveUseCase>(),
        gh<_i160.DeleteScheduledPaymentUseCase>(),
        gh<_i160.PayScheduledPaymentUseCase>(),
        gh<_i160.ProcessDueScheduledPaymentsUseCase>(),
        gh<_i387.GetCommittedCashflowUseCase>(),
        gh<_i244.ReminderScheduler>(),
      ),
    );
    gh.factory<_i1031.OcrBloc>(
      () => _i1031.OcrBloc(
        gh<_i826.ScanReceiptUseCase>(),
        gh<_i292.SaveReceiptUseCase>(),
        gh<_i937.GetReceiptsUseCase>(),
        gh<_i361.AddTransactionUseCase>(),
        gh<_i666.ReceiptImageStore>(),
      ),
    );
    return this;
  }
}

class _$StorageModule extends _i1015.StorageModule {}

class _$ReminderModule extends _i1015.ReminderModule {}

class _$CoreModule extends _i1015.CoreModule {}

class _$CurrencyModule extends _i827.CurrencyModule {}

class _$LocalDataModule extends _i1015.LocalDataModule {}

class _$TransactionsModule extends _i1015.TransactionsModule {}

class _$DebtsModule extends _i1015.DebtsModule {}

class _$ReceivablesModule extends _i1015.ReceivablesModule {}

class _$LocaleModule extends _i688.LocaleModule {}

class _$BudgetsModule extends _i950.BudgetsModule {}

class _$CategoriesModule extends _i873.CategoriesModule {}

class _$OcrModule extends _i600.OcrModule {}

class _$ScheduledPaymentsModule extends _i942.ScheduledPaymentsModule {}

class _$SyncModule extends _i273.SyncModule {}

class _$WalletsModule extends _i326.WalletsModule {}

class _$RoutingModule extends _i1015.RoutingModule {}
