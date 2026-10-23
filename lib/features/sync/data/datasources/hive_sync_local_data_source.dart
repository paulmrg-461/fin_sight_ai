import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import 'sync_local_data_source.dart';

/// Hive-backed sync queue plus last-sync metadata.
class HiveSyncLocalDataSource implements SyncLocalDataSource {
  const HiveSyncLocalDataSource(this._queueBox, this._metaBox);

  static const String _lastSyncedKey = 'lastSyncedAt';

  final Box<dynamic> _queueBox;
  final Box<dynamic> _metaBox;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    try {
      await _queueBox.put(operation.id, operation.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to queue the change for synchronization.',
        code: 'sync_queue_write_failed',
      );
    }
  }

  @override
  Future<List<SyncOperation>> pending() async {
    try {
      final operations = <SyncOperation>[];
      for (final value in _queueBox.values) {
        if (value is! Map) {
          throw const FormatException('Invalid sync operation.');
        }
        operations.add(
          SyncOperation.fromJson(Map<String, dynamic>.from(value)),
        );
      }
      operations.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      return List<SyncOperation>.unmodifiable(operations);
    } catch (_) {
      throw const CacheException(
        'Unable to read the synchronization queue.',
        code: 'sync_queue_read_failed',
      );
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _queueBox.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to update the synchronization queue.',
        code: 'sync_queue_write_failed',
      );
    }
  }

  @override
  Future<int> pendingCount() async {
    try {
      return _queueBox.length;
    } catch (_) {
      throw const CacheException(
        'Unable to read the synchronization queue.',
        code: 'sync_queue_read_failed',
      );
    }
  }

  @override
  Future<DateTime?> lastSyncedAt() async {
    try {
      final value = _metaBox.get(_lastSyncedKey);
      if (value is! String) {
        return null;
      }
      return DateTime.tryParse(value);
    } catch (_) {
      throw const CacheException(
        'Unable to read sync metadata.',
        code: 'sync_meta_read_failed',
      );
    }
  }

  @override
  Future<void> setLastSyncedAt(DateTime value) async {
    try {
      await _metaBox.put(_lastSyncedKey, value.toUtc().toIso8601String());
    } catch (_) {
      throw const CacheException(
        'Unable to persist sync metadata.',
        code: 'sync_meta_write_failed',
      );
    }
  }
}
