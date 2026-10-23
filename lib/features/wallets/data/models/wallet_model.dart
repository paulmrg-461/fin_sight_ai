import '../../domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.name,
    required super.type,
    required super.openingBalance,
    super.currency,
    super.updatedAt,
  });

  factory WalletModel.fromEntity(WalletEntity wallet) => WalletModel(
    id: wallet.id,
    name: wallet.name,
    type: wallet.type,
    openingBalance: wallet.openingBalance,
    currency: wallet.currency,
    updatedAt: wallet.updatedAt,
  );

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final type = json['type'];
    final openingBalance = json['openingBalance'];
    final currency = json['currency'];
    final updatedAt = json['updatedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Wallet id is missing.');
    }
    if (name is! String) {
      throw const FormatException('Wallet name is missing.');
    }
    final parsedType = type is String
        ? WalletType.values.asNameMap()[type]
        : null;
    if (parsedType == null) {
      throw const FormatException('Wallet type is missing.');
    }
    if (openingBalance is! num) {
      throw const FormatException('Wallet opening balance is missing.');
    }

    return WalletModel(
      id: id,
      name: name,
      type: parsedType,
      openingBalance: openingBalance.toDouble(),
      currency: currency is String ? currency : 'USD',
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'type': type.name,
    'openingBalance': openingBalance,
    'currency': currency,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };

  WalletEntity toEntity() => WalletEntity(
    id: id,
    name: name,
    type: type,
    openingBalance: openingBalance,
    currency: currency,
    updatedAt: updatedAt,
  );
}

class WalletTransferModel extends WalletTransferEntity {
  const WalletTransferModel({
    required super.id,
    required super.fromWalletId,
    required super.toWalletId,
    required super.amount,
    required super.date,
    super.note,
    super.createdAt,
  });

  factory WalletTransferModel.fromEntity(WalletTransferEntity transfer) {
    return WalletTransferModel(
      id: transfer.id,
      fromWalletId: transfer.fromWalletId,
      toWalletId: transfer.toWalletId,
      amount: transfer.amount,
      date: transfer.date,
      note: transfer.note,
      createdAt: transfer.createdAt,
    );
  }

  factory WalletTransferModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fromWalletId = json['fromWalletId'];
    final toWalletId = json['toWalletId'];
    final amount = json['amount'];
    final date = json['date'];
    final note = json['note'];
    final createdAt = json['createdAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Transfer id is missing.');
    }
    if (fromWalletId is! String || toWalletId is! String) {
      throw const FormatException('Transfer wallets are missing.');
    }
    if (amount is! num) {
      throw const FormatException('Transfer amount is missing.');
    }
    if (date is! String) {
      throw const FormatException('Transfer date is missing.');
    }

    return WalletTransferModel(
      id: id,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount.toDouble(),
      date: DateTime.parse(date),
      note: note is String ? note : '',
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fromWalletId': fromWalletId,
    'toWalletId': toWalletId,
    'amount': amount,
    'date': date.toUtc().toIso8601String(),
    'note': note,
    'createdAt': createdAt?.toUtc().toIso8601String(),
  };

  WalletTransferEntity toEntity() => WalletTransferEntity(
    id: id,
    fromWalletId: fromWalletId,
    toWalletId: toWalletId,
    amount: amount,
    date: date,
    note: note,
    createdAt: createdAt,
  );
}
