import '../../domain/entities/receipt_entity.dart';

/// Data-transfer representation of [ReceiptEntity].
class ReceiptModel extends ReceiptEntity {
  const ReceiptModel({
    required super.id,
    required super.imagePath,
    required super.merchantName,
    required super.date,
    required super.totalAmount,
    required super.items,
    required super.currency,
  });

  factory ReceiptModel.fromEntity(ReceiptEntity receipt) {
    return ReceiptModel(
      id: receipt.id,
      imagePath: receipt.imagePath,
      merchantName: receipt.merchantName,
      date: receipt.date,
      totalAmount: receipt.totalAmount,
      items: receipt.items,
      currency: receipt.currency,
    );
  }

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final imagePath = json['imagePath'];
    final merchantName = json['merchantName'];
    final date = json['date'];
    final totalAmount = json['totalAmount'];
    final currency = json['currency'];
    final items = json['items'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Receipt id is missing or invalid.');
    }
    if (imagePath is! String) {
      throw const FormatException('Receipt image path is missing or invalid.');
    }
    if (merchantName is! String) {
      throw const FormatException('Receipt merchant is missing or invalid.');
    }
    if (date is! String) {
      throw const FormatException('Receipt date is missing or invalid.');
    }
    if (totalAmount is! num) {
      throw const FormatException('Receipt total is missing or invalid.');
    }
    if (currency is! String || currency.isEmpty) {
      throw const FormatException('Receipt currency is missing or invalid.');
    }
    if (items is! List) {
      throw const FormatException('Receipt items must be a list.');
    }

    final parsedItems = <ReceiptItem>[];
    for (final entry in items) {
      if (entry is! Map) {
        throw const FormatException('Invalid receipt item.');
      }
      parsedItems.add(_itemFromJson(Map<String, dynamic>.from(entry)));
    }

    return ReceiptModel(
      id: id,
      imagePath: imagePath,
      merchantName: merchantName,
      date: DateTime.parse(date),
      totalAmount: totalAmount.toDouble(),
      items: List<ReceiptItem>.unmodifiable(parsedItems),
      currency: currency,
    );
  }

  static ReceiptItem _itemFromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final quantity = json['quantity'];
    final price = json['price'];

    if (name is! String || name.isEmpty) {
      throw const FormatException('Receipt item name is missing or invalid.');
    }
    if (quantity is! num || price is! num) {
      throw const FormatException(
        'Receipt item quantity or price is missing or invalid.',
      );
    }

    return ReceiptItem(
      name: name,
      quantity: quantity.toDouble(),
      price: price.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'imagePath': imagePath,
      'merchantName': merchantName,
      'date': date.toUtc().toIso8601String(),
      'totalAmount': totalAmount,
      'currency': currency,
      'items': items
          .map(
            (item) => <String, dynamic>{
              'name': item.name,
              'quantity': item.quantity,
              'price': item.price,
            },
          )
          .toList(),
    };
  }

  ReceiptEntity toEntity() {
    return ReceiptEntity(
      id: id,
      imagePath: imagePath,
      merchantName: merchantName,
      date: date,
      totalAmount: totalAmount,
      items: items,
      currency: currency,
    );
  }
}
