/// Cross-cutting constants shared by core and feature layers.
abstract final class AppConstants {
  static const String appName = 'FinSight AI';
  static const String transactionsBoxName = 'transactions';
  static const String debtsBoxName = 'debts';
  static const String receivablesBoxName = 'receivables';
  static const String receiptsBoxName = 'receipts';
  static const String storageMetaBoxName = 'storage_meta';
  static const String syncQueueBoxName = 'sync_queue';
  static const String syncMetaBoxName = 'sync_meta';
  static const String budgetsBoxName = 'budgets';
  static const String walletsBoxName = 'wallets';
  static const String walletTransfersBoxName = 'wallet_transfers';
  static const String settingsBoxName = 'settings';
  static const String categoriesBoxName = 'categories';
  static const String scheduledPaymentsBoxName = 'scheduled_payments';
  static const String aiInsightsBoxName = 'ai_insights';
  static const String savingsGoalsBoxName = 'savings_goals';
  static const String calendarMigrationFlagKey = 'calendar_migration_v1';
  static const int maxNoteLength = 500;
  static const int maxDebtorNameLength = 120;
  static const double maxInterestRate = 100;
}
