import '../currency/app_currency.dart';

/// Exact monetary amount stored as integer minor units (cents).
///
/// New ledger code should use this type instead of `double`. It exists as the
/// first phase of the integer-money migration; entities adopt it slice by
/// slice (see `specs/SPEC-money-minor-units.md`).
final class Money implements Comparable<Money> {
  const Money(this.minorUnits);

  static const Money zero = Money(0);

  final int minorUnits;

  /// Legacy bridge for data that still stores major units.
  factory Money.fromMajor(num major) => Money((major * 100).round());

  /// Reads `minorUnits` when present, falling back to legacy major amounts.
  factory Money.fromJson(Object? value) {
    if (value is int) {
      return Money(value);
    }
    if (value is num) {
      return Money.fromMajor(value);
    }
    if (value is Map) {
      final minor = value['minorUnits'];
      if (minor is int) {
        return Money(minor);
      }
      final major = value['amount'];
      if (major is num) {
        return Money.fromMajor(major);
      }
    }
    throw const FormatException('Invalid money value.');
  }

  /// Parses user input such as `1.234,56` (COP) or `1,234.56` (USD).
  ///
  /// Throws [FormatException] for empty input or more than two decimals.
  factory Money.parse(String input, {required AppCurrency currency}) {
    var text = input
        .replaceAll('\u00A0', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (text.isEmpty) {
      throw const FormatException('Amount is empty.');
    }

    var negative = false;
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    }
    if (text.contains('-')) {
      throw const FormatException('Amount is invalid.');
    }

    final decimalSeparator = currency == AppCurrency.cop ? ',' : '.';
    final groupSeparator = currency == AppCurrency.cop ? '.' : ',';

    if (text.contains(decimalSeparator)) {
      final parts = text.split(decimalSeparator);
      if (parts.length != 2 || parts.last.length > 2) {
        throw const FormatException('Amount has too many decimals.');
      }
      text = '${parts.first.replaceAll(groupSeparator, '')}.${parts.last}';
    } else {
      text = text.replaceAll(groupSeparator, '');
    }

    if (text.isEmpty || !RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text)) {
      throw const FormatException('Amount is invalid.');
    }

    final parts = text.split('.');
    final whole = int.parse(parts.first);
    if (whole > 90000000000000) {
      throw const FormatException('Amount is too large.');
    }
    final cents = parts.length == 2
        ? int.parse(parts.last.padRight(2, '0'))
        : 0;
    final minor = whole * 100 + cents;
    return Money(negative ? -minor : minor);
  }

  /// Major units for formatting and chart boundaries. Never use for math.
  double get major => minorUnits / 100;

  String format(AppCurrency currency) => MoneyFormatter.format(major, currency);

  String toDecimalString() {
    final sign = minorUnits < 0 ? '-' : '';
    final absolute = minorUnits.abs();
    final cents = (absolute % 100).toString().padLeft(2, '0');
    return '$sign${absolute ~/ 100}.$cents';
  }

  Money operator +(Money other) => Money(minorUnits + other.minorUnits);

  Money operator -(Money other) => Money(minorUnits - other.minorUnits);

  Money operator -() => Money(-minorUnits);

  Money operator *(int factor) => Money(minorUnits * factor);

  bool operator <(Money other) => minorUnits < other.minorUnits;

  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  bool operator >(Money other) => minorUnits > other.minorUnits;

  bool operator >=(Money other) => minorUnits >= other.minorUnits;

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => 'Money(${toDecimalString()})';
}
