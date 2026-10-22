import 'dart:io';

import 'package:fin_sight_ai/core/di/injection.dart';
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
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
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
  });

  test('resolving before configuration throws', () async {
    await getIt.reset();

    expect(() => getIt<ThemeController>(), throwsA(isA<StateError>()));
  });
}
