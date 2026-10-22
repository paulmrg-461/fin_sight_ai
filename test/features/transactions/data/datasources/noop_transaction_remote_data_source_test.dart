import 'package:fin_sight_ai/features/transactions/data/datasources/noop_transaction_remote_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports every upload as pending so records can sync later', () async {
    // Arrange
    const dataSource = NoopTransactionRemoteDataSource();
    final model = TransactionModel(
      id: 'tx-1',
      amount: 10,
      date: DateTime.utc(2026, 10, 20),
      category: 'Coffee',
      type: TransactionType.expense,
      note: '',
      isSynced: false,
    );

    // Act
    final uploaded = await dataSource.uploadTransaction(model);

    // Assert
    expect(uploaded, isFalse);
  });
}
