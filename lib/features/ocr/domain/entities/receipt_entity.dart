import '../../../../core/domain/entity.dart';

/// A single line item extracted from a receipt.
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final double quantity;

  /// Unit price.
  final double price;

  double get lineTotal => quantity * price;

  ReceiptItem copyWith({String? name, double? quantity, double? price}) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItem &&
          other.name == name &&
          other.quantity == quantity &&
          other.price == price;

  @override
  int get hashCode => Object.hash(name, quantity, price);

  @override
  String toString() =>
      'ReceiptItem(name: $name, quantity: $quantity, price: $price)';
}

/// Pure domain representation of a scanned receipt.
class ReceiptEntity extends Entity {
  const ReceiptEntity({
    required this.id,
    required this.imagePath,
    required this.merchantName,
    required this.date,
    required this.totalAmount,
    required this.items,
    required this.currency,
  });

  @override
  final String id;

  final String imagePath;
  final String merchantName;
  final DateTime date;
  final double totalAmount;
  final List<ReceiptItem> items;

  /// ISO-4217 code, normalized to uppercase.
  final String currency;

  double get itemsTotal =>
      items.fold(0, (total, item) => total + item.lineTotal);

  ReceiptEntity copyWith({
    String? id,
    String? imagePath,
    String? merchantName,
    DateTime? date,
    double? totalAmount,
    List<ReceiptItem>? items,
    String? currency,
  }) {
    return ReceiptEntity(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptEntity &&
          other.id == id &&
          other.imagePath == imagePath &&
          other.merchantName == merchantName &&
          other.date == date &&
          other.totalAmount == totalAmount &&
          other.currency == currency &&
          _sameItems(other.items, items);

  @override
  int get hashCode => Object.hash(
    id,
    imagePath,
    merchantName,
    date,
    totalAmount,
    currency,
    Object.hashAll(items),
  );

  static bool _sameItems(List<ReceiptItem> a, List<ReceiptItem> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'ReceiptEntity(id: $id, merchant: $merchantName, '
      'total: $totalAmount $currency)';
}
