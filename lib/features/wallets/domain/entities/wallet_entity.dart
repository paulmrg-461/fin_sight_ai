import '../../../../core/domain/entity.dart';

/// Where money is held.
enum WalletType { bank, cash }

/// A money container: bank account or cash.
class WalletEntity extends Entity {
  const WalletEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    this.currency = 'USD',
    this.updatedAt,
  });

  @override
  final String id;

  final String name;
  final WalletType type;

  /// Balance before recorded movements. Adjusted when the user reconciles.
  final double openingBalance;
  final String currency;
  final DateTime? updatedAt;

  WalletEntity copyWith({
    String? id,
    String? name,
    WalletType? type,
    double? openingBalance,
    String? currency,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletEntity &&
          other.id == id &&
          other.name == name &&
          other.type == type &&
          other.openingBalance == openingBalance &&
          other.currency == currency &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, type, openingBalance, currency, updatedAt);

  @override
  String toString() => 'WalletEntity($name, $type, opening: $openingBalance)';
}

/// A transfer of money between two wallets.
class WalletTransferEntity extends Entity {
  const WalletTransferEntity({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note = '',
    this.createdAt,
  });

  @override
  final String id;

  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final DateTime date;
  final String note;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransferEntity &&
          other.id == id &&
          other.fromWalletId == fromWalletId &&
          other.toWalletId == toWalletId &&
          other.amount == amount &&
          other.date == date &&
          other.note == note &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, fromWalletId, toWalletId, amount, date, note, createdAt);

  @override
  String toString() =>
      'WalletTransferEntity($fromWalletId -> $toWalletId: $amount)';
}

/// Wallet plus its computed balance.
class WalletBalance {
  const WalletBalance({required this.wallet, required this.balance});

  final WalletEntity wallet;
  final double balance;

  String get name => wallet.name;
  WalletType get type => wallet.type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletBalance &&
          other.wallet == wallet &&
          other.balance == balance;

  @override
  int get hashCode => Object.hash(wallet, balance);

  @override
  String toString() => 'WalletBalance(${wallet.name}: $balance)';
}
