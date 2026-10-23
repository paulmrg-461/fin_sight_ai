import 'package:equatable/equatable.dart';

/// Base event for synchronization.
sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => const [];
}

/// Refreshes the pending count and last-sync timestamp.
final class LoadSyncStatus extends SyncEvent {
  const LoadSyncStatus();
}

/// Runs a full push/pull synchronization pass.
final class SyncNow extends SyncEvent {
  const SyncNow();
}
