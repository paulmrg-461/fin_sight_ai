/// Cross-cutting constants shared by core and feature layers.
abstract final class AppConstants {
  static const String appName = 'FinSight AI';
  static const String transactionsBoxName = 'transactions';
  static const String debtsBoxName = 'debts';
  static const String receiptsBoxName = 'receipts';
  static const String syncQueueBoxName = 'sync_queue';
  static const String syncMetaBoxName = 'sync_meta';
  static const int maxNoteLength = 500;
  static const double maxInterestRate = 100;
}
