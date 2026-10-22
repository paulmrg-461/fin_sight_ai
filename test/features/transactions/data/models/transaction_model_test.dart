import 'dart:convert';

import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 20, 14, 30);

  TransactionModel buildModel({
    String id = 'tx-1',
    double amount = 42.5,
    TransactionType type = TransactionType.expense,
    bool isSynced = false,
  }) {
    return TransactionModel(
      id: id,
      amount: amount,
      date: date,
      category: 'Groceries',
      type: type,
      note: 'Weekly shopping',
      isSynced: isSynced,
    );
  }

  group('TransactionModel', () {
    test('maps every field from an entity', () {
      // Arrange
      final entity = Transaction(
        id: 'tx-9',
        amount: 99.99,
        date: date,
        category: 'Salary',
        type: TransactionType.income,
        note: 'October',
        isSynced: true,
      );

      // Act
      final model = TransactionModel.fromEntity(entity);

      // Assert
      expect(model.id, entity.id);
      expect(model.amount, entity.amount);
      expect(model.date, entity.date);
      expect(model.category, entity.category);
      expect(model.type, entity.type);
      expect(model.note, entity.note);
      expect(model.isSynced, entity.isSynced);
    });

    test('maps every field back to an entity', () {
      // Arrange
      final model = buildModel(isSynced: true);

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity.id, model.id);
      expect(entity.amount, model.amount);
      expect(entity.date, model.date);
      expect(entity.category, model.category);
      expect(entity.type, model.type);
      expect(entity.note, model.note);
      expect(entity.isSynced, model.isSynced);
    });

    test('serializes dates as UTC ISO-8601 and types by name', () {
      // Arrange
      final model = buildModel();

      // Act
      final json = model.toJson();

      // Assert
      expect(json['date'], '2026-10-20T14:30:00.000Z');
      expect(json['type'], 'expense');
      expect(json['isSynced'], isFalse);
    });

    test('round-trips through real JSON encoding', () {
      // Arrange
      final model = buildModel(isSynced: true);

      // Act
      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = TransactionModel.fromJson(
        decoded as Map<String, dynamic>,
      );

      // Assert
      expect(restored, model);
      expect(restored.toEntity(), model.toEntity());
    });

    test('defaults optional fields when they are absent', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 'tx-2',
        'amount': 10,
        'date': '2026-10-20T00:00:00.000Z',
        'category': 'Coffee',
        'type': 'income',
      };

      // Act
      final model = TransactionModel.fromJson(json);

      // Assert
      expect(model.note, isEmpty);
      expect(model.isSynced, isFalse);
      expect(model.type, TransactionType.income);
    });

    test('copyWith replaces only the provided fields', () {
      // Arrange
      final original = buildModel();

      // Act
      final updated = original.copyWith(isSynced: true, amount: 10);

      // Assert
      expect(updated.isSynced, isTrue);
      expect(updated.amount, 10);
      expect(updated.id, original.id);
      expect(updated.note, original.note);
    });

    test('uses value equality across all fields', () {
      // Arrange
      final first = buildModel();
      final second = buildModel();
      final different = buildModel(isSynced: true);

      // Act & Assert
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    test('toString exposes the identifier, amount, and sync state', () {
      // Act
      final description = buildModel().toString();

      // Assert
      expect(description, contains('tx-1'));
      expect(description, contains('42.5'));
      expect(description, contains('isSynced: false'));
    });

    test('throws FormatException for an invalid identifier', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{'id': ''}),
        throwsFormatException,
      );
    });

    test('throws FormatException when the amount is not numeric', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-3',
          'amount': 'ten',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when the date is not a string', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-3',
          'amount': 10,
          'date': 123,
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when the category is missing', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-3',
          'amount': 10,
          'date': '2026-10-20T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException for an unknown transaction type', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-3',
          'amount': 10,
          'date': '2026-10-20T00:00:00.000Z',
          'category': 'Coffee',
          'type': 'transfer',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException for a malformed date string', () {
      expect(
        () => TransactionModel.fromJson(<String, dynamic>{
          'id': 'tx-3',
          'amount': 10,
          'date': 'not-a-date',
          'category': 'Coffee',
          'type': 'expense',
        }),
        throwsFormatException,
      );
    });
  });
}
