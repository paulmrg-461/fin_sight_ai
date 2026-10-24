/// Entities that participate in remote synchronization.
enum SyncEntityType { transaction, debt, budget, receivable }

/// Operations queued while offline.
enum SyncOperationType { upsert, delete }

/// A single pending synchronization operation.
///
/// The queue is keyed by [id] (`<entityType>:<entityId>`), so repeated edits of
/// the same record collapse into the latest operation.
class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.queuedAt,
    this.payload = const {},
    this.attempts = 0,
    this.nextAttemptAt,
  });

  factory SyncOperation.upsert({
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required DateTime queuedAt,
    DateTime? nextAttemptAt,
  }) {
    return SyncOperation(
      id: keyFor(entityType, entityId),
      entityType: entityType,
      entityId: entityId,
      operationType: SyncOperationType.upsert,
      queuedAt: queuedAt,
      payload: payload,
      nextAttemptAt: nextAttemptAt,
    );
  }

  factory SyncOperation.delete({
    required SyncEntityType entityType,
    required String entityId,
    required DateTime queuedAt,
    DateTime? nextAttemptAt,
  }) {
    return SyncOperation(
      id: keyFor(entityType, entityId),
      entityType: entityType,
      entityId: entityId,
      operationType: SyncOperationType.delete,
      queuedAt: queuedAt,
      nextAttemptAt: nextAttemptAt,
    );
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final entityType = json['entityType'];
    final entityId = json['entityId'];
    final operationType = json['operationType'];
    final queuedAt = json['queuedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Sync operation id is missing.');
    }
    if (entityType is! String || entityId is! String) {
      throw const FormatException('Sync operation target is invalid.');
    }
    if (operationType is! String || queuedAt is! String) {
      throw const FormatException('Sync operation type is invalid.');
    }

    final parsedEntityType = SyncEntityType.values.asNameMap()[entityType];
    final parsedOperationType = SyncOperationType.values
        .asNameMap()[operationType];
    if (parsedEntityType == null || parsedOperationType == null) {
      throw const FormatException('Unknown sync operation enum value.');
    }

    final payload = json['payload'];
    final attempts = json['attempts'];
    final nextAttemptAt = json['nextAttemptAt'];

    return SyncOperation(
      id: id,
      entityType: parsedEntityType,
      entityId: entityId,
      operationType: parsedOperationType,
      queuedAt: DateTime.parse(queuedAt),
      payload: payload is Map ? Map<String, dynamic>.from(payload) : const {},
      attempts: attempts is int ? attempts : 0,
      nextAttemptAt: nextAttemptAt is String
          ? DateTime.tryParse(nextAttemptAt)
          : null,
    );
  }

  static String keyFor(SyncEntityType entityType, String entityId) =>
      '${entityType.name}:$entityId';

  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operationType;
  final DateTime queuedAt;
  final Map<String, dynamic> payload;
  final int attempts;

  /// Earliest time this operation may be retried after a failure.
  final DateTime? nextAttemptAt;

  SyncOperation copyWith({int? attempts, DateTime? nextAttemptAt}) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      queuedAt: queuedAt,
      payload: payload,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'entityType': entityType.name,
      'entityId': entityId,
      'operationType': operationType.name,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'payload': payload,
      'attempts': attempts,
      'nextAttemptAt': nextAttemptAt?.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperation &&
          other.id == id &&
          other.entityType == entityType &&
          other.entityId == entityId &&
          other.operationType == operationType &&
          other.queuedAt == queuedAt &&
          other.attempts == attempts &&
          other.nextAttemptAt == nextAttemptAt &&
          _samePayload(other.payload, payload);

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operationType,
    queuedAt,
    attempts,
    nextAttemptAt,
    payload.toString(),
  );

  static bool _samePayload(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'SyncOperation($id, $operationType, attempts: $attempts)';
}

/// Port used by feature repositories to schedule remote synchronization.
abstract interface class SyncQueue {
  Future<void> enqueue(SyncOperation operation);
}
