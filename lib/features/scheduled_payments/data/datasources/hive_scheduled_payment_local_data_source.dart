import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/scheduled_payment_model.dart';
import 'scheduled_payment_local_data_source.dart';

/// Hive-backed scheduled payments.
class HiveScheduledPaymentLocalDataSource
    implements ScheduledPaymentLocalDataSource {
  const HiveScheduledPaymentLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<ScheduledPaymentModel>> getPayments() async {
    try {
      final payments = <ScheduledPaymentModel>[];
      for (final value in _box.values) {
        if (value is! Map) {
          continue;
        }
        try {
          payments.add(
            ScheduledPaymentModel.fromJson(Map<String, dynamic>.from(value)),
          );
        } on FormatException {
          // Skip corrupted rows instead of breaking the whole list.
        }
      }
      return List<ScheduledPaymentModel>.unmodifiable(payments);
    } catch (_) {
      throw const CacheException(
        'Unable to read scheduled payments.',
        code: 'scheduled_payment_read_failed',
      );
    }
  }

  @override
  Future<void> savePayment(ScheduledPaymentModel payment) async {
    try {
      await _box.put(payment.id, payment.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the scheduled payment locally.',
        code: 'scheduled_payment_write_failed',
      );
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      await _box.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to delete the scheduled payment.',
        code: 'scheduled_payment_delete_failed',
      );
    }
  }
}
