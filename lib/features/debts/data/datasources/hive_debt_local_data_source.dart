import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/debt_model.dart';
import 'debt_local_data_source.dart';

/// Hive-backed offline storage for debts.
class HiveDebtLocalDataSource implements DebtLocalDataSource {
  const HiveDebtLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<DebtModel>> getDebts() async {
    try {
      return _readAll().where((debt) => !debt.isDeleted).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (_) {
      throw const CacheException(
        'Unable to read debts from local storage.',
        code: 'cache_read_failed',
      );
    }
  }

  @override
  Future<void> saveDebt(DebtModel debt) async {
    try {
      await _box.put(debt.id, debt.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the debt locally.',
        code: 'cache_write_failed',
      );
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    try {
      await _box.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to delete the debt locally.',
        code: 'cache_delete_failed',
      );
    }
  }

  @override
  Future<int> purgeTombstones(DateTime before) async {
    try {
      final keys = <dynamic>[];
      for (final key in _box.keys) {
        final value = _box.get(key);
        if (value is! Map) {
          continue;
        }
        final model = DebtModel.fromJson(Map<String, dynamic>.from(value));
        final deletedAt = model.deletedAt;
        if (deletedAt != null && deletedAt.isBefore(before)) {
          keys.add(key);
        }
      }
      if (keys.isEmpty) {
        return 0;
      }
      await _box.deleteAll(keys);
      return keys.length;
    } catch (_) {
      throw const CacheException(
        'Unable to purge debt tombstones.',
        code: 'cache_purge_failed',
      );
    }
  }

  List<DebtModel> _readAll() {
    final debts = <DebtModel>[];
    for (final value in _box.values) {
      if (value is! Map) {
        throw const FormatException('Invalid debt entry.');
      }
      debts.add(DebtModel.fromJson(Map<String, dynamic>.from(value)));
    }
    return debts;
  }
}
