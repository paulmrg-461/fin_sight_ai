// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:fin_sight_ai/core/di/injection.dart' as _i1015;
import 'package:fin_sight_ai/features/transactions/data/datasources/noop_transaction_remote_data_source.dart'
    as _i105;
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart'
    as _i228;
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_remote_data_source.dart'
    as _i613;
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart'
    as _i529;
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart'
    as _i544;
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart'
    as _i361;
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart'
    as _i1051;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final transactionsModule = _$TransactionsModule();
    final coreModule = _$CoreModule();
    await gh.factoryAsync<_i228.TransactionLocalDataSource>(
      () => transactionsModule.provideLocalDataSource(),
      preResolve: true,
    );
    gh.lazySingleton<_i706.Uuid>(() => coreModule.provideUuid());
    gh.lazySingleton<_i613.TransactionRemoteDataSource>(
      () => const _i105.NoopTransactionRemoteDataSource(),
    );
    gh.lazySingleton<_i544.TransactionRepository>(
      () => _i529.TransactionRepositoryImpl(
        gh<_i228.TransactionLocalDataSource>(),
        gh<_i613.TransactionRemoteDataSource>(),
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
    return this;
  }
}

class _$TransactionsModule extends _i1015.TransactionsModule {}

class _$CoreModule extends _i1015.CoreModule {}
