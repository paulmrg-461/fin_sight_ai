import '../../domain/entities/receipt_entity.dart';

/// Extracted receipt values before an id and image path are attached.
class ParsedReceipt {
  const ParsedReceipt({
    required this.merchantName,
    required this.date,
    required this.totalAmount,
    required this.items,
    required this.currency,
  });

  final String merchantName;
  final DateTime date;
  final double totalAmount;
  final List<ReceiptItem> items;
  final String currency;
}

/// Heuristic parser for OCR text from receipts.
///
/// It is deliberately tolerant: missing fields fall back to safe defaults so
/// the user can correct them in the preview instead of losing the scan.
class ReceiptParser {
  const ReceiptParser();

  static const List<String> _skipKeywords = [
    'subtotal',
    'total',
    'tax',
    'vat',
    'change',
    'cash',
    'card',
    'discount',
    'invoice',
    'receipt',
    'balance',
    'tip',
    'amount due',
  ];

  static const List<String> _currencyCodes = [
    'USD',
    'EUR',
    'GBP',
    'MXN',
    'COP',
    'ARS',
    'CLP',
    'PEN',
    'CAD',
    'JPY',
  ];

  static final RegExp _quantityItemPattern = RegExp(
    r"^(?<name>[A-Za-z][A-Za-z0-9 .,&'\-/]{1,}?)\s+"
    r"(?<qty>\d+(?:[.,]\d+)?)\s*[xX]\s*[^\d\-]*"
    r"(?<price>-?\d[\d.,]*)\s*$",
  );

  static final RegExp _simpleItemPattern = RegExp(
    r"^(?<name>[A-Za-z][A-Za-z0-9 .,&'\-/]{1,}?)\s+"
    r"[^\d\-]*(?<price>-?\d[\d.,]*)\s*$",
  );

  static final RegExp _isoDatePattern = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
  static final RegExp _shortDatePattern = RegExp(
    r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})',
  );
  static final RegExp _amountPattern = RegExp(r'-?\d[\d.,]*');

  ParsedReceipt parse(String rawText, {required DateTime now}) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return ParsedReceipt(
      merchantName: _detectMerchant(lines),
      date: _detectDate(lines) ?? now,
      totalAmount: _detectTotal(lines),
      items: _detectItems(lines),
      currency: _detectCurrency(rawText),
    );
  }

  String _detectMerchant(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_skipKeywords.any(lower.contains)) {
        continue;
      }
      final cleaned = line.replaceFirst(RegExp(r'^[^A-Za-z]+'), '').trim();
      if (cleaned.length >= 2 && RegExp('[A-Za-z]').hasMatch(cleaned)) {
        return cleaned;
      }
    }
    return 'Unknown merchant';
  }

  DateTime? _detectDate(List<String> lines) {
    for (final line in lines) {
      final isoMatch = _isoDatePattern.firstMatch(line);
      if (isoMatch != null) {
        final parsed = DateTime.tryParse(isoMatch.group(0)!);
        if (parsed != null) {
          return parsed;
        }
      }

      final shortMatch = _shortDatePattern.firstMatch(line);
      if (shortMatch == null) {
        continue;
      }

      final first = int.parse(shortMatch.group(1)!);
      final second = int.parse(shortMatch.group(2)!);
      var year = int.parse(shortMatch.group(3)!);
      if (year < 100) {
        year += 2000;
      }

      int day;
      int month;
      if (first > 12) {
        day = first;
        month = second;
      } else if (second > 12) {
        month = first;
        day = second;
      } else {
        // Ambiguous dates default to day/month, the most common receipt format.
        day = first;
        month = second;
      }

      final candidate = DateTime(year, month, day);
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        return candidate;
      }
    }
    return null;
  }

  double _detectTotal(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('total') && !lower.contains('subtotal')) {
        final amounts = _amountPattern.allMatches(line).toList();
        if (amounts.isNotEmpty) {
          final parsed = _parseAmount(amounts.last.group(0)!);
          if (parsed != null) {
            return _round(parsed.abs());
          }
        }
      }
    }

    final fallbackValues = <double>[];
    for (final line in lines) {
      for (final match in _amountPattern.allMatches(line)) {
        final parsed = _parseAmount(match.group(0)!);
        if (parsed != null && parsed.abs() > 0) {
          fallbackValues.add(parsed.abs());
        }
      }
    }
    if (fallbackValues.isEmpty) {
      return 0;
    }
    fallbackValues.sort();
    return _round(fallbackValues.last);
  }

  List<ReceiptItem> _detectItems(List<String> lines) {
    final items = <ReceiptItem>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_skipKeywords.any(lower.contains)) {
        continue;
      }

      final quantityMatch = _quantityItemPattern.firstMatch(line);
      if (quantityMatch != null) {
        final price = _parseAmount(quantityMatch.namedGroup('price')!);
        final quantity = _parseAmount(quantityMatch.namedGroup('qty')!);
        final name = quantityMatch.namedGroup('name')!.trim();
        if (price != null &&
            quantity != null &&
            quantity > 0 &&
            name.isNotEmpty) {
          items.add(
            ReceiptItem(
              name: name,
              quantity: quantity,
              price: _round(price.abs()),
            ),
          );
          continue;
        }
      }

      final simpleMatch = _simpleItemPattern.firstMatch(line);
      if (simpleMatch != null) {
        final name = simpleMatch.namedGroup('name')!.trim();
        final price = _parseAmount(simpleMatch.namedGroup('price')!);
        if (price != null && name.isNotEmpty) {
          items.add(
            ReceiptItem(name: name, quantity: 1, price: _round(price.abs())),
          );
        }
      }
    }

    return List<ReceiptItem>.unmodifiable(items);
  }

  String _detectCurrency(String rawText) {
    final upper = rawText.toUpperCase();
    for (final code in _currencyCodes) {
      if (RegExp('\\b$code\\b').hasMatch(upper)) {
        return code;
      }
    }
    if (upper.contains('€')) {
      return 'EUR';
    }
    if (upper.contains('£')) {
      return 'GBP';
    }
    if (upper.contains('¥')) {
      return 'JPY';
    }
    return 'USD';
  }

  double? _parseAmount(String raw) {
    var value = raw.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (value.isEmpty) {
      return null;
    }

    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');
    if (lastComma > -1 && lastDot > -1) {
      if (lastComma > lastDot) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (lastComma > -1) {
      final decimals = value.length - lastComma - 1;
      value = decimals == 2
          ? value.replaceAll(',', '.')
          : value.replaceAll(',', '');
    }

    return double.tryParse(value);
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));
}
