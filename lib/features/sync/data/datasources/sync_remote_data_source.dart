/// Remote synchronization contract (Supabase PostgREST in production).
///
/// Maps use the same camelCase shape as `TransactionModel` / `DebtModel` so the
/// sync repository can reuse the existing JSON mappers.
abstract interface class SyncRemoteDataSource {
  Future<Map<String, dynamic>?> fetchTransaction(String id);

  Future<List<Map<String, dynamic>>> fetchTransactions({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  });

  Future<void> upsertTransaction(Map<String, dynamic> json);

  Future<void> deleteTransaction(String id);

  Future<Map<String, dynamic>?> fetchDebt(String id);

  Future<List<Map<String, dynamic>>> fetchDebts({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  });

  Future<void> upsertDebt(Map<String, dynamic> json);

  Future<void> deleteDebt(String id);

  Future<Map<String, dynamic>?> fetchBudget(String id);

  Future<List<Map<String, dynamic>>> fetchBudgets({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  });

  Future<void> upsertBudget(Map<String, dynamic> json);

  Future<void> deleteBudget(String id);

  Future<Map<String, dynamic>?> fetchReceivable(String id);

  Future<List<Map<String, dynamic>>> fetchReceivables({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  });

  Future<void> upsertReceivable(Map<String, dynamic> json);

  Future<void> deleteReceivable(String id);
}
