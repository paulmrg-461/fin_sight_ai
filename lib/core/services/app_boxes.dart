import 'package:hive_ce_flutter/hive_flutter.dart';

/// Open Hive boxes shared by the data sources.
class AppBoxes {
  const AppBoxes({
    required this.transactions,
    required this.debts,
    required this.receipts,
  });

  final Box<dynamic> transactions;
  final Box<dynamic> debts;
  final Box<dynamic> receipts;
}
