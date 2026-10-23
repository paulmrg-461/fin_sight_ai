import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import '../../../core/sync/sync_operation.dart';
import 'datasources/hive_sync_local_data_source.dart';
import 'datasources/sync_local_data_source.dart';

/// Sync queue registrations. `SyncQueue` is the write-side port used by the
/// transactions and debts repositories.
@module
abstract class SyncModule {
  @lazySingleton
  SyncLocalDataSource provideSyncLocalDataSource(AppBoxes boxes) =>
      HiveSyncLocalDataSource(boxes.syncQueue, boxes.syncMeta);

  @lazySingleton
  SyncQueue provideSyncQueue(SyncLocalDataSource localDataSource) =>
      localDataSource;
}
