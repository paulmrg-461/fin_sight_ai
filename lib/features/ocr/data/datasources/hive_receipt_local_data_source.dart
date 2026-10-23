import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/receipt_model.dart';
import 'receipt_local_data_source.dart';

/// Hive-backed storage for scanned receipts.
class HiveReceiptLocalDataSource implements ReceiptLocalDataSource {
  const HiveReceiptLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<ReceiptModel>> getReceipts() async {
    try {
      return _readAll()..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      throw const CacheException(
        'Unable to read receipts from local storage.',
        code: 'cache_read_failed',
      );
    }
  }

  @override
  Future<void> saveReceipt(ReceiptModel receipt) async {
    try {
      await _box.put(receipt.id, receipt.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the receipt locally.',
        code: 'cache_write_failed',
      );
    }
  }

  List<ReceiptModel> _readAll() {
    final receipts = <ReceiptModel>[];
    for (final value in _box.values) {
      if (value is! Map) {
        throw const FormatException('Invalid receipt entry.');
      }
      receipts.add(ReceiptModel.fromJson(Map<String, dynamic>.from(value)));
    }
    return receipts;
  }
}
