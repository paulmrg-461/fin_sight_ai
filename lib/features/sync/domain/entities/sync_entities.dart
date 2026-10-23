/// Outcome of a synchronization pass.
class SyncReport {
  const SyncReport({
    required this.pushed,
    required this.pulled,
    required this.conflictsResolved,
    required this.pendingOperations,
    required this.isConfigured,
    required this.isAuthenticated,
    required this.completedAt,
  });

  final int pushed;
  final int pulled;
  final int conflictsResolved;
  final int pendingOperations;

  /// `false` when Supabase credentials are missing (offline-only mode).
  final bool isConfigured;

  /// `false` when the user has no valid Supabase session.
  final bool isAuthenticated;
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
          other.isAuthenticated == isAuthenticated &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    pushed,
    pulled,
    conflictsResolved,
    pendingOperations,
    isConfigured,
    isAuthenticated,
    completedAt,
  );

  @override
  String toString() =>
      'SyncReport(pushed: $pushed, pulled: $pulled, '
      'conflicts: $conflictsResolved, pending: $pendingOperations, '
      'configured: $isConfigured, authenticated: $isAuthenticated)';
}

/// Lightweight status used by the dashboard sync indicator.
class SyncStatusEntity {
  const SyncStatusEntity({
    required this.pendingCount,
    required this.isConfigured,
    required this.isAuthenticated,
    this.lastSyncedAt,
  });

  final int pendingCount;
  final bool isConfigured;
  final bool isAuthenticated;
  final DateTime? lastSyncedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusEntity &&
          other.pendingCount == pendingCount &&
          other.isConfigured == isConfigured &&
          other.isAuthenticated == isAuthenticated &&
          other.lastSyncedAt == lastSyncedAt;

  @override
  int get hashCode =>
      Object.hash(pendingCount, isConfigured, isAuthenticated, lastSyncedAt);

  @override
  String toString() =>
      'SyncStatusEntity(pending: $pendingCount, configured: $isConfigured, '
      'authenticated: $isAuthenticated)';
}
