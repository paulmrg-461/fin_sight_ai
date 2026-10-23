import '../../../../core/sync/sync_operation.dart';

/// Persistent queue and sync metadata.
abstract interface class SyncLocalDataSource implements SyncQueue {
  Future<List<SyncOperation>> pending();

  Future<void> remove(String id);

  Future<int> pendingCount();

  Future<DateTime?> lastSyncedAt();

  Future<void> setLastSyncedAt(DateTime value);
}
