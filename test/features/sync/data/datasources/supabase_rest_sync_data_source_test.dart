import 'dart:convert';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/supabase_rest_sync_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

AppEnv configuredEnv() => const AppEnv(
  supabaseUrl: 'https://demo.supabase.co',
  supabaseAnonKey: 'anon-key',
  groqApiKey: '',
);

Map<String, dynamic> transactionRow({String id = 'tx-1'}) => {
  'id': id,
  'amount': 10.5,
  'type': 'expense',
  'category': 'Food',
  'description': 'Lunch',
  'date': '2026-10-22T12:00:00.000Z',
  'receipt_image_path': '/tmp/r.jpg',
  'wallet_id': 'wallet-bank',
  'updated_at': '2026-10-22T12:05:00.000Z',
};

Map<String, dynamic> budgetRow({String id = 'budget-1'}) => {
  'id': id,
  'category': 'Food',
  'monthly_limit': 100,
  'month': '2026-10-01T00:00:00.000Z',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'deleted_at': null,
};

Map<String, dynamic> debtRow({String id = 'debt-1'}) => {
  'id': id,
  'creditor_name': 'Bank',
  'total_amount': 1000,
  'remaining_amount': 600,
  'interest_rate': 12,
  'minimum_payment': 100,
  'due_date': '2026-12-01T00:00:00.000Z',
  'status': 'active',
  'payment_history': [
    {'id': 'p-1', 'amount': 100, 'paidAt': '2026-10-01T00:00:00.000Z'},
  ],
  'updated_at': '2026-10-22T12:05:00.000Z',
};

Map<String, dynamic> receivableRow({String id = 'receivable-1'}) => {
  'id': id,
  'debtor_name': 'Ana',
  'total_amount': 1000,
  'remaining_amount': 600,
  'date_lent': '2026-10-01T00:00:00.000Z',
  'due_date': '2026-12-01T00:00:00.000Z',
  'notes': 'Lunch loan',
  'status': 'active',
  'payment_history': [
    {
      'id': 'p-1',
      'amount': 400,
      'paidAt': '2026-10-10T00:00:00.000Z',
      'note': 'Cash',
    },
  ],
  'created_at': '2026-10-01T09:00:00.000Z',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'deleted_at': null,
};

Map<String, dynamic> categoryRow() => {
  'id': 'cat-1',
  'name': 'Coffee',
  'is_archived': true,
  'created_at': '2026-10-01T00:00:00.000Z',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'deleted_at': null,
};

Map<String, dynamic> scheduleRow() => {
  'id': 'pay-1',
  'name': 'Rent',
  'amount': 800,
  'type': 'expense',
  'category': 'Rent',
  'frequency': 'monthly',
  'next_due_date': '2026-11-01T00:00:00.000Z',
  'day_of_month': 1,
  'wallet_id': 'wallet-bank',
  'notes': 'Monthly',
  'is_active': true,
  'created_at': '2026-10-01T00:00:00.000Z',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'last_paid_at': null,
  'deleted_at': null,
};

Map<String, dynamic> walletRow() => {
  'id': 'wallet-bank',
  'name': 'Bank',
  'type': 'bank',
  'opening_balance': 100,
  'currency': 'COP',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'deleted_at': null,
};

Map<String, dynamic> transferRow() => {
  'id': 't-1',
  'from_wallet_id': 'wallet-bank',
  'to_wallet_id': 'wallet-cash',
  'amount': 25,
  'date': '2026-10-22T00:00:00.000Z',
  'note': 'ATM',
  'created_at': '2026-10-22T00:00:00.000Z',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'deleted_at': null,
};

