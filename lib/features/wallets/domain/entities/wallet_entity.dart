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
    this.isSynced = false,
    this.deletedAt,
  });

  @override
  final String id;

  final String name;
  final WalletType type;

  /// Balance before recorded movements. Adjusted when the user reconciles.
  final double openingBalance;
  final String currency;
  final DateTime? updatedAt;

  /// Whether the remote backend already accepted this record.
  final bool isSynced;

  /// Soft-delete tombstone. Hidden from queries but kept for synchronization.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DateTime get lastModified => updatedAt ?? _epoch;

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  WalletEntity copyWith({
    String? id,
    String? name,
    WalletType? type,
    double? openingBalance,
    String? currency,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
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
          other.updatedAt == updatedAt &&
          other.isSynced == isSynced &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    openingBalance,
    currency,
    updatedAt,
    isSynced,
    deletedAt,
  );

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
    this.updatedAt,
    this.isSynced = false,
    this.deletedAt,
  });

  @override
  final String id;

  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final DateTime date;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether the remote backend already accepted this record.
  final bool isSynced;

  /// Soft-delete tombstone. Hidden from queries but kept for synchronization.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DateTime get lastModified => updatedAt ?? createdAt ?? date;

  WalletTransferEntity copyWith({
    String? id,
    String? fromWalletId,
    String? toWalletId,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return WalletTransferEntity(
      id: id ?? this.id,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

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
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.isSynced == isSynced &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    fromWalletId,
    toWalletId,
    amount,
    date,
    note,
    createdAt,
    updatedAt,
    isSynced,
    deletedAt,
  );

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
