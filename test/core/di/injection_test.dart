import 'dart:io';

import 'package:fin_sight_ai/core/di/injection.dart';
import 'package:fin_sight_ai/core/currency/currency_repository.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/hive_currency_repository.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/services/receipt_image_picker.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/hive_debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/ai_coach_datasource.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/groq_api_datasource.dart';
import 'package:fin_sight_ai/features/ai_coach/data/repositories/ai_coach_repository_impl.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/ai_coach_repository.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/secure_session_storage.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/session_storage.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:fin_sight_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/hive_budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fin_sight_ai/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fin_sight_ai/features/budgets/domain/usecases/budget_usecases.dart';
import 'package:fin_sight_ai/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:fin_sight_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fin_sight_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/hive_receipt_local_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/ocr_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/receipt_local_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/repositories/receipt_repository_impl.dart';
import 'package:fin_sight_ai/features/ocr/domain/repositories/receipt_repository.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/hive_sync_local_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/sync_local_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/sync_remote_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/supabase_rest_sync_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:fin_sight_ai/features/sync/domain/repositories/sync_repository.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:fin_sight_ai/features/wallets/data/datasources/hive_wallet_local_data_source.dart';
import 'package:fin_sight_ai/features/wallets/data/datasources/wallet_local_data_source.dart';
import 'package:fin_sight_ai/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:fin_sight_ai/features/wallets/domain/repositories/wallet_repository.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_di_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      tempDirectory.path,
    );
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL=https://demo.supabase.co
SUPABASE_ANON_KEY=anon-key
GROQ_API_KEY=groq-key
''',
    );
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('resolves the complete dependency graph', () async {
    await configureDependencies();

    expect(getIt<AppEnv>().supabaseUrl, 'https://demo.supabase.co');
    expect(getIt<AppEnv>().hasGroq, isTrue);
    expect(getIt<Clock>(), isA<Clock>());

    expect(
      getIt<TransactionLocalDataSource>(),
      isA<HiveTransactionLocalDataSource>(),
    );
    expect(getIt<DebtLocalDataSource>(), isA<HiveDebtLocalDataSource>());
    expect(getIt<TransactionRepository>(), isA<TransactionRepositoryImpl>());
    expect(getIt<DebtRepository>(), isA<DebtRepositoryImpl>());

    expect(getIt<GetTransactionsUseCase>(), isNotNull);
    expect(getIt<AddTransactionUseCase>(), isNotNull);
    expect(getIt<DeleteTransactionUseCase>(), isNotNull);
    expect(getIt<GetTransactionsByDateRangeUseCase>(), isNotNull);
    expect(getIt<GetDebtsUseCase>(), isNotNull);
    expect(getIt<AddDebtUseCase>(), isNotNull);
    expect(getIt<MakePaymentUseCase>(), isNotNull);
    expect(getIt<DeleteDebtUseCase>(), isNotNull);
    expect(getIt<CalculatePayoffUseCase>(), isNotNull);

    expect(getIt<TransactionBloc>(), isA<TransactionBloc>());
    expect(getIt<DebtBloc>(), isA<DebtBloc>());
    expect(getIt<ThemeController>(), isA<ThemeController>());
    expect(getIt<GoRouter>(), isA<GoRouter>());
    expect(getIt<http.Client>(), isA<http.Client>());
    expect(getIt<ReceiptImagePicker>(), isA<ReceiptImagePicker>());

    expect(getIt<ReceiptLocalDataSource>(), isA<HiveReceiptLocalDataSource>());
    expect(getIt<OcrDataSource>(), isNotNull);
    expect(getIt<ReceiptRepository>(), isA<ReceiptRepositoryImpl>());
    expect(getIt<ScanReceiptUseCase>(), isNotNull);
    expect(getIt<SaveReceiptUseCase>(), isNotNull);
    expect(getIt<GetReceiptsUseCase>(), isNotNull);
    expect(getIt<OcrBloc>(), isA<OcrBloc>());

    expect(getIt<AiCoachDatasource>(), isA<GroqApiDatasource>());
    expect(getIt<AiCoachRepository>(), isA<AiCoachRepositoryImpl>());
    expect(getIt<AiCoachBloc>(), isA<AiCoachBloc>());

    expect(getIt<DashboardRepository>(), isA<DashboardRepositoryImpl>());
    expect(getIt<DashboardBloc>(), isA<DashboardBloc>());

    expect(getIt<SyncLocalDataSource>(), isA<HiveSyncLocalDataSource>());
    expect(getIt<SyncQueue>(), getIt<SyncLocalDataSource>());
    expect(getIt<SyncRemoteDataSource>(), isA<SupabaseRestSyncDataSource>());
    expect(getIt<SyncRepository>(), isA<SyncRepositoryImpl>());
    expect(getIt<SyncNowUseCase>(), isNotNull);
    expect(getIt<GetSyncStatusUseCase>(), isNotNull);
    expect(getIt<SyncBloc>(), isA<SyncBloc>());

    expect(getIt<SessionStorage>(), isA<SecureSessionStorage>());
    expect(getIt<AuthRemoteDataSource>(), isA<SupabaseAuthDataSource>());
    expect(getIt<AuthRepository>(), isA<AuthRepositoryImpl>());
    expect(getIt<SignInUseCase>(), isNotNull);
    expect(getIt<SignUpUseCase>(), isNotNull);
    expect(getIt<SignOutUseCase>(), isNotNull);
    expect(getIt<RestoreSessionUseCase>(), isNotNull);
    expect(getIt<AuthBloc>(), isA<AuthBloc>());

    expect(getIt<BudgetLocalDataSource>(), isA<HiveBudgetLocalDataSource>());
    expect(getIt<BudgetRepository>(), isA<BudgetRepositoryImpl>());
    expect(getIt<AddBudgetUseCase>(), isNotNull);
    expect(getIt<DeleteBudgetUseCase>(), isNotNull);
    expect(getIt<GetBudgetProgressUseCase>(), isNotNull);
    expect(getIt<GetCategoriesUseCase>(), isNotNull);
    expect(getIt<BudgetBloc>(), isA<BudgetBloc>());
    expect(getIt<CurrencyRepository>(), isA<HiveCurrencyRepository>());
    expect(getIt<GetCurrencyUseCase>(), isNotNull);
    expect(getIt<SetCurrencyUseCase>(), isNotNull);
    expect(getIt<CurrencyBloc>(), isA<CurrencyBloc>());

    expect(getIt<WalletLocalDataSource>(), isA<HiveWalletLocalDataSource>());
    expect(getIt<WalletRepository>(), isA<WalletRepositoryImpl>());
    expect(getIt<GetWalletBalancesUseCase>(), isNotNull);
    expect(getIt<SetWalletBalanceUseCase>(), isNotNull);
    expect(getIt<TransferBetweenWalletsUseCase>(), isNotNull);
    expect(getIt<WalletBloc>(), isA<WalletBloc>());
  });

  test('resolving before configuration throws', () async {
    await getIt.reset();

    expect(() => getIt<ThemeController>(), throwsA(isA<StateError>()));
  });
}
