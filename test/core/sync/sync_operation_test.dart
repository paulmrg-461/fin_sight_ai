import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final queuedAt = DateTime.utc(2026, 10, 22, 12);

  group('SyncOperation', () {
    test('builds an upsert keyed by entity type and id', () {
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        payload: const {'id': 'tx-1', 'amount': 10},
        queuedAt: queuedAt,
      );

      expect(operation.id, 'transaction:tx-1');
      expect(operation.operationType, SyncOperationType.upsert);
      expect(operation.attempts, 0);
    });

    test('builds a delete operation without payload', () {
      final operation = SyncOperation.delete(
        entityType: SyncEntityType.debt,
        entityId: 'debt-1',
        queuedAt: queuedAt,
      );

      expect(operation.id, 'debt:debt-1');
      expect(operation.operationType, SyncOperationType.delete);
      expect(operation.payload, isEmpty);
    });

    test('round-trips through JSON', () {
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.debt,
        entityId: 'debt-1',
        payload: const {'id': 'debt-1', 'creditorName': 'Bank'},
        queuedAt: queuedAt,
      ).copyWith(attempts: 2);

      final restored = SyncOperation.fromJson(operation.toJson());

      expect(restored, operation);
      expect(restored.attempts, 2);
    });

    test('copyWith only changes attempts', () {
      final operation = SyncOperation.delete(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        queuedAt: queuedAt,
      );

      final retried = operation.copyWith(attempts: 3);

      expect(retried.attempts, 3);
      expect(retried.id, operation.id);
      expect(retried.operationType, operation.operationType);
    });

    test('round-trips retry backoff metadata', () {
      final operation =
          SyncOperation.upsert(
            entityType: SyncEntityType.transaction,
            entityId: 'tx-1',
            payload: const {'id': 'tx-1'},
            queuedAt: queuedAt,
          ).copyWith(
            attempts: 2,
            nextAttemptAt: queuedAt.add(const Duration(minutes: 4)),
          );

      final restored = SyncOperation.fromJson(operation.toJson());

      expect(restored, operation);
      expect(restored.nextAttemptAt, queuedAt.add(const Duration(minutes: 4)));
    });

    test('rejects invalid JSON', () {
      expect(
        () => SyncOperation.fromJson(const {'id': ''}),
        throwsFormatException,
      );
      expect(
        () => SyncOperation.fromJson(const {
          'id': 'x',
          'entityType': 'unknown',
          'entityId': 'y',
          'operationType': 'upsert',
          'queuedAt': '2026-10-22T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('toString exposes the operation', () {
      final description = SyncOperation.delete(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        queuedAt: queuedAt,
      ).toString();

      expect(description, contains('transaction:tx-1'));
      expect(description, contains('delete'));
    });
  });
}
