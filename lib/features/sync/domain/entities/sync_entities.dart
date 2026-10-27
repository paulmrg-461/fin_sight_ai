import '../../../../core/sync/sync_operation.dart';

/// One entity that failed during a sync pass.
class SyncEntityFailure {
  const SyncEntityFailure({
    required this.entityType,
    required this.code,
    required this.message,
  });

  final SyncEntityType entityType;
  final String code;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncEntityFailure &&
          other.entityType == entityType &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(entityType, code, message);

  @override
  String toString() => 'SyncEntityFailure(${entityType.name}: $code)';
}

/// Outcome of a synchronization pass.
class SyncReport {
  const SyncReport({
    required this.pushed,
    required this.pulled,
    required this.conflictsResolved,
    required this.pendingOperations,
    this.failed = 0,
    this.discarded = 0,
    this.failures = const [],
    required this.isConfigured,
    required this.isAuthenticated,
    required this.completedAt,
  });

  final int pushed;
  final int pulled;
  final int conflictsResolved;
  final int pendingOperations;

  /// Operations that failed transiently and were requeued with backoff.
  final int failed;

  /// Invalid queued payloads that were removed and cannot be retried.
  final int discarded;

  /// Entity-level failures, including pull failures that did not block others.
  final List<SyncEntityFailure> failures;

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
          other.failed == failed &&
          other.discarded == discarded &&
          _sameFailures(other.failures, failures) &&
          other.isConfigured == isConfigured &&
          other.isAuthenticated == isAuthenticated &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    pushed,
    pulled,
    conflictsResolved,
    pendingOperations,
    failed,
    discarded,
    Object.hashAll(failures),
    isConfigured,
    isAuthenticated,
    completedAt,
  );

  @override
  String toString() =>
      'SyncReport(pushed: $pushed, pulled: $pulled, '
      'conflicts: $conflictsResolved, pending: $pendingOperations, '
      'failed: $failed, discarded: $discarded, '
      'failures: ${failures.length}, '
      'configured: $isConfigured, authenticated: $isAuthenticated)';

  static bool _sameFailures(
    List<SyncEntityFailure> a,
    List<SyncEntityFailure> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
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
