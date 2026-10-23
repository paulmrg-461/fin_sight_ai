import '../../../../core/usecase/usecase.dart';
import '../entities/sync_entities.dart';

/// Domain contract for offline-to-remote synchronization.
abstract interface class SyncRepository {
  /// Pushes pending operations, pulls remote changes, and returns a report.
  ResultFuture<SyncReport> syncNow();

  /// Returns the current pending count and configuration state.
  ResultFuture<SyncStatusEntity> getStatus();
}
