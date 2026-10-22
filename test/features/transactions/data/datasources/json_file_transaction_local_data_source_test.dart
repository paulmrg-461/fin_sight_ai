import 'dart:convert';
import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/json_file_transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final date = DateTime.utc(2026, 10, 20, 14, 30);

  TransactionModel buildModel({
    String id = 'tx-1',
    double amount = 10,
    bool isSynced = false,
  }) {
    return TransactionModel(
      id: id,
      amount: amount,
      date: date,
      category: 'Coffee',
      type: TransactionType.expense,
      note: 'Morning',
      isSynced: isSynced,
    );
  }

  late Directory tempDirectory;
  late File storeFile;
  late JsonFileTransactionLocalDataSource dataSource;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_tx_');
    storeFile = File(p.join(tempDirectory.path, 'nested', 'transactions.json'));
    dataSource = JsonFileTransactionLocalDataSource(storeFile);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<void> writeRaw(String contents) async {
    await storeFile.parent.create(recursive: true);
    await storeFile.writeAsString(contents);
  }

  group('JsonFileTransactionLocalDataSource', () {
    test('returns an empty list when the store does not exist', () async {
      // Act
      final transactions = await dataSource.getTransactions();

      // Assert
      expect(transactions, isEmpty);
      expect(await storeFile.exists(), isFalse);
    });

    test('persists a transaction and creates missing directories', () async {
      // Arrange
      final model = buildModel();

      // Act
      await dataSource.saveTransaction(model);
      final transactions = await dataSource.getTransactions();

      // Assert
      expect(transactions, [model]);
      expect(await storeFile.exists(), isTrue);
    });

    test('writes a versioned document for future migrations', () async {
      // Act
      await dataSource.saveTransaction(buildModel());

      // Assert
      final decoded =
          jsonDecode(await storeFile.readAsString()) as Map<String, dynamic>;
      expect(
        decoded['version'],
        JsonFileTransactionLocalDataSource.schemaVersion,
      );
      expect(decoded['transactions'], isA<List<dynamic>>());
    });

    test('replaces an existing transaction with the same id', () async {
      // Arrange
      await dataSource.saveTransaction(buildModel());
      final updated = buildModel(amount: 99, isSynced: true);

      // Act
      await dataSource.saveTransaction(updated);
      final transactions = await dataSource.getTransactions();

      // Assert
      expect(transactions, hasLength(1));
      expect(transactions.single.amount, 99);
      expect(transactions.single.isSynced, isTrue);
    });

    test('persists records across new data source instances', () async {
      // Arrange
      await dataSource.saveTransaction(buildModel(id: 'tx-a'));
      final secondInstance = JsonFileTransactionLocalDataSource(storeFile);

      // Act
      final transactions = await secondInstance.getTransactions();

      // Assert
      expect(transactions.map((model) => model.id), ['tx-a']);
    });

    test('serializes concurrent writes without losing records', () async {
      // Arrange
      final models = List.generate(
        25,
        (index) => buildModel(id: 'tx-$index', amount: index.toDouble() + 1),
      );

      // Act
      await Future.wait(models.map(dataSource.saveTransaction));
      final transactions = await dataSource.getTransactions();

      // Assert
      expect(transactions, hasLength(models.length));
      expect(
        transactions.map((model) => model.id).toSet(),
        models.map((model) => model.id).toSet(),
      );
    });

    test('treats a blank file as an empty store', () async {
      // Arrange
      await writeRaw('   \n');

      // Act
      final transactions = await dataSource.getTransactions();

      // Assert
      expect(transactions, isEmpty);
    });

    test('maps invalid JSON to a corrupted-store failure', () async {
      // Arrange
      await writeRaw('{not-json');

      // Act & Assert
      await expectLater(
        dataSource.getTransactions(),
        throwsA(
          isA<CacheException>().having(
            (exception) => exception.code,
            'code',
            'cache_corrupted',
          ),
        ),
      );
    });

    test(
      'maps a non-object root element to a corrupted-store failure',
      () async {
        // Arrange
        await writeRaw('[]');

        // Act & Assert
        await expectLater(
          dataSource.getTransactions(),
          throwsA(
            isA<CacheException>().having(
              (exception) => exception.code,
              'code',
              'cache_corrupted',
            ),
          ),
        );
      },
    );

    test(
      'maps a missing transactions array to a corrupted-store failure',
      () async {
        // Arrange
        await writeRaw('{"version":1}');

        // Act & Assert
        await expectLater(
          dataSource.getTransactions(),
          throwsA(isA<CacheException>()),
        );
      },
    );

    test('rejects an unsupported schema version', () async {
      // Arrange
      await writeRaw('{"version":2,"transactions":[]}');

      // Act & Assert
      await expectLater(
        dataSource.getTransactions(),
        throwsA(
          isA<CacheException>().having(
            (exception) => exception.code,
            'code',
            'cache_version_unsupported',
          ),
        ),
      );
    });

    test(
      'maps an invalid transaction entry to a corrupted-store failure',
      () async {
        // Arrange
        await writeRaw('{"version":1,"transactions":[{"id":"tx-only"}]}');

        // Act & Assert
        await expectLater(
          dataSource.getTransactions(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });
}
