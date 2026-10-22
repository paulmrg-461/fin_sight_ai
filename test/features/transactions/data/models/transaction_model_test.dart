import 'dart:convert';

import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 20, 14, 30);

  TransactionModel buildModel({bool withReceipt = true}) {
    return TransactionModel(
      id: 'tx-1',
      amount: 42.5,
      type: TransactionType.expense,
      category: 'Groceries',
      description: 'Weekly shopping',
      date: date,
      receiptImagePath: withReceipt ? '/tmp/receipt.jpg' : null,
    );
  }

  group('TransactionModel', () {
    test('maps every field from an entity', () {
      final entity = TransactionEntity(
        id: 'tx-9',
        amount: 99.99,
        type: TransactionType.income,
        category: 'Salary',
        description: 'October',
        date: date,
        receiptImagePath: '/tmp/salary.pdf',
      );

      final model = TransactionModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.amount, entity.amount);
      expect(model.type, entity.type);
      expect(model.category, entity.category);
      expect(model.description, entity.description);
      expect(model.date, entity.date);
      expect(model.receiptImagePath, entity.receiptImagePath);
    });

    test('maps back to an entity', () {
      final model = buildModel();

      final entity = model.toEntity();

      expect(entity, isA<TransactionEntity>());
      expect(entity.id, model.id);
      expect(entity.amount, model.amount);
      expect(entity.type, model.type);
      expect(entity.category, model.category);
      expect(entity.description, model.description);
      expect(entity.date, model.date);
      expect(entity.receiptImagePath, model.receiptImagePath);
    });

    test('serializes dates as UTC ISO-8601 and type by name', () {
      final json = buildModel().toJson();

      expect(json['date'], '2026-10-20T14:30:00.000Z');
      expect(json['type'], 'expense');
      expect(json['receiptImagePath'], '/tmp/receipt.jpg');
    });

    test('round-trips through real JSON encoding', () {
      final model = buildModel();

      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = TransactionModel.fromJson(
        decoded as Map<String, dynamic>,
      );

      expect(restored.toEntity(), model.toEntity());
    });

    test('supports a null receipt image path', () {
      final json = buildModel(withReceipt: false).toJson();

      expect(json['receiptImagePath'], isNull);
      expect(TransactionModel.fromJson(json).receiptImagePath, isNull);
    });

    test('throws FormatException for an invalid id', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{'id': ''}),
        throwsFormatException,
      );
    });

    test('throws FormatException for a non-numeric amount', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-1',
          'amount': 'ten',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException for an unknown type', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-1',
          'amount': 10,
          'type': 'transfer',
          'category': 'Coffee',
          'description': '',
          'date': '2026-10-20T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException for a missing description', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-1',
          'amount': 10,
          'type': 'expense',
          'category': 'Coffee',
          'date': '2026-10-20T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException for a malformed date', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-1',
          'amount': 10,
          'type': 'expense',
          'category': 'Coffee',
          'description': '',
          'date': 'not-a-date',
        }),
        throwsFormatException,
      );
    });
  });
}
