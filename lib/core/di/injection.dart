import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/debts/data/datasources/debt_local_data_source.dart';
import '../../features/debts/data/datasources/hive_debt_local_data_source.dart';
import '../../features/receivables/data/datasources/hive_receivable_local_data_source.dart';
import '../../features/receivables/data/datasources/receivable_local_data_source.dart';
import '../../features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import '../../features/transactions/data/datasources/transaction_local_data_source.dart';
import '../routing/app_router.dart';
import '../services/app_boxes.dart';
import '../services/local_data_scope.dart';
import '../services/receipt_image_picker.dart';
import '../theme/theme_controller.dart';
import '../utils/app_constants.dart';
import '../utils/app_env.dart';
import 'injection.config.dart';

/// Global service locator. Resolve dependencies only at composition
/// boundaries (startup, router factories); never inside domain or data code.
final GetIt getIt = GetIt.instance;

/// Builds the object graph. Async because Hive boxes are pre-resolved.
@InjectableInit()
Future<void> configureDependencies({String? environment}) async {
  await getIt.init(environment: environment);
}

/// Third-party and async registrations that injectable cannot infer.
@module
abstract class CoreModule {
  @lazySingleton
  Uuid provideUuid() => const Uuid();

  @lazySingleton
  AppEnv provideAppEnv() => AppEnv.current();

  @lazySingleton
  http.Client provideHttpClient() => http.Client();
}

@module
abstract class StorageModule {
  @preResolve
  Future<AppBoxes> provideAppBoxes() async {
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);

    return AppBoxes(
      transactions: await Hive.openBox<dynamic>(
        AppConstants.transactionsBoxName,
      ),
      debts: await Hive.openBox<dynamic>(AppConstants.debtsBoxName),
      receivables: await Hive.openBox<dynamic>(AppConstants.receivablesBoxName),
      receipts: await Hive.openBox<dynamic>(AppConstants.receiptsBoxName),
      syncQueue: await Hive.openBox<dynamic>(AppConstants.syncQueueBoxName),
      syncMeta: await Hive.openBox<dynamic>(AppConstants.syncMetaBoxName),
      budgets: await Hive.openBox<dynamic>(AppConstants.budgetsBoxName),
      wallets: await Hive.openBox<dynamic>(AppConstants.walletsBoxName),
      walletTransfers: await Hive.openBox<dynamic>(
        AppConstants.walletTransfersBoxName,
      ),
      settings: await Hive.openBox<dynamic>(AppConstants.settingsBoxName),
      categories: await Hive.openBox<dynamic>(AppConstants.categoriesBoxName),
      scheduledPayments: await Hive.openBox<dynamic>(
        AppConstants.scheduledPaymentsBoxName,
      ),
    );
  }
}

@module
abstract class LocalDataModule {
  @lazySingleton
  LocalDataScope provideLocalDataScope(AppBoxes boxes) =>
      HiveLocalDataScope(boxes);
}

@module
abstract class TransactionsModule {
  @lazySingleton
  TransactionLocalDataSource provideTransactionLocalDataSource(
    AppBoxes boxes,
  ) => HiveTransactionLocalDataSource(boxes.transactions);
}

@module
abstract class DebtsModule {
  @lazySingleton
  DebtLocalDataSource provideDebtLocalDataSource(AppBoxes boxes) =>
      HiveDebtLocalDataSource(boxes.debts);
}

@module
abstract class ReceivablesModule {
  @lazySingleton
  ReceivableLocalDataSource provideReceivableLocalDataSource(AppBoxes boxes) =>
      HiveReceivableLocalDataSource(boxes.receivables);
}

@module
abstract class RoutingModule {
  @lazySingleton
  GoRouter provideGoRouter(
    ThemeController themeController,
    ReceiptImagePicker imagePicker,
  ) => buildRouter(
    themeController: themeController,
    receiptImagePicker: imagePicker,
  );
}
