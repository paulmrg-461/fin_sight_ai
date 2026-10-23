import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app_boxes.dart';

/// Tracks which account owns the financial data stored on this device.
///
/// Policy: one account per device. Local data is wiped on explicit sign-out
/// and whenever the stored session no longer matches the recorded owner.
abstract interface class LocalDataScope {
  Future<String?> getOwnerUserId();

  Future<void> setOwnerUserId(String? userId);

  /// Clears every user-owned box, including the sync queue and metadata.
  ///
  /// Settings preferences (currency, locale, migrations) are preserved.
  Future<void> clearAllUserData();
}

/// Hive-backed [LocalDataScope].
class HiveLocalDataScope implements LocalDataScope {
  const HiveLocalDataScope(this._boxes);

  /// Settings key that records the owner of the local data.
  static const String ownerKey = 'owner_user_id';

  final AppBoxes _boxes;

  @override
  Future<String?> getOwnerUserId() async {
    final value = _boxes.settings.get(ownerKey);
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  @override
  Future<void> setOwnerUserId(String? userId) async {
    if (userId == null) {
      await _boxes.settings.delete(ownerKey);
      return;
    }
    await _boxes.settings.put(ownerKey, userId);
  }

  @override
  Future<void> clearAllUserData() async {
    for (final box in _userDataBoxes) {
      await box.clear();
    }
  }

  Iterable<Box<dynamic>> get _userDataBoxes => [
    _boxes.transactions,
    _boxes.debts,
    _boxes.receipts,
    _boxes.budgets,
    _boxes.wallets,
    _boxes.walletTransfers,
    _boxes.categories,
    _boxes.scheduledPayments,
    _boxes.syncQueue,
    _boxes.syncMeta,
  ];
}
