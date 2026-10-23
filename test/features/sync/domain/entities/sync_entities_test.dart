import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final completedAt = DateTime.utc(2026, 10, 22, 12);

  SyncReport report() => SyncReport(
    pushed: 2,
    pulled: 1,
    conflictsResolved: 1,
    pendingOperations: 0,
    isConfigured: true,
    isAuthenticated: true,
    completedAt: completedAt,
  );

  group('SyncReport', () {
    test('uses value equality across all fields', () {
      expect(report(), report());
      expect(report().hashCode, report().hashCode);
      expect(
        report(),
        isNot(
          SyncReport(
            pushed: 0,
            pulled: 1,
            conflictsResolved: 1,
            pendingOperations: 0,
            isConfigured: true,
            isAuthenticated: true,
            completedAt: completedAt,
          ),
        ),
      );
      expect(
        report(),
        isNot(
          SyncReport(
            pushed: 2,
            pulled: 1,
            conflictsResolved: 1,
            pendingOperations: 0,
            isConfigured: false,
            isAuthenticated: true,
            completedAt: completedAt,
          ),
        ),
      );
      expect(
        report(),
        isNot(
          SyncReport(
            pushed: 2,
            pulled: 1,
            conflictsResolved: 1,
            pendingOperations: 0,
            isConfigured: true,
            isAuthenticated: true,
            completedAt: completedAt.add(const Duration(minutes: 1)),
          ),
        ),
      );
    });

    test('toString summarizes the pass', () {
      final description = report().toString();

      expect(description, contains('pushed: 2'));
      expect(description, contains('pulled: 1'));
      expect(description, contains('conflicts: 1'));
    });
  });

  group('SyncStatusEntity', () {
    const status = SyncStatusEntity(
      pendingCount: 3,
      isConfigured: true,
      isAuthenticated: true,
    );

    test('uses value equality including the last sync timestamp', () {
      expect(
        status,
        const SyncStatusEntity(
          pendingCount: 3,
          isConfigured: true,
          isAuthenticated: true,
        ),
      );
      expect(status.hashCode, isNonZero);
      expect(
        status,
        isNot(
          const SyncStatusEntity(
            pendingCount: 0,
            isConfigured: true,
            isAuthenticated: true,
          ),
        ),
      );
      expect(
        status,
        isNot(
          const SyncStatusEntity(
            pendingCount: 3,
            isConfigured: false,
            isAuthenticated: true,
          ),
        ),
      );
      expect(
        status,
        isNot(
          SyncStatusEntity(
            pendingCount: 3,
            isConfigured: true,
            isAuthenticated: true,
            lastSyncedAt: completedAt,
          ),
        ),
      );
    });

    test('toString exposes pending and configuration state', () {
      final description = status.toString();

      expect(description, contains('pending: 3'));
      expect(description, contains('configured: true'));
    });
  });
}
