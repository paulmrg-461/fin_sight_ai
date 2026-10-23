import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 22);
  const milk = ReceiptItem(name: 'Milk', quantity: 2, price: 3.5);
  const bread = ReceiptItem(name: 'Bread', quantity: 1, price: 4.5);

  ReceiptEntity buildReceipt() {
    return ReceiptEntity(
      id: 'receipt-1',
      imagePath: '/tmp/receipt.jpg',
      merchantName: 'ACME MARKET',
      date: date,
      totalAmount: 11.5,
      items: const [milk, bread],
      currency: 'USD',
    );
  }

  group('ReceiptItem', () {
    test('computes the line total', () {
      expect(milk.lineTotal, 7);
    });

    test('supports copyWith and value equality', () {
      final updated = milk.copyWith(name: 'Oat milk');

      expect(updated.name, 'Oat milk');
      expect(updated.quantity, milk.quantity);
      expect(updated.price, milk.price);
      expect(updated, isNot(milk));
      expect(milk, const ReceiptItem(name: 'Milk', quantity: 2, price: 3.5));
    });

    test('toString exposes the item values', () {
      final description = milk.toString();

      expect(description, contains('Milk'));
      expect(description, contains('3.5'));
    });
  });

  group('ReceiptEntity', () {
    test('adds up the item totals', () {
      expect(buildReceipt().itemsTotal, 11.5);
    });

    test('copyWith replaces only provided fields', () {
      final original = buildReceipt();

      final updated = original.copyWith(merchantName: 'Corner Shop');

      expect(updated.merchantName, 'Corner Shop');
      expect(updated.id, original.id);
      expect(updated.items, original.items);
      expect(original.merchantName, 'ACME MARKET');
    });

    test('uses value equality including items', () {
      expect(buildReceipt(), buildReceipt());
      expect(
        buildReceipt(),
        isNot(buildReceipt().copyWith(items: const [milk])),
      );
      expect(buildReceipt().hashCode, buildReceipt().hashCode);
    });

    test('toString exposes merchant and total', () {
      final description = buildReceipt().toString();

      expect(description, contains('ACME MARKET'));
      expect(description, contains('11.5'));
    });
  });
}
