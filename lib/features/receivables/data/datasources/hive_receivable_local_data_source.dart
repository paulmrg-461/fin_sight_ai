import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/receivable_model.dart';
import 'receivable_local_data_source.dart';

/// Hive-backed offline storage for receivables.
class HiveReceivableLocalDataSource implements ReceivableLocalDataSource {
  const HiveReceivableLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<ReceivableModel>> getReceivables() async {
    try {
      return _readAll()..sort(_compare);
    } catch (_) {
      throw const CacheException(
        'Unable to read receivables from local storage.',
        code: 'cache_read_failed',
      );
    }
  }

  @override
  Future<void> saveReceivable(ReceivableModel receivable) async {
    try {
      await _box.put(receivable.id, receivable.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the receivable locally.',
        code: 'cache_write_failed',
      );
    }
  }

  @override
  Future<void> deleteReceivable(String id) async {
    try {
      await _box.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to delete the receivable locally.',
        code: 'cache_delete_failed',
      );
    }
  }

  List<ReceivableModel> _readAll() {
    final receivables = <ReceivableModel>[];
    for (final value in _box.values) {
      if (value is! Map) {
        throw const FormatException('Invalid receivable entry.');
      }
      receivables.add(
        ReceivableModel.fromJson(Map<String, dynamic>.from(value)),
      );
    }
    return receivables;
  }

  int _compare(ReceivableModel a, ReceivableModel b) {
    if (a.isPaid != b.isPaid) {
      return a.isPaid ? 1 : -1;
    }
    if (!a.isPaid) {
      final aDate = a.dueDate ?? a.dateLent;
      final bDate = b.dueDate ?? b.dateLent;
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) {
        return byDate;
      }
      return a.dateLent.compareTo(b.dateLent);
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }
}
