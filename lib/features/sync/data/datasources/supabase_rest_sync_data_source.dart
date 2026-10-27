import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_env.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'sync_remote_data_source.dart';

/// Supabase PostgREST implementation of [SyncRemoteDataSource].
@LazySingleton(as: SyncRemoteDataSource)
class SupabaseRestSyncDataSource implements SyncRemoteDataSource {
  SupabaseRestSyncDataSource(this._client, this._env, this._auth);

  static const Duration timeout = Duration(seconds: 15);

  final http.Client _client;
  final AppEnv _env;
  final AuthRepository _auth;

  Map<String, String> get _headers => <String, String>{
    'apikey': _env.supabaseAnonKey,
    'Authorization': 'Bearer ${_auth.accessToken ?? _env.supabaseAnonKey}',
    'Content-Type': 'application/json',
  };

  void _ensureConfigured() {
    if (!_env.hasSupabase) {
      throw const ServerException(
        'Supabase is not configured.',
        code: 'supabase_not_configured',
      );
    }
    if (!_auth.isAuthenticated || _auth.accessToken == null) {
      throw const ServerException(
        'Sign in to synchronize with Supabase.',
        code: 'supabase_unauthenticated',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCategory(String id) async {
    final rows = await _fetch('categories', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _categoryFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'categories',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_categoryFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertCategory(Map<String, dynamic> json) async {
    await _upsert('categories', _categoryToRow(json));
  }

  @override
  Future<Map<String, dynamic>?> fetchScheduledPayment(String id) async {
    final rows = await _fetch('scheduled_payments', {
      'id': 'eq.$id',
      'select': '*',
    });
    if (rows.isEmpty) {
      return null;
    }
    return _scheduledPaymentFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchScheduledPayments({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'scheduled_payments',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_scheduledPaymentFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertScheduledPayment(Map<String, dynamic> json) async {
    await _upsert('scheduled_payments', _scheduledPaymentToRow(json));
  }

  @override
  Future<Map<String, dynamic>?> fetchWallet(String id) async {
    final rows = await _fetch('wallets', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _walletFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWallets({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'wallets',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_walletFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertWallet(Map<String, dynamic> json) async {
    await _upsert('wallets', _walletToRow(json));
  }

  @override
  Future<Map<String, dynamic>?> fetchWalletTransfer(String id) async {
    final rows = await _fetch('wallet_transfers', {
      'id': 'eq.$id',
      'select': '*',
    });
    if (rows.isEmpty) {
      return null;
    }
    return _walletTransferFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWalletTransfers({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'wallet_transfers',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_walletTransferFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertWalletTransfer(Map<String, dynamic> json) async {
    await _upsert('wallet_transfers', _walletTransferToRow(json));
  }

  @override
  Future<Map<String, dynamic>?> fetchSavingsGoal(String id) async {
    final rows = await _fetch('savings_goals', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _savingsGoalFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSavingsGoals({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'savings_goals',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_savingsGoalFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertSavingsGoal(Map<String, dynamic> json) async {
    await _upsert('savings_goals', _savingsGoalToRow(json));
  }

  @override
  Future<Map<String, dynamic>?> fetchTransaction(String id) async {
    final rows = await _fetch('transactions', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _transactionFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTransactions({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'transactions',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_transactionFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertTransaction(Map<String, dynamic> json) async {
    await _upsert('transactions', _transactionToRow(json));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _delete('transactions', id);
  }

  @override
  Future<Map<String, dynamic>?> fetchDebt(String id) async {
    final rows = await _fetch('debts', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _debtFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDebts({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'debts',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_debtFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertDebt(Map<String, dynamic> json) async {
    await _upsert('debts', _debtToRow(json));
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _delete('debts', id);
  }

  @override
  Future<Map<String, dynamic>?> fetchBudget(String id) async {
    final rows = await _fetch('budgets', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _budgetFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBudgets({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'budgets',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_budgetFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertBudget(Map<String, dynamic> json) async {
    await _upsert('budgets', _budgetToRow(json));
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _delete('budgets', id);
  }

  @override
  Future<Map<String, dynamic>?> fetchReceivable(String id) async {
    final rows = await _fetch('receivables', {'id': 'eq.$id', 'select': '*'});
    if (rows.isEmpty) {
      return null;
    }
    return _receivableFromRow(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReceivables({
    DateTime? updatedAfter,
    int limit = 500,
    int offset = 0,
  }) async {
    final rows = await _fetch(
      'receivables',
      _updatedQuery(updatedAfter, limit: limit, offset: offset),
    );
    return rows.map(_receivableFromRow).toList(growable: false);
  }

  @override
  Future<void> upsertReceivable(Map<String, dynamic> json) async {
    await _upsert('receivables', _receivableToRow(json));
  }

  @override
  Future<void> deleteReceivable(String id) async {
    await _delete('receivables', id);
  }

  Map<String, String> _updatedQuery(
    DateTime? updatedAfter, {
    required int limit,
    required int offset,
  }) {
    return <String, String>{
      'select': '*',
      'limit': '$limit',
      'offset': '$offset',
      if (updatedAfter != null)
        'updated_at': 'gt.${updatedAfter.toUtc().toIso8601String()}',
      if (updatedAfter != null) 'order': 'updated_at.asc',
    };
  }

  Future<List<Map<String, dynamic>>> _fetch(
    String table,
    Map<String, String> query,
  ) async {
    _ensureConfigured();
    final response = await _send(
      () => _client.get(_uri(table, query), headers: _headers).timeout(timeout),
    );
    _ensureSuccess(response, const {200});

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ServerException(
        'Supabase returned an invalid payload.',
        code: 'supabase_invalid_response',
      );
    }
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> _upsert(String table, Map<String, dynamic> row) async {
    _ensureConfigured();
    final response = await _send(
      () => _client
          .post(
            _uri(table, {'on_conflict': 'id'}),
            headers: {
              ..._headers,
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode(row),
          )
          .timeout(timeout),
    );
    _ensureSuccess(response, const {200, 201, 204});
  }

  Future<void> _delete(String table, String id) async {
    _ensureConfigured();
    final response = await _send(
      () => _client
          .delete(_uri(table, {'id': 'eq.$id'}), headers: _headers)
          .timeout(timeout),
    );
    _ensureSuccess(response, const {200, 204});
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on ServerException {
      rethrow;
    } on TimeoutException {
      throw const ServerException(
        'The sync request timed out.',
        code: 'supabase_timeout',
      );
    } on http.ClientException {
      throw const ServerException(
        'Could not reach Supabase.',
        code: 'supabase_network_error',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('SYNC transport error: ${error.runtimeType}: $error');
      }
      throw const ServerException(
        'Could not reach Supabase.',
        code: 'supabase_network_error',
      );
    }
  }

  void _ensureSuccess(http.Response response, Set<int> allowed) {
    if (!allowed.contains(response.statusCode)) {
      throw ServerException(
        'Supabase request failed.',
        code: 'supabase_http_${response.statusCode}',
      );
    }
  }

  Uri _uri(String table, Map<String, String> query) {
    return Uri.parse('${_env.supabaseUrl}/rest/v1/$table')
        .replace(queryParameters: query);
  }

  Map<String, dynamic> _transactionToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'amount': json['amount'],
      'type': json['type'],
      'category': json['category'],
      'description': json['description'],
      'date': json['date'],
      'receipt_image_path': json['receiptImagePath'],
      'wallet_id': json['walletId'],
      'deleted_at': json['deletedAt'],
      'updated_at': json['updatedAt'] ?? json['date'],
    };
  }

  Map<String, dynamic> _transactionFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'amount': row['amount'],
      'type': row['type'],
      'category': row['category'],
      'description': row['description'],
      'date': row['date'],
      'receiptImagePath': row['receipt_image_path'],
      'walletId': row['wallet_id'],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _budgetToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'category': json['category'],
      'monthly_limit': json['monthlyLimit'],
      'month': json['month'],
      'deleted_at': json['deletedAt'],
      'updated_at': json['updatedAt'] ?? json['month'],
    };
  }

  Map<String, dynamic> _budgetFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'category': row['category'],
      'monthlyLimit': row['monthly_limit'],
      'month': row['month'],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _debtToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'creditor_name': json['creditorName'],
      'total_amount': json['totalAmount'],
      'remaining_amount': json['remainingAmount'],
      'interest_rate': json['interestRate'],
      'minimum_payment': json['minimumPayment'],
      'due_date': json['dueDate'],
      'status': json['status'],
      'payment_history': json['paymentHistory'] ?? const [],
      'deleted_at': json['deletedAt'],
      'updated_at': json['updatedAt'] ?? json['dueDate'],
    };
  }

  Map<String, dynamic> _receivableToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'debtor_name': json['debtorName'],
      'total_amount': json['totalAmount'],
      'remaining_amount': json['remainingAmount'],
      'date_lent': json['dateLent'],
      'due_date': json['dueDate'],
      'notes': json['notes'] ?? '',
      'status': json['status'],
      'payment_history': json['paymentHistory'] ?? const [],
      'created_at': json['createdAt'],
      'deleted_at': json['deletedAt'],
      'updated_at': json['updatedAt'] ?? json['dateLent'],
    };
  }

  Map<String, dynamic> _receivableFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'debtorName': row['debtor_name'],
      'totalAmount': row['total_amount'],
      'remainingAmount': row['remaining_amount'],
      'dateLent': row['date_lent'],
      'dueDate': row['due_date'],
      'notes': row['notes'] ?? '',
      'status': row['status'],
      'paymentHistory': row['payment_history'] ?? const [],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _debtFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'creditorName': row['creditor_name'],
      'totalAmount': row['total_amount'],
      'remainingAmount': row['remaining_amount'],
      'interestRate': row['interest_rate'],
      'minimumPayment': row['minimum_payment'],
      'dueDate': row['due_date'],
      'status': row['status'],
      'paymentHistory': row['payment_history'] ?? const [],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _categoryToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'name': json['name'],
      'is_archived': json['isArchived'] ?? false,
      'created_at': json['createdAt'],
      'updated_at': json['updatedAt'] ?? json['createdAt'],
      'deleted_at': json['deletedAt'],
    };
  }

  Map<String, dynamic> _categoryFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'name': row['name'],
      'isArchived': row['is_archived'] ?? false,
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _scheduledPaymentToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'name': json['name'],
      'amount': json['amount'],
      'type': json['type'] ?? 'expense',
      'category': json['category'],
      'frequency': json['frequency'],
      'next_due_date': json['nextDueDate'],
      'day_of_month': json['dayOfMonth'],
      'wallet_id': json['walletId'],
      'notes': json['notes'] ?? '',
      'is_active': json['isActive'] ?? true,
      'created_at': json['createdAt'],
      'updated_at': json['updatedAt'] ?? json['createdAt'],
      'last_paid_at': json['lastPaidAt'],
      'deleted_at': json['deletedAt'],
    };
  }

  Map<String, dynamic> _scheduledPaymentFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'name': row['name'],
      'amount': row['amount'],
      'type': row['type'] ?? 'expense',
      'category': row['category'],
      'frequency': row['frequency'],
      'nextDueDate': row['next_due_date'],
      'dayOfMonth': row['day_of_month'],
      'walletId': row['wallet_id'],
      'notes': row['notes'] ?? '',
      'isActive': row['is_active'] ?? true,
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'lastPaidAt': row['last_paid_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _walletToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'name': json['name'],
      'type': json['type'],
      'opening_balance': json['openingBalance'],
      'currency': json['currency'] ?? 'COP',
      'updated_at': json['updatedAt'],
      'deleted_at': json['deletedAt'],
    };
  }

  Map<String, dynamic> _walletFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'name': row['name'],
      'type': row['type'],
      'openingBalance': row['opening_balance'],
      'currency': row['currency'] ?? 'COP',
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _walletTransferToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'from_wallet_id': json['fromWalletId'],
      'to_wallet_id': json['toWalletId'],
      'amount': json['amount'],
      'date': json['date'],
      'note': json['note'] ?? '',
      'created_at': json['createdAt'],
      'updated_at': json['updatedAt'] ?? json['createdAt'],
      'deleted_at': json['deletedAt'],
    };
  }

  Map<String, dynamic> _walletTransferFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'fromWalletId': row['from_wallet_id'],
      'toWalletId': row['to_wallet_id'],
      'amount': row['amount'],
      'date': row['date'],
      'note': row['note'] ?? '',
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }

  Map<String, dynamic> _savingsGoalToRow(Map<String, dynamic> json) {
    return <String, dynamic>{
      'id': json['id'],
      'name': json['name'],
      'target_amount': json['targetAmount'],
      'target_date': json['targetDate'],
      'contributions': json['contributions'] ?? const [],
      'created_at': json['createdAt'],
      'updated_at': json['updatedAt'] ?? json['createdAt'],
      'deleted_at': json['deletedAt'],
    };
  }

  Map<String, dynamic> _savingsGoalFromRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'id': row['id'],
      'name': row['name'],
      'targetAmount': row['target_amount'],
      'targetDate': row['target_date'],
      'contributions': row['contributions'] ?? const [],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'deletedAt': row['deleted_at'],
      'isSynced': true,
    };
  }
}