Map<String, dynamic> savingsGoalRow() => {
  'id': 'goal-1',
  'name': 'Trip',
  'target_amount': 1000,
  'target_date': '2027-01-01T00:00:00.000Z',
  'contributions': [
    {'id': 'c-1', 'amount': 400, 'date': '2026-10-02T00:00:00.000Z'},
  ],
  'created_at': '2026-10-01T00:00:00.000Z',
  'updated_at': '2026-10-22T12:05:00.000Z',
  'deleted_at': null,
};

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
    when(() => auth.isAuthenticated).thenReturn(true);
    when(() => auth.accessToken).thenReturn('access-token');
  });

  group('SupabaseRestSyncDataSource', () {
    test('rejects calls without Supabase credentials', () async {
      final client = MockClient((request) async {
        fail('HTTP must not be called when unconfigured');
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        const AppEnv(supabaseUrl: '', supabaseAnonKey: '', groqApiKey: ''),
        auth,
      );

      await expectLater(
        datasource.fetchTransaction('tx-1'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'supabase_not_configured',
          ),
        ),
      );
    });

    test('rejects calls without an authenticated session', () async {
      when(() => auth.isAuthenticated).thenReturn(false);
      when(() => auth.accessToken).thenReturn(null);
      final client = MockClient((request) async {
        fail('HTTP must not be called without a session');
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await expectLater(
        datasource.fetchTransaction('tx-1'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'supabase_unauthenticated',
          ),
        ),
      );
    });

    test('fetches and maps a transaction', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode([transactionRow()]), 200);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final row = await datasource.fetchTransaction('tx-1');

      expect(row, isNotNull);
      expect(row!['id'], 'tx-1');
      expect(row['receiptImagePath'], '/tmp/r.jpg');
      expect(row['walletId'], 'wallet-bank');
      expect(row['updatedAt'], '2026-10-22T12:05:00.000Z');
      expect(row['isSynced'], isTrue);
      expect(captured.url.path, '/rest/v1/transactions');
      expect(captured.url.queryParameters['id'], 'eq.tx-1');
      expect(captured.headers['apikey'], 'anon-key');
    });

    test('returns null when the remote row does not exist', () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode([]), 200),
      );
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      expect(await datasource.fetchTransaction('missing'), isNull);
    });

    test('fetches transactions updated after a timestamp', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode([transactionRow()]), 200);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final rows = await datasource.fetchTransactions(
        updatedAfter: DateTime.utc(2026, 10, 1),
      );

      expect(rows, hasLength(1));
      expect(
        captured.url.queryParameters['updated_at'],
        'gt.2026-10-01T00:00:00.000Z',
      );
      expect(captured.url.queryParameters['order'], 'updated_at.asc');
      expect(captured.url.queryParameters['limit'], '500');
      expect(captured.url.queryParameters['offset'], '0');
    });

    test('passes pagination parameters to PostgREST', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode([]), 200);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.fetchReceivables(limit: 250, offset: 500);

      expect(captured.url.queryParameters['limit'], '250');
      expect(captured.url.queryParameters['offset'], '500');
    });

    test('upserts a transaction using snake_case columns', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 201);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.upsertTransaction({
        'id': 'tx-1',
        'amount': 10,
        'type': 'expense',
        'category': 'Food',
        'description': 'Lunch',
        'date': '2026-10-22T12:00:00.000Z',
        'receiptImagePath': '/tmp/r.jpg',
        'walletId': 'wallet-bank',
        'updatedAt': '2026-10-22T12:05:00.000Z',
        'isSynced': false,
      });

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['receipt_image_path'], '/tmp/r.jpg');
      expect(body['wallet_id'], 'wallet-bank');
      expect(body['updated_at'], '2026-10-22T12:05:00.000Z');
      expect(body.containsKey('isSynced'), isFalse);
      expect(captured.url.queryParameters['on_conflict'], 'id');
      expect(captured.headers['Prefer'], contains('merge-duplicates'));
    });

    test('deletes a transaction', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.deleteTransaction('tx-1');

      expect(captured.method, 'DELETE');
      expect(captured.url.queryParameters['id'], 'eq.tx-1');
    });

    test('fetches and maps debts with payment history', () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode([debtRow()]), 200),
      );
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final row = await datasource.fetchDebt('debt-1');

      expect(row!['creditorName'], 'Bank');
      expect(row['dueDate'], '2026-12-01T00:00:00.000Z');
      final history = row['paymentHistory'] as List<dynamic>;
      expect(history, hasLength(1));
      expect(row['isSynced'], isTrue);
    });

    test('upserts a debt using snake_case columns', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 200);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.upsertDebt({
        'id': 'debt-1',
        'creditorName': 'Bank',
        'totalAmount': 1000,
        'remainingAmount': 600,
        'interestRate': 12,
        'minimumPayment': 100,
        'dueDate': '2026-12-01T00:00:00.000Z',
        'status': 'active',
        'paymentHistory': const [],
        'updatedAt': '2026-10-22T12:05:00.000Z',
      });

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['creditor_name'], 'Bank');
      expect(body['remaining_amount'], 600);
      expect(body['payment_history'], isEmpty);
    });

    test('fetches and maps budgets', () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode([budgetRow()]), 200),
      );
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final row = await datasource.fetchBudget('budget-1');

      expect(row!['category'], 'Food');
      expect(row['monthlyLimit'], 100);
      expect(row['isSynced'], isTrue);
    });

    test('upserts a budget using snake_case columns', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 201);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.upsertBudget({
        'id': 'budget-1',
        'category': 'Food',
        'monthlyLimit': 100,
        'month': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-22T12:05:00.000Z',
        'deletedAt': null,
      });

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['monthly_limit'], 100);
      expect(body['month'], '2026-10-01T00:00:00.000Z');
      expect(body['updated_at'], '2026-10-22T12:05:00.000Z');
    });

    test('fetches and maps receivables', () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode([receivableRow()]), 200),
      );
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final row = await datasource.fetchReceivable('receivable-1');

      expect(row!['debtorName'], 'Ana');
      expect(row['remainingAmount'], 600);
      expect(row['status'], 'active');
      expect((row['paymentHistory'] as List), hasLength(1));
      expect(row['isSynced'], isTrue);
    });

    test('upserts a receivable using snake_case columns', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 201);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.upsertReceivable({
        'id': 'receivable-1',
        'debtorName': 'Ana',
        'totalAmount': 1000,
        'remainingAmount': 600,
        'dateLent': '2026-10-01T00:00:00.000Z',
        'dueDate': '2026-12-01T00:00:00.000Z',
        'notes': 'Lunch loan',
        'status': 'active',
        'paymentHistory': const [],
        'createdAt': '2026-10-01T09:00:00.000Z',
        'updatedAt': '2026-10-22T12:05:00.000Z',
        'deletedAt': null,
      });

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['debtor_name'], 'Ana');
      expect(body['remaining_amount'], 600);
      expect(body['date_lent'], '2026-10-01T00:00:00.000Z');
      expect(body['payment_history'], isEmpty);
    });

    test('deletes receivables by id', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await datasource.deleteReceivable('receivable-1');

      expect(captured.method, 'DELETE');
      expect(captured.url.queryParameters['id'], 'eq.receivable-1');
    });

    test('maps non-2xx responses to an HTTP failure', () async {
      final client = MockClient(
        (request) async => http.Response('forbidden', 403),
      );
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await expectLater(
        datasource.fetchDebts(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'supabase_http_403',
          ),
        ),
      );
    });

    test('rejects invalid response payloads', () async {
      final client = MockClient(
        (request) async => http.Response('{"not":"a list"}', 200),
      );
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await expectLater(
        datasource.fetchTransactions(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'supabase_invalid_response',
          ),
        ),
      );
    });

    test('maps network errors to a stable code', () async {
      final client = MockClient((request) async {
        throw http.ClientException('offline');
      });
      final datasource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      await expectLater(
        datasource.fetchTransactions(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'supabase_network_error',
          ),
        ),
      );
    });

    test('maps category rows in both directions', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode([categoryRow()]), 200);
        }
        return http.Response('', 204);
      });
      final dataSource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final rows = await dataSource.fetchCategories();
      expect(rows.single['isArchived'], isTrue);
      expect(rows.single['isSynced'], isTrue);

      await dataSource.upsertCategory({
        'id': 'cat-1',
        'name': 'Coffee',
        'isArchived': false,
        'createdAt': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-22T12:05:00.000Z',
      });

      expect(requests.first.url.path, '/rest/v1/categories');
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['is_archived'], isFalse);
      expect(body['deleted_at'], isNull);
    });

    test('maps scheduled payment rows in both directions', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode([scheduleRow()]), 200);
        }
        return http.Response('', 201);
      });
      final dataSource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final rows = await dataSource.fetchScheduledPayments();
      expect(rows.single['nextDueDate'], '2026-11-01T00:00:00.000Z');
      expect(rows.single['dayOfMonth'], 1);
      expect(rows.single['isActive'], isTrue);

      await dataSource.upsertScheduledPayment({
        'id': 'pay-1',
        'name': 'Rent',
        'amount': 800,
        'type': 'expense',
        'category': 'Rent',
        'frequency': 'monthly',
        'nextDueDate': '2026-11-01T00:00:00.000Z',
        'dayOfMonth': 1,
        'walletId': 'wallet-bank',
        'notes': 'Monthly',
        'isActive': true,
        'createdAt': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-22T12:05:00.000Z',
      });

      expect(requests.last.url.path, '/rest/v1/scheduled_payments');
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['next_due_date'], '2026-11-01T00:00:00.000Z');
      expect(body['is_active'], isTrue);
      expect(body['wallet_id'], 'wallet-bank');
    });

    test('maps wallet rows in both directions', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode([walletRow()]), 200);
        }
        return http.Response('', 204);
      });
      final dataSource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final rows = await dataSource.fetchWallets();
      expect(rows.single['openingBalance'], 100);
      expect(rows.single['currency'], 'COP');

      await dataSource.upsertWallet({
        'id': 'wallet-bank',
        'name': 'Bank',
        'type': 'bank',
        'openingBalance': 100,
        'currency': 'COP',
        'updatedAt': '2026-10-22T12:05:00.000Z',
      });

      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['opening_balance'], 100);
      expect(body['deleted_at'], isNull);
    });

    test('maps wallet transfer rows in both directions', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode([transferRow()]), 200);
        }
        return http.Response('', 204);
      });
      final dataSource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final rows = await dataSource.fetchWalletTransfers();
      expect(rows.single['fromWalletId'], 'wallet-bank');
      expect(rows.single['toWalletId'], 'wallet-cash');

      await dataSource.upsertWalletTransfer({
        'id': 't-1',
        'fromWalletId': 'wallet-bank',
        'toWalletId': 'wallet-cash',
        'amount': 25,
        'date': '2026-10-22T00:00:00.000Z',
        'note': 'ATM',
        'createdAt': '2026-10-22T00:00:00.000Z',
        'updatedAt': '2026-10-22T12:05:00.000Z',
      });

      expect(requests.last.url.path, '/rest/v1/wallet_transfers');
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['from_wallet_id'], 'wallet-bank');
      expect(body['to_wallet_id'], 'wallet-cash');
    });

    test('maps savings goal rows in both directions', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode([savingsGoalRow()]), 200);
        }
        return http.Response('', 204);
      });
      final dataSource = SupabaseRestSyncDataSource(
        client,
        configuredEnv(),
        auth,
      );

      final rows = await dataSource.fetchSavingsGoals();
      expect(rows.single['targetAmount'], 1000);
      expect((rows.single['contributions'] as List), hasLength(1));

      await dataSource.upsertSavingsGoal({
        'id': 'goal-1',
        'name': 'Trip',
        'targetAmount': 1000,
        'targetDate': '2027-01-01T00:00:00.000Z',
        'contributions': const [],
        'createdAt': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-22T12:05:00.000Z',
      });

      expect(requests.last.url.path, '/rest/v1/savings_goals');
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['target_amount'], 1000);
      expect(body['deleted_at'], isNull);
    });
  });
}
