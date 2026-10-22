// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:fin_sight_ai/core/di/injection.dart' as _i1015;
import 'package:fin_sight_ai/core/services/app_boxes.dart' as _i422;
import 'package:fin_sight_ai/core/theme/theme_controller.dart' as _i32;
import 'package:fin_sight_ai/core/utils/app_env.dart' as _i1042;
import 'package:fin_sight_ai/core/utils/clock.dart' as _i956;
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
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart'
    as _i820;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
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
    final coreModule = _$CoreModule();
    final routingModule = _$RoutingModule();
    final transactionsModule = _$TransactionsModule();
    final debtsModule = _$DebtsModule();
    await gh.factoryAsync<_i422.AppBoxes>(
      () => storageModule.provideAppBoxes(),
      preResolve: true,
    );
    gh.lazySingleton<_i706.Uuid>(() => coreModule.provideUuid());
    gh.lazySingleton<_i1042.AppEnv>(() => coreModule.provideAppEnv());
    gh.lazySingleton<_i32.ThemeController>(() => _i32.ThemeController());
    gh.lazySingleton<_i956.Clock>(() => const _i956.Clock());
    gh.lazySingleton<_i583.GoRouter>(
      () => routingModule.provideGoRouter(gh<_i32.ThemeController>()),
    );
    gh.lazySingleton<_i228.TransactionLocalDataSource>(
      () => transactionsModule.provideTransactionLocalDataSource(
        gh<_i422.AppBoxes>(),
      ),
    );
    gh.lazySingleton<_i1035.DebtLocalDataSource>(
      () => debtsModule.provideDebtLocalDataSource(gh<_i422.AppBoxes>()),
    );
    gh.lazySingleton<_i544.TransactionRepository>(
      () => _i529.TransactionRepositoryImpl(
        gh<_i228.TransactionLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i268.DebtRepository>(
      () => _i140.DebtRepositoryImpl(gh<_i1035.DebtLocalDataSource>()),
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
    gh.lazySingleton<_i361.AddTransactionUseCase>(
      () => _i361.AddTransactionUseCase(
        gh<_i544.TransactionRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i978.MakePaymentUseCase>(
      () => _i978.MakePaymentUseCase(
        gh<_i268.DebtRepository>(),
        uuid: gh<_i706.Uuid>(),
        clock: gh<_i956.Clock>(),
      ),
    );
    gh.lazySingleton<_i144.AddDebtUseCase>(
      () => _i144.AddDebtUseCase(
        gh<_i268.DebtRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.factory<_i820.TransactionBloc>(
      () => _i820.TransactionBloc(
        gh<_i1051.GetTransactionsUseCase>(),
        gh<_i361.AddTransactionUseCase>(),
        gh<_i69.DeleteTransactionUseCase>(),
        gh<_i271.GetTransactionsByDateRangeUseCase>(),
      ),
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
    gh.factory<_i1009.DebtBloc>(
      () => _i1009.DebtBloc(
        gh<_i243.GetDebtsUseCase>(),
        gh<_i144.AddDebtUseCase>(),
        gh<_i978.MakePaymentUseCase>(),
        gh<_i24.DeleteDebtUseCase>(),
        gh<_i1045.CalculatePayoffUseCase>(),
      ),
    );
    return this;
  }
}

class _$StorageModule extends _i1015.StorageModule {}

class _$CoreModule extends _i1015.CoreModule {}

class _$RoutingModule extends _i1015.RoutingModule {}

class _$TransactionsModule extends _i1015.TransactionsModule {}

class _$DebtsModule extends _i1015.DebtsModule {}
