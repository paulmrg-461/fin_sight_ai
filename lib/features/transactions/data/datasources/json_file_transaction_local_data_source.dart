import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';
import 'transaction_local_data_source.dart';

/// JSON-file backed implementation of [TransactionLocalDataSource].
///
/// The file is a single versioned document:
///
/// ```json
/// {"version": 1, "transactions": [ ... ]}
/// ```
///
/// Writes are atomic (temp file + rename) and serialized through an internal
/// mutex so concurrent async writes cannot lose records.
class JsonFileTransactionLocalDataSource implements TransactionLocalDataSource {
  JsonFileTransactionLocalDataSource(this._file);

  static const int schemaVersion = 1;

  final File _file;
  Future<void> _tail = Future<void>.value();

  @override
  Future<List<TransactionModel>> getTransactions() => _synchronized(_readAll);

  @override
  Future<void> saveTransaction(TransactionModel transaction) =>
      _synchronized(() async {
        final transactions = await _readAll();
        final index = transactions.indexWhere(
          (existing) => existing.id == transaction.id,
        );
        if (index == -1) {
          transactions.add(transaction);
        } else {
          transactions[index] = transaction;
        }
        await _writeAll(transactions);
      });

  Future<List<TransactionModel>> _readAll() async {
    try {
      if (!await _file.exists()) {
        return <TransactionModel>[];
      }

      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) {
        return <TransactionModel>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root element must be a JSON object.');
      }

      final version = decoded['version'];
      if (version is int && version > schemaVersion) {
        throw CacheException(
          'Unsupported local store version: $version.',
          code: 'cache_version_unsupported',
        );
      }

      final entries = decoded['transactions'];
      if (entries is! List) {
        throw const FormatException('Transactions must be a JSON array.');
      }

      return entries
          .map((entry) {
            if (entry is! Map<String, dynamic>) {
              throw const FormatException('Invalid transaction entry.');
            }
            return TransactionModel.fromJson(entry);
          })
          .toList(growable: true);
    } on CacheException {
      rethrow;
    } catch (_) {
      throw const CacheException(
        'The local transaction store is corrupted.',
        code: 'cache_corrupted',
      );
    }
  }

  Future<void> _writeAll(List<TransactionModel> transactions) async {
    try {
      await _file.parent.create(recursive: true);

      final payload = jsonEncode(<String, dynamic>{
        'version': schemaVersion,
        'transactions': transactions
            .map((transaction) => transaction.toJson())
            .toList(),
      });

      final temporaryFile = File('${_file.path}.tmp');
      await temporaryFile.writeAsString(payload, flush: true);
      await temporaryFile.rename(_file.path);
    } catch (_) {
      throw const CacheException(
        'Unable to persist transactions locally.',
        code: 'cache_write_failed',
      );
    }
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
