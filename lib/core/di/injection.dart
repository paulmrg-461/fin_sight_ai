import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../features/debts/data/datasources/debt_local_data_source.dart';
import '../../features/debts/data/datasources/hive_debt_local_data_source.dart';
import '../../features/receivables/data/datasources/hive_receivable_local_data_source.dart';
import '../../features/receivables/data/datasources/receivable_local_data_source.dart';
import '../../features/transactions/data/datasources/hive_transaction_local_data_source.dart';
import '../../features/transactions/data/datasources/transaction_local_data_source.dart';
import '../routing/app_router.dart';
import '../services/app_boxes.dart';
import '../services/box_encryption.dart';
import '../services/hive_storage_location.dart';
import '../services/local_data_scope.dart';
import '../services/local_reminder_scheduler.dart';
import '../services/reminder_scheduler.dart';
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
abstract class ReminderModule {
  @lazySingleton
  ReminderScheduler provideReminderScheduler() => LocalReminderScheduler();
}

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
    final directory = await const HiveStorageLocation().resolve();
    await Hive.initFlutter(directory.path);

    final meta = await Hive.openBox<dynamic>(AppConstants.storageMetaBoxName);
    final alreadyEncrypted = meta.get('encrypted') == true;
    final cipher = await HiveEncryption().cipher();
    if (alreadyEncrypted && cipher == null) {
      throw StateError(
        'Encrypted storage is enabled but the secure key is unavailable.',
      );
    }
    const opener = EncryptedBoxOpener();
    Future<Box<dynamic>> openBox(String name) =>
        opener.open(name, cipher, allowLegacyMigration: !alreadyEncrypted);

    final boxes = AppBoxes(
      transactions: await openBox(AppConstants.transactionsBoxName),
      debts: await openBox(AppConstants.debtsBoxName),
      receivables: await openBox(AppConstants.receivablesBoxName),
      receipts: await openBox(AppConstants.receiptsBoxName),
      syncQueue: await openBox(AppConstants.syncQueueBoxName),
      syncMeta: await openBox(AppConstants.syncMetaBoxName),
      budgets: await openBox(AppConstants.budgetsBoxName),
      wallets: await openBox(AppConstants.walletsBoxName),
      walletTransfers: await openBox(AppConstants.walletTransfersBoxName),
      settings: await openBox(AppConstants.settingsBoxName),
      categories: await openBox(AppConstants.categoriesBoxName),
      scheduledPayments: await openBox(AppConstants.scheduledPaymentsBoxName),
      aiInsights: await openBox(AppConstants.aiInsightsBoxName),
      savingsGoals: await openBox(AppConstants.savingsGoalsBoxName),
    );
    if (cipher != null && !alreadyEncrypted) {
      await meta.put('encrypted', true);
    }
    return boxes;
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
