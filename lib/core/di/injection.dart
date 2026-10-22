import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/transactions/data/datasources/json_file_transaction_local_data_source.dart';
import '../../features/transactions/data/datasources/transaction_local_data_source.dart';
import 'injection.config.dart';

/// Global service locator. Resolve dependencies only at composition boundaries
/// (app startup, BLoC factories); never inside domain or data classes.
final GetIt getIt = GetIt.instance;

/// Builds the object graph. Async because the local store is pre-resolved.
@InjectableInit()
Future<void> configureDependencies({String? environment}) async {
  await getIt.init(environment: environment);
}

/// Third-party and async registrations that injectable cannot infer.
@module
abstract class CoreModule {
  @lazySingleton
  Uuid provideUuid() => const Uuid();
}

@module
abstract class TransactionsModule {
  @preResolve
  Future<TransactionLocalDataSource> provideLocalDataSource() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(directory.path, 'fin_sight_ai', 'transactions.json'),
    );
    return JsonFileTransactionLocalDataSource(file);
  }
}
