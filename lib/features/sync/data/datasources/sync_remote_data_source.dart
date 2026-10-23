/// Remote synchronization contract (Supabase PostgREST in production).
///
/// Maps use the same camelCase shape as `TransactionModel` / `DebtModel` so the
/// sync repository can reuse the existing JSON mappers.
abstract interface class SyncRemoteDataSource {
  Future<Map<String, dynamic>?> fetchTransaction(String id);

  Future<List<Map<String, dynamic>>> fetchTransactions({
    DateTime? updatedAfter,
  });

  Future<void> upsertTransaction(Map<String, dynamic> json);

  Future<void> deleteTransaction(String id);

  Future<Map<String, dynamic>?> fetchDebt(String id);

  Future<List<Map<String, dynamic>>> fetchDebts({DateTime? updatedAfter});

  Future<void> upsertDebt(Map<String, dynamic> json);

  Future<void> deleteDebt(String id);

  Future<Map<String, dynamic>?> fetchBudget(String id);

  Future<List<Map<String, dynamic>>> fetchBudgets({DateTime? updatedAfter});

  Future<void> upsertBudget(Map<String, dynamic> json);

  Future<void> deleteBudget(String id);
}
