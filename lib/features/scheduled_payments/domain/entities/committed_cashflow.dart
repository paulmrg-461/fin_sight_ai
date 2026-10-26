/// Where a committed payment comes from.
enum CommittedSource { scheduledPayment, debtMinimum }

/// One committed outflow inside a projection window.
class CommittedPayment {
  const CommittedPayment({
    required this.date,
    required this.name,
    required this.amount,
    required this.category,
    required this.source,
  });

  final DateTime date;
  final String name;
  final double amount;
  final String category;
  final CommittedSource source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommittedPayment &&
          other.date == date &&
          other.name == name &&
          other.amount == amount &&
          other.category == category &&
          other.source == source;

  @override
  int get hashCode => Object.hash(date, name, amount, category, source);

  @override
  String toString() => 'CommittedPayment($name, $amount, $date, $source)';
}

/// Outflows already committed between [start] and [end], inclusive.
class CommittedCashflow {
  const CommittedCashflow({
    required this.start,
    required this.end,
    required this.payments,
  });

  final DateTime start;
  final DateTime end;
  final List<CommittedPayment> payments;

  double get total =>
      payments.fold<double>(0, (sum, payment) => sum + payment.amount);

  bool get isEmpty => payments.isEmpty;

  /// First [count] payments, used by the compact card preview.
  List<CommittedPayment> take(int count) =>
      List<CommittedPayment>.unmodifiable(payments.take(count));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommittedCashflow &&
          other.start == start &&
          other.end == end &&
          _samePayments(other.payments, payments);

  @override
  int get hashCode => Object.hash(start, end, Object.hashAll(payments));

  @override
  String toString() =>
      'CommittedCashflow($start..$end, ${payments.length} payments, $total)';

  static bool _samePayments(
    List<CommittedPayment> a,
    List<CommittedPayment> b,
  ) {
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
}
