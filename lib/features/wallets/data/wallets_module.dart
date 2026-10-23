import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import 'datasources/hive_wallet_local_data_source.dart';
import 'datasources/wallet_local_data_source.dart';

@module
abstract class WalletsModule {
  @lazySingleton
  WalletLocalDataSource provideWalletLocalDataSource(AppBoxes boxes) =>
      HiveWalletLocalDataSource(boxes.wallets, boxes.walletTransfers);
}
