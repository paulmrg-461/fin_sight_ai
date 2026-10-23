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
  });
}
