/// Outcome of a synchronization pass.
class SyncReport {
  const SyncReport({
    required this.pushed,
    required this.pulled,
    required this.conflictsResolved,
    required this.pendingOperations,
    required this.isConfigured,
    required this.completedAt,
  });

  final int pushed;
  final int pulled;
  final int conflictsResolved;
  final int pendingOperations;

  /// `false` when Supabase credentials are missing (offline-only mode).
  final bool isConfigured;
  final DateTime completedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncReport &&
          other.pushed == pushed &&
          other.pulled == pulled &&
          other.conflictsResolved == conflictsResolved &&
          other.pendingOperations == pendingOperations &&
          other.isConfigured == isConfigured &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    pushed,
    pulled,
    conflictsResolved,
    pendingOperations,
    isConfigured,
    completedAt,
  );

  @override
  String toString() =>
      'SyncReport(pushed: $pushed, pulled: $pulled, '
      'conflicts: $conflictsResolved, pending: $pendingOperations, '
      'configured: $isConfigured)';
}

/// Lightweight status used by the dashboard sync indicator.
class SyncStatusEntity {
  const SyncStatusEntity({
    required this.pendingCount,
    required this.isConfigured,
    this.lastSyncedAt,
  });

  final int pendingCount;
  final bool isConfigured;
  final DateTime? lastSyncedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusEntity &&
          other.pendingCount == pendingCount &&
          other.isConfigured == isConfigured &&
          other.lastSyncedAt == lastSyncedAt;

  @override
  int get hashCode => Object.hash(pendingCount, isConfigured, lastSyncedAt);

  @override
  String toString() =>
      'SyncStatusEntity(pending: $pendingCount, configured: $isConfigured)';
}
