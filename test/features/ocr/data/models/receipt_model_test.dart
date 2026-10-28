import 'dart:convert';

import 'package:fin_sight_ai/features/ocr/data/models/receipt_model.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 22, 14, 30);

  ReceiptModel buildModel() {
    return ReceiptModel(
      id: 'receipt-1',
      imagePath: '/tmp/receipt.jpg',
      merchantName: 'ACME',
      date: date,
      totalAmount: 11.5,
      currency: 'USD',
      items: const [
        ReceiptItem(name: 'Milk', quantity: 2, price: 3.5),
        ReceiptItem(name: 'Bread', quantity: 1, price: 4.5),
      ],
    );
  }

  group('ReceiptModel', () {
    test('maps every field from an entity', () {
      final entity = ReceiptEntity(
        id: 'receipt-9',
        imagePath: '/tmp/a.jpg',
        merchantName: 'Shop',
        date: date,
        totalAmount: 5,
        items: const [ReceiptItem(name: 'Tea', quantity: 1, price: 5)],
        currency: 'EUR',
      );

      final model = ReceiptModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.imagePath, entity.imagePath);
      expect(model.merchantName, entity.merchantName);
      expect(model.date, entity.date);
      expect(model.totalAmount, entity.totalAmount);
      expect(model.currency, entity.currency);
      expect(model.items, entity.items);
    });

    test('maps back to an entity', () {
      final model = buildModel();

      final entity = model.toEntity();

      expect(entity, isA<ReceiptEntity>());
      expect(entity.id, model.id);
      expect(entity.items, model.items);
      expect(entity.currency, model.currency);
    });

    test('round-trips sync metadata', () {
      final model = ReceiptModel(
        id: 'receipt-1',
        imagePath: '/tmp/receipt.jpg',
        merchantName: 'ACME',
        date: date,
        totalAmount: 11.5,
        currency: 'USD',
        items: const [],
        updatedAt: DateTime.utc(2026, 10, 23, 9),
        isSynced: true,
      );

      final restored = ReceiptModel.fromJson(
        jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>,
      );

      expect(restored.updatedAt, DateTime.utc(2026, 10, 23, 9));
      expect(restored.isSynced, isTrue);
      expect(restored.lastModified, DateTime.utc(2026, 10, 23, 9));
    });

    test('serializes dates as UTC ISO-8601', () {
      final json = buildModel().toJson();

      expect(json['date'], '2026-10-22T14:30:00.000Z');
      expect(json['items'], isA<List<dynamic>>());
    });

    test('round-trips through real JSON encoding', () {
      final model = buildModel();

      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = ReceiptModel.fromJson(decoded as Map<String, dynamic>);

      expect(restored.toEntity(), model.toEntity());
    });

    test('throws FormatException for an invalid id', () {
      expect(
        () => ReceiptModel.fromJson(<String, dynamic>{'id': ''}),
        throwsFormatException,
      );
    });

    test('throws FormatException for missing items', () {
      final json = buildModel().toJson()..remove('items');

      expect(() => ReceiptModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for an invalid item entry', () {
      final json = buildModel().toJson()
        ..['items'] = [
          <String, dynamic>{'name': 'Milk'},
        ];

      expect(() => ReceiptModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for a malformed date', () {
      final json = buildModel().toJson()..['date'] = 'not-a-date';

      expect(() => ReceiptModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for an invalid amount', () {
      final json = buildModel().toJson()..['totalAmount'] = 'ten';

      expect(() => ReceiptModel.fromJson(json), throwsFormatException);
    });
  });
}
