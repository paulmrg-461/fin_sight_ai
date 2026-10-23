import 'package:hive_ce_flutter/hive_flutter.dart';

/// Open Hive boxes shared by the data sources.
class AppBoxes {
  const AppBoxes({
    required this.transactions,
    required this.debts,
    required this.receipts,
    required this.syncQueue,
    required this.syncMeta,
    required this.budgets,
    required this.wallets,
    required this.walletTransfers,
    required this.settings,
  });

  final Box<dynamic> transactions;
  final Box<dynamic> debts;
  final Box<dynamic> receipts;
  final Box<dynamic> syncQueue;
  final Box<dynamic> syncMeta;
  final Box<dynamic> budgets;
  final Box<dynamic> wallets;
  final Box<dynamic> walletTransfers;
  final Box<dynamic> settings;
}
