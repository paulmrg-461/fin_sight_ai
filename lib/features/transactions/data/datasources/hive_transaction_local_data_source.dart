import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';
import 'transaction_local_data_source.dart';

/// Hive-backed offline storage for transactions.
///
/// Records are stored as JSON maps keyed by transaction id, which keeps the
/// box schema-agnostic and survives model changes through explicit migrations.
class HiveTransactionLocalDataSource implements TransactionLocalDataSource {
  const HiveTransactionLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      return _readAll()..sort(_newestFirst);
    } catch (_) {
      throw const CacheException(
        'Unable to read transactions from local storage.',
        code: 'cache_read_failed',
      );
    }
  }

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await _box.put(transaction.id, transaction.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the transaction locally.',
        code: 'cache_write_failed',
      );
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _box.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to delete the transaction locally.',
        code: 'cache_delete_failed',
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return _readAll()
        ..removeWhere(
          (transaction) =>
              transaction.date.isBefore(start) || transaction.date.isAfter(end),
        )
        ..sort(_newestFirst);
    } catch (_) {
      throw const CacheException(
        'Unable to read transactions from local storage.',
        code: 'cache_read_failed',
      );
    }
  }

  List<TransactionModel> _readAll() {
    final transactions = <TransactionModel>[];
    for (final value in _box.values) {
      if (value is! Map) {
        throw const FormatException('Invalid transaction entry.');
      }
      transactions.add(
        TransactionModel.fromJson(Map<String, dynamic>.from(value)),
      );
    }
    return transactions;
  }

  int _newestFirst(TransactionModel a, TransactionModel b) =>
      b.date.compareTo(a.date);
}
