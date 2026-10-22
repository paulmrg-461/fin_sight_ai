import 'package:injectable/injectable.dart';

import '../models/transaction_model.dart';
import 'transaction_remote_data_source.dart';

/// Placeholder remote source used until the Supabase slice is configured.
///
/// Returning `false` keeps every record pending (`isSynced == false`) without
/// failing the local write.
@LazySingleton(as: TransactionRemoteDataSource)
class NoopTransactionRemoteDataSource implements TransactionRemoteDataSource {
  const NoopTransactionRemoteDataSource();

  @override
  Future<bool> uploadTransaction(TransactionModel transaction) async => false;
}
